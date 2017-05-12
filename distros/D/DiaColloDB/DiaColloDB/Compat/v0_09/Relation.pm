## -*- Mode: CPerl -*-
## File: DiaColloDB::Compat::v0_09::Relation.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, relation API (abstract & utilities)

package DiaColloDB::Compat::v0_09::Relation;
use DiaColloDB::Compat;
use DiaColloDB::Relation;
use DiaColloDB::Utils qw(:si);
use Algorithm::BinarySearch::Vec qw(:api);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Relation DiaColloDB::Compat);

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
##    a tt-style text file containing 1 token-id perl line with optional blank lines
##  + %opts: clobber %$rel
##  + DISABLED
BEGIN {
  *create = DiaColloDB::Compat->nocompat('create');
}

##==============================================================================
## Relation API: union

## $rel = $CLASS_OR_OBJECT->union($coldb, \@pairs, %opts)
##  + merge multiple co-frequency indices into new object
##  + @pairs : array of pairs ([$argrel,\@xi2u],...)
##    of relation-objects $argrel and tuple-id maps \@xi2u for $rel
##  + %opts: clobber %$rel
##  + implicitly flushes the new index
##  + DISABLED
BEGIN {
  *union = DiaColloDB::Compat->nocompat('union');
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
##     ##
##     ##-- profiling and debugging parameters
##     strings => $bool,          ##-- do/don't stringify item keys (default=do)
##     packed  => $bool,          ##-- leave item keys packed (default=don't)
##     fill    => $bool,          ##-- if true, returned multi-profile will have null profiles inserted for missing slices
##     onepass => $bool,          ##-- if true, use fast but incorrect 1-pass method (Cofreqs subclass only)
##    )
##  + default implementation
##    - calls $rel->subprofile1() for every requested date-slice, then
##    - calls $rel->subprofile2() to compute item2 frequencies, and finally
##    - collects the result in a DiaColloDB::Profile::Multi object
##  + default values for %opts should be set by higher-level call, e.g. DiaColloDB::profile()
sub profile {
  my ($reldb,$coldb,%opts) = @_;

  ##-- sanity check(s)
  $reldb->logconfess("profile(): incompatible DB class ".ref($coldb).", v".($coldb->{version}//'???')." for directory $coldb->{dbdir}")
    if (!$coldb->isa('DiaColloDB::Compat::v0_09::DiaColloDB'));

  ##-- common variables
  my $logProfile = $coldb->{logProfile};

  ##-- variables: by attribute
  my $groupby= $coldb->groupby($opts{groupby});
  my $attrs  = $coldb->attrs();
  my $adata  = $coldb->attrData($attrs);
  my $a2data = {map {($_->{a}=>$_)} @$adata};
  my $areqs  = $coldb->parseRequest($opts{query}, logas=>'query', default=>$attrs->[0]);
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
  my $xivec = undef;
  my $nbits = undef;
  my $pack_xv = undef;
  my $test_xv = undef;    ##-- test value via vec()
  foreach $ac (grep {$_->{reqids}} @$adata) {
    ##-- sanity checks
    $nbits   //= $ac->{a2x}{len_i}*8;
    $pack_xv //= "$ac->{a2x}{pack_i}*";
    vec($test_xv='',0,$nbits) = 0x12345678 if (!defined($test_xv));
    $reldb->logconfess("profile(): multimap pack-size mismatch: nbits($ac->{a2x}{base}.*) != $nbits")
      if ($ac->{a2x}{len_i} != $nbits/8);
    $reldb->logconfess("profile(): multimap pack-template '$ac->{a2x}{pack_i}' for $ac->{a2x}{base}.* is not big-endian")
      if (pack($ac->{a2x}{pack_i},0x12345678) ne $test_xv);

    ##-- target set construction
    my $axiset = '';
    $axiset = vunion($axiset, $ac->{a2x}->fetchraw($_), $nbits) foreach (@{$ac->{reqids}});
    $xivec  = defined($xivec) ? vintersect($xivec, $axiset, $nbits) : $axiset;
  }

  ##-- check maxExpand
  $nbits //= packsize($coldb->{pack_id});
  my $nxis = $xivec ? length($xivec)/($nbits/8) : 0;
  if ($coldb->{maxExpand}>0 && $nxis > $coldb->{maxExpand}) {
    $reldb->logwarn("profile(): Warning: target set exceeds max expansion size ($nxis > $coldb->{maxExpand}): truncating");
    substr($xivec, -($nxis - $coldb->{maxExpand})*($nbits/8)) = '';
  }
  my $xis = [$xivec ? unpack($pack_xv, $xivec) : qw()];

  ##-- prepare: parse and filter tuples
  $reldb->vlog($logProfile, "profile(): parse and filter target tuples (date=$opts{date}, slice=$opts{slice}, fill=$opts{fill})");
  my $d2xis = $coldb->xidsByDate($xis, @opts{qw(date slice fill)});

  ##-- profile: get relation profiles (by date-slice, pass 1: f12)
  my $onepass = $opts{onepass} || ($reldb->can('subprofile2') eq \&subprofile2);
  $reldb->vlog($logProfile, "profile(): get frequency profile(s): ".($onepass ? 'single-pass' : 'pass-1'));
  my %d2prf  = qw();
  my @slices = sort {$a<=>$b} keys %$d2xis;
  my ($d,$prf);
  foreach $d (@slices) {
    $prf = $reldb->subprofile1($d2xis->{$d}, groupby=>$groupby->{xi2g}, coldb=>$coldb, onepass=>$onepass, opts=>\%opts);
    $prf->{label}  = $d;
    $prf->{titles} = $groupby->{titles};
    $d2prf{$d} = $prf;
  }

  ##-- profile: complete slice-wise profiles (pass 2: f2)
  if (!$onepass) {
    $reldb->vlog($logProfile, "profile(): get frequency profile(s): pass-2");
    $reldb->subprofile2(\%d2prf, %opts, coldb=>$coldb, groupby=>$groupby, a2data=>$a2data, opts=>\%opts);
  }

  ##-- compile & collect: multi-profile
  foreach $prf (values %d2prf) {
    $prf->compile($opts{score}, eps=>$opts{eps});
  }
  my $mp = DiaColloDB::Profile::Multi->new(profiles=>[@d2prf{@slices}],
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
      $diff->stringify($groupby->{g2s});
    } else {
      $diff->stringify($groupby->{g2txt});
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
## Relation API: default: subprofile1()

## $prf = $rel->subprofile1(\@xids, %opts)
##  + get joint frequency profile for @xids (db must be opened)
##  + %opts:
##     groupby => \&gbsub,  ##-- key-extractor $key2_or_undef = $gbsub->($i2)
##     coldb   => $coldb,   ##-- parent DiaColloDB object (for shared data, debugging)
##     opts    => \%opts,   ##-- pass-through for options to top-level profile() method
sub subprofile1 {
  my ($rel,$ids,%opts) = @_;
  $rel->logconfess("subprofile(): abstract method called");
}

## \%slice2prf = $rel->subprofile2(\%slice2prf, %opts)
##  + populate f2 frequencies for profiles in \%slice2prf
##  + %opts:
##     groupby => \%gbreq,  ##-- parsed groupby object
##     a2data  => \%a2data, ##-- maps indexed attributes to associated datastructures
##     coldb   => $coldb,   ##-- parent DiaColloDB object (for shared data, debugging)
##     opts    => \%opts,   ##-- pass-through for options to top-level profile() method
##  + default implementation just returns \%slice2prf
sub subprofile2 {
  #my ($rel,$slice2prf,%opts) = @_;
  return $_[1];
}

##==============================================================================
## Relation API: default: qinfo()

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
      push(@fstrs, DDC::Any::CQFHasField->new($1,"__W2.${xi}__")->toString);
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


##==============================================================================
## Footer
1;

__END__
