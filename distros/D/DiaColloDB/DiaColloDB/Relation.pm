## -*- Mode: CPerl -*-
## File: DiaColloDB::Relation.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, relation API (abstract & utilities)

package DiaColloDB::Relation;
use DiaColloDB::Persistent;
use DiaColloDB::Profile;
use DiaColloDB::Profile::Multi;
use DiaColloDB::Utils qw(:si :pack :math);
use Algorithm::BinarySearch::Vec qw(:api);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Persistent);

##==============================================================================
## Constructors etc.

## $rel = CLASS_OR_OBJECT->new(%args)
## + %args, object structure: see subclases
sub new {
  my ($that,%args) = @_;
  return bless({ %args }, ref($that)||$that);
}

##==============================================================================
## Relation API: create

## $rel = $CLASS_OR_OBJECT->create($coldb, $tokdat_file, %opts)
##  + populates current database from $tokdat_file,
##    a tt-style text file containing with lines of the form:
##      TID DATE	##-- single token
##	"\n"		##-- blank line --> EOS
##  + %opts: clobber %$rel
sub create {
  my ($rel,$coldb,$datfile,%opts) = @_;
  $rel->logconfess($coldb->{error}="create(): abstract method called");
}

##==============================================================================
## Relation API: union

## $rel = $CLASS_OR_OBJECT->union($coldb, \@pairs, %opts)
##  + merge multiple co-frequency indices into new object
##  + @pairs : array of pairs ([$argrel,\@ti2u],...)
##    of relation-objects $argrel and tuple-id maps \@ti2u for $rel
##  + %opts: clobber %$rel
##  + implicitly flushes the new index
sub union {
  my ($rel,$coldb, $pairs,%opts) = @_;
  $rel->logconfess($coldb->{error}="union(): abstract method called");
}

##==============================================================================
## Relation API: info

## \%info = $rel->dbinfo($coldb)
##  + embedded info-hash for $coldb->dbinfo()
sub dbinfo {
  my $rel = shift;
  my $info = { class=>ref($rel) };
  if ($rel->can('du')) {
    $info->{du_b} = $rel->du();
    $info->{du_h} = si_str($info->{du_b});
  }
  return $info;
}


##==============================================================================
## Relation API: profiling & comparison: top-level

##--------------------------------------------------------------
## Relation API: profile

## $mprf = $rel->profile($coldb, %opts)
##  + get a relation profile for selected items as a DiaColloDB::Profile::Multi object
##  + %opts:
##    (
##     ##-- selection parameters
##     query => $query,           ##-- target request ATTR:REQ...
##     date  => $date1,           ##-- string or array or range "MIN-MAX" (inclusive) : default=all
##     ##
##     ##-- aggregation parameters
##     slice   => $slice,         ##-- date slice (default=1, 0 for global profile)
##     groupby => $groupby,       ##-- string or array "ATTR1[:HAVING1] ...": default=$coldb->attrs; see groupby() method
##     ##
##     ##-- scoring and trimming parameters
##     eps     => $eps,           ##-- smoothing constant (default=0)
##     score   => $func,          ##-- scoring function ("f"|"lf"|"fm"|"lfm"|"mi"|"ld"|"ll") : default="f"
##     kbest   => $k,             ##-- return only $k best collocates per date (slice) : default=-1:all
##     cutoff  => $cutoff,        ##-- minimum score
##     global  => $bool,          ##-- trim profiles globally (vs. locally for each date-slice?) (default=0)
##     extend  => \%label2gkeys,  ##-- maps slice-labels to selected (packed) group-keys, for extend() method
##     ##
##     ##-- profiling and debugging parameters
##     strings => $bool,          ##-- do/don't stringify item keys (default=do)
##     packed  => $bool,          ##-- leave item keys packed (default=don't)
##     fill    => $bool,          ##-- if true, returned multi-profile will have null profiles inserted for missing slices
##     onepass => $bool,          ##-- if true, use fast but incorrect 1-pass method (Cofreqs subclass only, >= v0.09.001)
##    )
##  + default implementation
##    - parses request and extracts target tuple-ids
##    - calls $rel->subprofile1() to compute slice-wise joint frequency profiles (f12)
##    - calls $rel->subprofile2() to compute independent collocate frequencies (f2), and finally
##    - collects the result in a DiaColloDB::Profile::Multi object
##  + default values for %opts should be set by higher-level call, e.g. DiaColloDB::profile()
sub profile {
  my ($reldb,$coldb,%opts) = @_;

  ##-- common variables
  $opts{coldb}   = $coldb; ##-- pass-down to subprofile() methods
  my $logProfile = $coldb->{logProfile};

  ##-- variables: by attribute
  my $groupby= $opts{groupby} = $coldb->groupby($opts{groupby});
  my $attrs  = $coldb->attrs();
  my $adata  = $coldb->attrData($attrs);
  my $a2data = $opts{a2data} = {map {($_->{a}=>$_)} @$adata};
  my $areqs  = $coldb->parseRequest($opts{query}, logas=>'query', default=>$attrs->[0], qref=>\$opts{qobj});
  foreach (@$areqs) {
    $a2data->{$_->[0]}{req} = $_->[1];
  }

  ##-- sanity check(s)
  if (!@$areqs) {
    $reldb->logwarn($coldb->{error}="profile(): no target attributes specified (supported attributes: ".join(' ',@{$coldb->attrs}).")");
    return undef;
  }
  if (!@{$groupby->{attrs}}) {
    $reldb->logconfess($coldb->{error}="profile(): cannot profile with empty groupby clause");
    return undef;
  }

  ##-- prepare: get target IDs (by attribute)
  my ($ac);
  foreach $ac (grep {($_->{req}//'') ne ''} @$adata) {
    $ac->{reqids} = $coldb->enumIds($ac->{enum},$ac->{req},logLevel=>$logProfile,logPrefix=>"profile(): get target $ac->{a}-values");
    if (!@{$ac->{reqids}}) {
      $reldb->logwarn($coldb->{error}="profile(): no $ac->{a}-attribute values match user query '$ac->{req}'");
      return undef;
    }
  }

  ##-- prepare: get tuple-ids (by attribute)
  $reldb->vlog($logProfile, "profile(): get target tuple IDs");
  my $tivec = undef;
  my $nbits = undef;
  my $pack_tv = undef;
  my $test_tv = undef;    ##-- test value via vec()
  foreach $ac (grep {$_->{reqids}} @$adata) {
    ##-- sanity checks
    $nbits   //= $ac->{a2t}{len_i}*8;
    $pack_tv //= "$ac->{a2t}{pack_i}*";
    vec($test_tv='',0,$nbits) = 0x12345678 if (!defined($test_tv));
    $reldb->logconfess($coldb->{error}="profile(): multimap pack-size mismatch: nbits($ac->{a2t}{base}.*) != $nbits")
      if ($ac->{a2t}{len_i} != $nbits/8);
    $reldb->logconfess($coldb->{error}="profile(): multimap pack-template '$ac->{a2t}{pack_i}' for $ac->{a2t}{base}.* is not big-endian")
      if (pack($ac->{a2t}{pack_i},0x12345678) ne $test_tv);

    ##-- target set construction
    my $atiset = '';
    $atiset = vunion($atiset, $ac->{a2t}->fetchraw($_), $nbits) foreach (@{$ac->{reqids}});
    $tivec  = defined($tivec) ? vintersect($tivec, $atiset, $nbits) : $atiset;
  }

  ##-- check maxExpand
  $nbits //= packsize($coldb->{pack_id});
  my $ntis = $tivec ? length($tivec)/($nbits/8) : 0;
  if ($coldb->{maxExpand}>0 && $ntis > $coldb->{maxExpand}) {
    $reldb->logwarn("profile(): Warning: target set exceeds max expansion size ($ntis > $coldb->{maxExpand}): truncating");
    substr($tivec, -($ntis - $coldb->{maxExpand})*($nbits/8)) = '';
  }
  my $tis = [$tivec ? unpack($pack_tv, $tivec) : qw()];

  ##-- parse date request (no filtering here)
  $reldb->vlog($logProfile, "profile(): parse date request (date=$opts{date}, slice=$opts{slice}, fill=$opts{fill})");
  my $dreq = $opts{dreq} = $coldb->parseDateRequest(@opts{qw(date slice fill)});

  ##-- profile: get relation profiles (by date-slice, pass 1: f12)
  my $onepass = $opts{onepass} || ($reldb->can('subprofile2') eq \&subprofile2);
  $reldb->vlog($logProfile, "profile(): get frequency profile(s): ".($onepass ? 'single-pass' : 'pass-1'));
  my $s2prf = $reldb->subprofile1($tis, \%opts);
  foreach (keys %$s2prf) {
    @{$s2prf->{$_}}{qw(label titles)} = ($_,$groupby->{titles});
  }

  ##-- profile/extend: insert extension keys
  my $extend = $opts{extend};
  if ($extend) {
    my ($slice,$prf,$sxkeys);
    while (($slice,$prf) = each %$s2prf) {
      $sxkeys = $extend->{$slice}//{};
      $prf->{f12}{$_} //= 0 foreach (keys %$sxkeys);
    }
  }

  ##-- profile: complete slice-wise profiles (pass 2: f2)
  if (!$onepass || !$opts{onepass}) {
    $reldb->vlog($logProfile, "profile(): get frequency profile(s): pass-2");
    $reldb->subprofile2($s2prf, \%opts);
  }

  ##-- compile & collect: multi-profile
  foreach (values %$s2prf) {
    $_->compile($opts{score}, eps=>$opts{eps});
  }
  my $mp = DiaColloDB::Profile::Multi->new(profiles=>[@$s2prf{sort {$a<=>$b} keys %$s2prf}],
					   titles=>$groupby->{titles},
					   qinfo =>$reldb->qinfo($coldb, %opts, qreqs=>$areqs, gbreq=>$groupby),
					  );

  ##-- trim and stringify
  $reldb->vlog($logProfile, "profile(): trim and stringify");
  $mp->trim(%opts, empty=>!$opts{fill});
  if (!$opts{packed}) {
    if ($opts{strings}//1) {
      $mp->stringify($groupby->{g2s});
    } else {
      $mp->stringify($groupby->{g2txt});
    }
  }

  ##-- return
  return $mp;
}

##--------------------------------------------------------------
## Relation API: extend (pass-2 for multi-clients)

## $mprf = $rel->extend($coldb, %opts)
##  + extend f12 and f2 frequencies for \%slice2keys = $opts{slice2keys}
##  + calls $rel->profile($coldb, %opts,extend=>\%slice2keys_packed)
##  + returns a DiaColloDB::Profile::Multi containing the appropriate f12 and f2 entries
sub extend {
  my ($reldb,$coldb,%opts) = @_;

  ##-- common variables
  $opts{coldb}   = $coldb; ##-- pass-down to subprofile() methods
  my $logProfile = $coldb->{logProfile};

  ##-- sanity check(s)
  my $slice2keys = $opts{slice2keys} || $opts{extend};
  if (!$slice2keys) {
    $reldb->logwarn($coldb->{error}="extend(): no 'slice2keys' or 'extend' parameter specified!");
    return undef;
  }
  elsif (!UNIVERSAL::isa($slice2keys,'HASH')) {
    $reldb->logwarn($coldb->{error}="extend(): failed to parse 'slice2keys' or 'extend' parameter");
    return undef;
  }
  delete $opts{slice2keys};

  ##-- get packed group-keys (avoid temporary dummy-profiles: they can't handle unknown group-components)
  my $groupby = $opts{groupby} = $coldb->groupby($opts{groupby});
  my $s2gx    = $groupby->{s2gx};
  my ($xslice,$xkeys, $xgkeys,$xkey,$xg, %extend);
  while (($xslice,$xkeys) = each %$slice2keys) {
    $xgkeys = $extend{$xslice} = {};
    foreach $xkey (UNIVERSAL::isa($xkeys,'HASH') ? keys(%$xkeys) : @$xkeys) {
      next if (!defined($xg = $s2gx->($xkey)));
      $xgkeys->{$xg} = undef;
    }
  }

  ##-- guts: dispatch to profile()
  my $mp = $reldb->profile($coldb, %opts, kbest=>0,kbesta=>0,cutoff=>undef,global=>0,fill=>1, extend=>\%extend);

  return $mp;
}

##--------------------------------------------------------------
## Relation API: comparison (diff)

## $mpdiff = $rel->compare($coldb, %opts)
##  + get a relation comparison profile for selected items as a DiaColloDB::Profile::MultiDiff object
##  + %opts:
##    (
##     ##-- selection parameters
##     (a|b)?query => $query,       ##-- target query as for parseRequest()
##     (a|b)?date  => $date1,       ##-- string or array or range "MIN-MAX" (inclusive) : default=all
##     ##
##     ##-- aggregation parameters
##     groupby      => $groupby,    ##-- string or array "ATTR1[:HAVING1] ...": default=$coldb->attrs; see groupby() method
##     (a|b)?slice  => $slice,      ##-- date slice (default=1, 0 for global profile)
##     ##
##     ##-- scoring and trimming parameters
##     eps     => $eps,           ##-- smoothing constant (default=0)
##     score   => $func,          ##-- scoring function ("f"|"lf"|"fm"|"lfm"|"mi"|"ld"|"ll") : default="f"
##     kbest   => $k,             ##-- return only $k best collocates per date (slice) : default=-1:all
##     cutoff  => $cutoff,        ##-- minimum score
##     global  => $bool,          ##-- trim profiles globally (vs. locally for each date-slice?) (default=0)
##     diff    => $diff,          ##-- low-level score-diff operation (adiff|diff|sum|min|max|avg|havg); default='adiff'
##     ##
##     ##-- profiling and debugging parameters
##     strings => $bool,          ##-- do/don't stringify item keys (default=do)
##     packed  => $bool,          ##-- leave item keys packed (override stringification; default=don't)
##     ##
##     ##-- sublcass abstraction parameters
##     _gbparse => $bool,         ##-- if true (default), 'groupby' clause will be parsed only once, using $coldb->groupby() method
##     _abkeys  => \@abkeys,      ##-- additional key-suffixes KEY s.t. (KEY=>VAL) gets passed to profile() calls if e.g. (aKEY=>VAL) is in %opts
##    )
##  + default implementation wraps profile() method
##  + default values for %opts should be set by higher-level call, e.g. DiaColloDB::compare()
sub compare {
  my ($reldb,$coldb,%opts) = @_;

  ##-- common variables
  my $logProfile = $coldb->{logProfile};
  my $groupby    = $opts{groupby} || [@{$coldb->attrs}];
  $groupby       = $coldb->groupby($groupby) if ($opts{_gbparse}//1);
  my %aopts      = map {exists($opts{"a$_"}) ? ($_=>$opts{"a$_"}) : qw()} (qw(query date slice), @{$opts{_abkeys}//[]});
  my %bopts      = map {exists($opts{"b$_"}) ? ($_=>$opts{"b$_"}) : qw()} (qw(query date slice), @{$opts{_abkeys}//[]});
  my %popts      = (kbest=>-1,cutoff=>'',global=>0,strings=>0,packed=>1,fill=>1, groupby=>$groupby);

  ##-- get profiles to compare
  my $mpa = $reldb->profile($coldb,%opts, %aopts,%popts) or return undef;
  my $mpb = $reldb->profile($coldb,%opts, %bopts,%popts) or return undef;

  ##-- alignment and trimming
  $reldb->vlog($logProfile, "compare(): align and trim (".($opts{global} ? 'global' : 'local').")");
  my $ppairs = DiaColloDB::Profile::MultiDiff->align($mpa,$mpb);
  DiaColloDB::Profile::MultiDiff->trimPairs($ppairs, %opts);
  my $diff = DiaColloDB::Profile::MultiDiff->new($mpa,$mpb, titles=>$mpa->{titles}, diff=>$opts{diff});
  $diff->trim( DiaColloDB::Profile::Diff->diffkbest($opts{diff})=>$opts{kbest} ) if (!$opts{global});

  ##-- finalize: stringify
  if (!$opts{packed}) {
    if ($opts{strings}//1) {
      $diff->stringify($groupby->{g2s}) if (ref($groupby) && $groupby->{g2s})
    } else {
      $diff->stringify($groupby->{g2txt}) if (ref($groupby) && $groupby->{g2txt});
    }
  }

  return $diff;
}

## $mpdiff = $rel->diff($coldb, %opts)
##  + alias for compare()
sub diff {
  my $rel = shift;
  return $rel->compare(@_);
}


##==============================================================================
## Relation API: default

##--------------------------------------------------------------
## Relation API: default: sliceN

## $N = $rel->sliceN($sliceBy, $dateLo)
##  + get total slice-wise co-occurrence count for a slice of size $sliceBy starting at $dateLo
##  + not called by any default methods, but useful for sub-classes
##  + default implementation is really only appropriate for Cofreqs and Unigrams relations;
##    uses $rel properties 'N', 'sizeN', 'ymin', 'rN'
sub sliceN {
  my ($rel,$slice,$dlo) = @_;
  return $rel->{N} if ($slice==0 || !UNIVERSAL::can($rel->{rN},'fetch'));
  my $ymin  = ($rel->{ymin}//0);
  my $rN    = $rel->{rN};
  my $ihi   = min2( $dlo-$ymin+$slice, $rel->{sizeN}//$rN->size );
  my $ilo   = max2( $dlo-$ymin,        0);
  my $N     = 0;
  for (my $i=$ilo; $i < $ihi; ++$i) {
    $N += $rN->fetch($i);
  }
  return $N;
}

##--------------------------------------------------------------
## Relation API: default: subprofile1

## \%slice2prf = $rel->subprofile1(\@tids,\%opts)
##  + get slice-wise joint frequency profile(s) for \@tids (db must be opened)
##  + %opts: as for profile(), also:
##     coldb => $coldb,    ##-- parent DiaColloDB object (for shared data, debugging)
##     a2data => \%a2data, ##-- maps indexed attributes to associated data structures
##     dreq  => \%dreq,    ##-- parsed date request
sub subprofile1 {
  my ($rel,$tids,$opts) = @_;
  $rel->logconfess($opts->{coldb}{error}="subprofile(): abstract method called");
}

##--------------------------------------------------------------
## Relation API: default: subprofile2

## \%slice2prf = $rel->subprofile2(\%slice2prf,\%opts)
##  + populate f2 frequencies for profiles in \%slice2prf
##  + %opts: as for subprofile1()
##  + default implementation just returns \%slice2prf
sub subprofile2 {
  #my ($rel,$slice2prf,$opts) = @_;
  return $_[1];
}

##--------------------------------------------------------------
## Relation API: default: qinfo

## \%qinfo = $rel->qinfo($coldb, %opts)
##  + get query-info hash for profile administrivia (ddc hit links)
##  + %opts: as for profile(), additionally:
##    (
##     qreqs => \@areqs,      ##-- as returned by $coldb->parseRequest($opts{query})
##     gbreq => \%groupby,    ##-- as returned by $coldb->groupby($opts{groupby})
##    )
##  + returned hash \%qinfo should have keys:
##    (
##     fcoef => $fcoef,         ##-- frequency coefficient (2*$coldb->{dmax} for CoFreqs)
##     qtemplate => $qtemplate, ##-- query template with __W1.I1__ rsp __W2.I2__ replacing groupby fields
##     qcanon => $qcanon,       ##-- canonical query string (after parsing)
##    )
sub qinfo {
  my ($rel,$coldb,%opts) = @_;
  $rel->logconfess("qinfo(): abstract method called");
}

## (\@q1strs,\@q2strs,\@qxstrs,\@fstrs) = $rel->qinfoData($coldb,%opts)
##  + parses @opts{qw(qreqs gbreq)} into conditions on w1, w2 and metadata filters (for ddc linkup)
##  + call this from subclass qinfo() methods
sub qinfoData {
  my ($rel,$coldb,%opts) = @_;
  my (@q1strs,@q2strs,@qxstrs,@fstrs,$q,$q2);

  ##-- query clause
  foreach (@{$opts{qreqs}}) {
    $q = $coldb->attrQuery(@$_);
    if (UNIVERSAL::isa($q,'DDC::Any::CQFilter')) {
      push(@fstrs, $q->toString);
    }
    elsif (defined($q) && !UNIVERSAL::isa($q,'DDC::Any::CQTokAny')) {
      push(@q1strs, $q->toString);
    }
  }

  ##-- groupby clause
  my $xi=1;
  foreach (@{$opts{gbreq}{areqs}}) {
    if ($_->[0] =~ /^doc\.(.*)/) {
      push(@fstrs, DDC::Any::CQFHasField->new("$1","__W2.${xi}__")->toString);
    }
    else {
      push(@q2strs, DDC::Any::CQTokExact->new($_->[0],"__W2.${xi}__")->toString);
    }
    ++$xi;
  }

  ##-- common restrictions (trunk/2015-10-28: these are too expensive for large corpora (timeouts): ignore 'em
  #push(@qxstrs, qq(\$p=/$coldb->{pgood}/)) if ($coldb->{pgood});
  #push(@qxstrs, qq(\$=!/$coldb->{pbad}/))  if ($coldb->{pbad});

  ##-- utf8
  foreach (@q1strs,@q2strs,@qxstrs,@fstrs) {
    utf8::decode($_) if (!utf8::is_utf8($_));
  }

  return (\@q1strs,\@q2strs,\@qxstrs,\@fstrs);
}

## $qstr_or_undef = $rel->qcanon($coldb,%opts)
##  + returns "canonical" query string for %opts
##  + default implementation uses:
##    - $opts{qcanon} if defined
##    - $opts{qobj}->toStringFull() if available
##    - undef
sub qcanon {
  my ($rel,$coldb,%opts) = @_;
  my $q = $opts{qcanon} // $opts{qobj};
  $q = $q->toStringFull if (ref($q) && UNIVERSAL::can($q,'toStringFull'));
  utf8::decode($q) if (!utf8::is_utf8($q));
  return $q;
}


##==============================================================================
## Footer
1;

__END__
