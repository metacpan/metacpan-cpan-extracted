## -*- Mode: CPerl -*-
## File: DiaColloDB::methods::compile.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, top-level compile-time methods (create, union, etc.)
##  + really just adds methods to top-level DiaColloDB package

##-- dummy package
package DiaColloDB::methods::compile;
use strict;
1;

package DiaColloDB;
use vars qw($MMCLASS $ECLASS $XECLASS %TDF_OPTS $NJOBS);
use strict;

##==============================================================================
## DiaColloDB: create/compile

##--------------------------------------------------------------
## create: utils

## \%line2undef = $coldb->loadFilterFile($filename_or_undef)
##  + now in DiaColloDB::Corpus::Filters (since v0.12.012_01); alias retained for compatibility
BEGIN { *loadFilterFile = \&DiaColloDB::Corpus::Filters::loadListFile; }

## $filters = $coldb->corpusFilters()
##  + DiaColloDB::Corpus::Filters object from $coldb options
sub corpusFilters {
  my $coldb = shift;
  return DiaColloDB::Corpus::Filters->new(map {($_=>$coldb->{$_})}
                                          @DiaColloDB::Corpus::Filters::NAMES,
                                          @DiaColloDB::Corpus::Filters::FILES);
}

## $multimap = $coldb->create_multimap($base, \%ts2i, $packfmt, $label="multimap")
sub create_multimap {
  my ($coldb,$base,$ts2i,$packfmt,$label) = @_;
  $label //= "multimap";
  $coldb->vlog($coldb->{logCreate},"create_multimap(): creating $label $base.*");

  my $pack_id  = $coldb->{pack_id};
  my $pack_mmb = "${pack_id}*"; ##-- multimap target-set pack format
  my @v2ti     = qw();
  my ($t,$ti,$vi);
  while (($t,$ti)=each %$ts2i) {
    ($vi)       = unpack($packfmt,$t);
    $v2ti[$vi] .= pack($pack_id,$ti);
  }
  $_ = pack($pack_mmb, sort {$a<=>$b} unpack($pack_mmb,$_//'')) foreach (@v2ti); ##-- ensure multimap target-sets are sorted

  my $v2t = $coldb->mmclass($MMCLASS)->new(base=>$base, flags=>'rw', perms=>$coldb->{perms}, pack_i=>$pack_id, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_id})
    or $coldb->logconfess("create_multimap(): failed to create $base.*: $!");
  $v2t->fromArray(\@v2ti)
    or $coldb->logconfess("create_multimap(): failed to populate $base.*: $!");
  $v2t->flush()
    or $coldb->logconfess("create_multimap(): failed to flush $base.*: $!");

  return $v2t;
}

## \@attrs = $coldb->attrs()
## \@attrs = $coldb->attrs($attrs=$coldb->{attrs}, $default=[])
##  + parse attributes in $attrs as array
sub attrs {
  my ($coldb,$attrs,$default) = @_;
  $attrs //= $coldb->{attrs} // $default // [];
  return $attrs if (UNIVERSAL::isa($attrs,'ARRAY'));
  return [grep {defined($_) && $_ ne ''} split(/[\s\,]+/, $attrs)];
}

## $aname = $CLASS_OR_OBJECT->attrName($attr)
##  + returns canonical (short) attribute name for $attr
##  + supports aliases in %ATTR_ALIAS = ($alias=>$name, ...)
##  + see also:
##     %ATTR_RALIAS = ($name=>\@aliases, ...)
##     %ATTR_CBEXPR = ($name=>$ddcCountByExpr, ...)
##     %ATTR_TITLE = ($name_or_alias=>$title, ...)
our (%ATTR_ALIAS,%ATTR_RALIAS,%ATTR_TITLE,%ATTR_CBEXPR);
BEGIN {
  %ATTR_RALIAS = (
		  'l' => [map {(uc($_),ucfirst($_),$_)} qw(lemma lem l)],
		  'w' => [map {(uc($_),ucfirst($_),$_)} qw(token word w)],
		  'p' => [map {(uc($_),ucfirst($_),$_)} qw(postag tag pt pos p)],
		  ##
		  'doc.collection' => [qw(doc.collection collection doc.corpus corpus)],
		  'doc.textClass'  => [qw(doc.textClass textClass textclass tc)], #doc.genre genre
		  'doc.genre'      => [qw(doc.genre genre doc.textClass0 textClass0 textclass0 tc0)],
		  'doc.title'      => [qw(doc.title title)],
		  'doc.author'     => [qw(doc.author author)],
		  'doc.basename'   => [qw(doc.basename basename)],
		  'doc.bibl'	   => [qw(doc.bibl bibl)],
		  'doc.flags'      => [qw(doc.flags flags)],
		  ##
		  date  => [map {(uc($_),ucfirst($_),$_)} qw(date d)],
		  slice => [map {(uc($_),ucfirst($_),$_)} qw(dslice slice sl ds s)],
		 );
  %ATTR_ALIAS = (map {my $attr=$_; map {($_=>$attr)} @{$ATTR_RALIAS{$attr}}} keys %ATTR_RALIAS);
  %ATTR_TITLE = (
		 'l'=>'lemma',
		 'w'=>'word',
		 'p'=>'pos',
		);
  %ATTR_CBEXPR = (
		  'doc.textClass' => DDC::Any::CQCountKeyExprRegex->new(DDC::Any::CQCountKeyExprBibl->new('textClass'),':.*$',''),
		  'doc.genre'     => DDC::Any::CQCountKeyExprRegex->new(DDC::Any::CQCountKeyExprBibl->new('textClass'),':.*$',''),
		 );
}
sub attrName {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  return $ATTR_ALIAS{($_[0]//'')} // $_[0];
}

## $atitle = $CLASS_OR_OBJECT->attrTitle($attr_or_alias)
##  + returns an attribute title for $attr_or_alias
sub attrTitle {
  my ($that,$attr) = @_;
  $attr = $that->attrName($attr//'');
  return $ATTR_TITLE{$attr} if (exists($ATTR_TITLE{$attr}));
  $attr =~ s/^(?:doc|meta)\.//;
  return $attr;
}

## $acbexpr = $CLASS_OR_OBJECT->attrCountBy($attr_or_alias,$matchid=0)
sub attrCountBy {
  my ($that,$attr,$matchid) = @_;
  $attr = $that->attrName($attr//'');
  if (exists($ATTR_CBEXPR{$attr})) {
    ##-- aliased attribute
    return $ATTR_CBEXPR{$attr};
  }
  if ($attr =~ /^doc\.(.*)$/) {
    ##-- document attribute ("doc.ATTR" convention)
    return DDC::Any::CQCountKeyExprBibl->new($1);
  } else {
    ##-- token attribute
    return DDC::Any::CQCountKeyExprToken->new($attr, ($matchid||0), 0);
  }
}

## $aquery_or_filter_or_undef = $CLASS_OR_OBJECT->attrQuery($attr_or_alias,$cquery)
##  + returns a CQuery or CQFilter object for condition $cquery on $attr_or_alias
sub attrQuery {
  my ($that,$attr,$cquery) = @_;
  $attr = $that->attrName( $attr // ($cquery ? $cquery->getIndexName : undef) // '' );
  if ($attr =~ /^doc\./) {
    ##-- document attribute ("doc.ATTR" convention)
    return $that->query2filter($attr,$cquery);
  }
  ##-- token condition (use literal $cquery)
  return $cquery;
}

## \@attrdata = $coldb->attrData()
## \@attrdata = $coldb->attrData(\@attrs=$coldb->attrs)
##  + get attribute data for \@attrs
##  + return @attrdata = ({a=>$attr, i=>$i, enum=>$aenum, pack_t=>$pack_xa, a2t=>$a2t, ...})
sub attrData {
  my ($coldb,$attrs) = @_;
  $attrs //= $coldb->attrs;
  my ($attr);
  return [map {
    $attr = $coldb->attrName($attrs->[$_]);
    {i=>$_, a=>$attr, enum=>$coldb->{"${attr}enum"}, pack_t=>$coldb->{"pack_t$attr"}, a2t=>$coldb->{"${attr}2t"}}
  } (0..$#$attrs)];
}

## $bool = $coldb->hasAttr($attr)
sub hasAttr {
  return 0 if (!defined($_[1]));
  return $_[1] ne 'x' && defined($_[0]{$_[0]->attrName($_[1]).'enum'});
}


##--------------------------------------------------------------
## create: from corpus

## $bool = $coldb->create($corpus,%opts)
##  + %opts:
##     $key => $val,  ##-- clobbers $coldb->{$key}
sub create {
  my ($coldb,$corpus,%opts) = @_;
  $coldb = $coldb->new() if (!ref($coldb));
  @$coldb{keys %opts} = values %opts;
  my $flags = O_RDWR|O_CREAT|O_TRUNC;
  my $debug = $coldb->{debug};

  ##-- initialize: output directory
  my $dbdir = $coldb->{dbdir}
    or $coldb->logconfess("create() called but 'dbdir' key not set!");
  $dbdir =~ s{/$}{};
  $coldb->vlog('info', "create($dbdir) v$coldb->{version}");
  !-d $dbdir
    or remove_tree($dbdir)
      or $coldb->logconfess("create(): could not remove stale $dbdir: $!");
  make_path($dbdir)
    or $coldb->logconfess("create(): could not create DB directory $dbdir: $!");

  ##-- initialize: tdf
  $coldb->{index_tdf} //= 1;
  if ($coldb->{index_tdf}) {
    if (!require "DiaColloDB/Relation/TDF.pm") {
      $coldb->logwarn("create(): require failed for DiaColloDB/Relation/TDF.pm ; (term x document) matrix modelling disabled", ($@ ? "\n: $@" : ''));
      $coldb->{index_tdf} = 0;
    } else {
      $coldb->info("(term x document) matrix modelling via DiaColloDB::Relation::TDF enabled.");
    }
  }

  ##-- initialize: attributes
  my $attrs = $coldb->{attrs} = [map {$coldb->attrName($_)} @{$coldb->attrs(undef,['l'])}];

  ##-- pack-formats
  my $pack_id    = $coldb->{pack_id};
  my $pack_date  = $coldb->{pack_date};
  my $pack_f     = $coldb->{pack_f};
  my $pack_off   = $coldb->{pack_off};
  my $pack_len   = $coldb->{pack_len};
  my $pack_t     = $coldb->{pack_t} = $pack_id."[".scalar(@$attrs)."]";

  ##-- initialize: common flags
  my %efopts = (flags=>$flags, pack_i=>$coldb->{pack_id}, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_len});
  my %mmopts = (flags=>$flags, pack_i=>$coldb->{pack_id});

  ##-- initialize: attribute enums
  my $aconf = [];  ##-- [{a=>$attr, i=>$i, enum=>$aenum, pack_t=>$pack_ta, s2i=>\%s2i, ns=>$nstrings, ?i2j=>$pftmp, ...}, ]
  my $axpos = 0;
  my ($attr,$ac);
  foreach (0..$#$attrs) {
    push(@$aconf,$ac={i=>$_, a=>($attr=$attrs->[$_])});
    $ac->{enum}   = $coldb->{"${attr}enum"} = $coldb->mmclass($ECLASS)->new(%efopts);
    $ac->{pack_t} = $coldb->{"pack_t$attr"} = '@'.$axpos.$pack_id;
    $ac->{s2i}    = $ac->{enum}{s2i};
    $ac->{ma}     = $1 if ($attr =~ /^(?:meta|doc)\.(.*)$/);
    $axpos       += packsize($pack_id);
  }
  my @aconfm = grep { defined($_->{ma})} @$aconf; ##-- meta-attributes
  my @aconfw = grep {!defined($_->{ma})} @$aconf; ##-- token-attributes

  ##-- initialize: tuple enum (+dates)
  my $tenum = $coldb->{tenum} = $coldb->mmclass($XECLASS)->new(%efopts, pack_s=>$pack_t);
  my $ts2i  = $tenum->{s2i};
  my $nt    = 0;

  ##-- initialize: corpus token-list (temporary)
  ##  + 1 token/line, blank lines ~ EOS, token lines ~ "$a0i $a1i ... $aNi $date"
  my $atokfile =  "$dbdir/atokens.dat";
  CORE::open(my $atokfh, ">:raw", $atokfile)
    or $coldb->logconfess("$0: open failed for $atokfile: $!");

  ##-- initialize: tdf: doc-data array (temporary)
  my ($docmeta,$docoff);
  my $ndocs = 0; ##-- current size of @$docmeta, @$docoff
  my $index_tdf = $coldb->{index_tdf};
  if ($index_tdf) {
    $docmeta = $coldb->{docmeta} = tmparray("$dbdir/docmeta", UNLINK=>!$coldb->{keeptmp}, pack_o=>'J', pack_l=>'J')
      or $coldb->logconfess("create(): could not tie temporary doc-data array to $dbdir/docmeta.*: $!");
    $docoff = $coldb->{docoff} = tmparrayp("$dbdir/docoff", 'J', UNLINK=>!$coldb->{keeptmp})
      or $coldb->logconfess("create(): could not tie temporary doc-offset array to $dbdir/docoff.*: $!");
  }
  my $dbreak = ($coldb->{dbreak} // '#file');
  $dbreak    = "#$dbreak" if ($dbreak !~ /^#/);
  $coldb->{dbreak} = $dbreak;

  ##-- initialize: pre-compile corpus
  if (!UNIVERSAL::isa($corpus,'DiaColloDB::Corpus::Compiled')) {
    $coldb->vlog('info', "create(): pre-compiling & filtering corpus to $dbdir/corpus.d/");
    $corpus = $corpus->compile("$dbdir/corpus.d",
                               njobs=>$NJOBS,
                               filters=>$coldb->corpusFilters,
                               logFileN=>max2(1,$corpus->size/10),
                               temp=>!$coldb->{keeptmp}
                              )
      or $coldb->logconfess("failed to pre-compile corpus to $dbdir/corpus.d/");
  } else {
    $coldb->vlog('info', "create(): using pre-compiled corpus ".$corpus->dbdir.'/');

    ##-- always use pre-compiled corpus filters -- but warn about overrides
    my ($cfilters,$dbfilters) = ($corpus->filters,$coldb->corpusFilters);
    foreach my $key (@DiaColloDB::Corpus::Filters::NAMES,@DiaColloDB::Corpus::Filters::FILES) {
      if (($dbfilters->{$key}//'') ne ($cfilters->{$key}//'')) {
        $coldb->warn("create(): WARNING: pre-compiled corpus filter $key=".($cfilters->{$key}//'(null)')." overrides user request=".($dbfilters->{$key}//'(null)'));
        $coldb->{$key} = $cfilters->{$key};
      }
    }
  }

  ##-- initialize: logging
  my $nfiles   = $corpus->size();
  my $logFileN = $coldb->{logCorpusFileN} // max2(1,int($nfiles/20));

  ##-- initialize: enums, date-range
  $coldb->vlog($coldb->{logCreate},"create(): processing $nfiles corpus file(s)");
  my ($xdmin,$xdmax) = ('inf','-inf');
  my ($doc, $date,$tok,@ais,$aistr,$t,$ti, $nsigs, $filei, $last_was_eos);
  my $docoff_cur = -1;
  my $toki       = 0;
  for ($corpus->ibegin(); $corpus->iok; $corpus->inext) {
    $doc  = $corpus->idocument();
    $coldb->vlog($coldb->{logCorpusFile},
                 sprintf("create(): processing files [%3.0f%%]: %s", 100*($filei-1)/$nfiles, ($doc->{label} || $corpus->ifile)))
      if ($logFileN && ($filei++ % $logFileN)==0);

    ##-- initalize tdf data (#/sigs)
    $nsigs = 0;
    $docoff_cur=$toki;

    ##-- get date-range
    $date  = $doc->{date};
    $xdmin = $date if ($date < $xdmin);
    $xdmax = $date if ($date > $xdmax);

    ##-- get meta-attributes
    @ais = qw();
    $ais[$_->{i}] = ($_->{s2i}{$doc->{meta}{$_->{ma}}} //= ++$_->{ns}) foreach (@aconfm);

    ##-- iterate over tokens, populating initial attribute-enums and writing $atokfile
    $last_was_eos = 1;
    foreach $tok (@{$doc->{tokens}}) {
      if (ref($tok)) {
	##-- normal token: get attribute value-ids and build tuple
	$ais[$_->{i}] = ($_->{s2i}{$tok->{$_->{a}//''}} //= ++$_->{ns}) foreach (@aconfw);
	$aistr        = join(' ',@ais);

	$atokfh->print("$aistr $date\n");
	$last_was_eos = 0;
	++$toki;
      }
      elsif (!defined($tok) && !$last_was_eos) {
	##-- eos
	$atokfh->print("\n");
	$last_was_eos = 1;
      }
      elsif (defined($tok) && $tok eq $dbreak && $docoff && $docoff_cur < $toki) {
	##-- break:tdf
	++$nsigs;
	push(@$docoff, $docoff_cur);
	$docoff_cur = $toki;
      }
    }

    ##-- store final doc-break (for tdf)
    if ($docoff && $docoff_cur < $toki) {
      ++$nsigs;
      push(@$docoff, $docoff_cur);
      $docoff_cur = $toki;
    }

    ##-- store doc-data (for tdf)
    if ($docmeta) {
      push(@$docmeta, {
		       id    => $ndocs++,
		       nsigs => $nsigs,
		       file  => $corpus->ifile,
		       (map {($_=>$doc->{$_})} qw(meta date label)),
		      })
    }
  }
  ##-- store final pseudo-doc offset (total #/tokens)
  push(@$docoff, $toki) if ($docoff);

  ##-- store date-range
  @$coldb{qw(xdmin xdmax)} = ($xdmin,$xdmax);

  ##-- close temporary attribute-token file(s)
  CORE::close($atokfh)
      or $coldb->logconfess("create(): failed to close temporary token storage file '$atokfile': $!");

  ##-- close/free temporary corpus
  undef $corpus if ($corpus->{temp});

  ##-- filter: by attribute frequency
  my $ibad  = unpack($pack_id,pack($pack_id,-1));
  foreach $ac (@$aconf) {
    my $afmin = $coldb->{"fmin_".$ac->{a}} // '';
    $afmin    = $coldb->{tfmin} // 0 if (($afmin//'') eq '');
    next if ($afmin <= 0);
    $coldb->vlog($coldb->{logCreate}, "create(): building attribute frequency filter (fmin_$ac->{a}=$afmin)");

    ##-- filter: by attribute frequency: setup re-numbering map $ac->{i2j}
    my $i2j = $ac->{i2j} = tmparrayp("$dbdir/i2j_$ac->{a}.tmp", 'J', UNLINK=>!$coldb->{keeptmp});

    ##-- filter: by attribute frequency: populate $ac->{i2j} and update $ac->{s2i}
    env_push(LC_ALL=>'C');
    my $ai1   = $ac->{i}+1;
    my $cmdfh = opencmd(sortCmd()." -nk$ai1 $atokfile | cut -d\" \" -f $ai1 | uniq -c |")
      or $coldb->logconfess("create(): failed to open pipe from sort for attribute frequency filter (fmin_$ac->{a}=$afmin)");
    my ($f,$i);
    my $nj   = 0;
    while (defined($_=<$cmdfh>)) {
      chomp;
      ($f,$i)    = split(' ',$_,2);
      $i2j->[$i] = ($f >= $afmin ? ++$nj : $ibad) if ($i)
    }
    $cmdfh->close();
    env_pop();

    my $nabad = $ac->{ns} - $nj;
    my $pabad = $ac->{ns} ? sprintf("%.2f%%", 100*$nabad/$ac->{ns}) : 'nan%';
    $coldb->vlog($coldb->{logCreate}, "create(): filter (fmin_$ac->{a}=$afmin) pruning $nabad of $ac->{ns} attribute value type(s) ($pabad)");

    tied(@$i2j)->flush;
    my $s2i = $ac->{s2i};
    my ($s,$j,@badkeys);
    while (($s,$i)=each %$s2i) {
      if (($j=$i2j->[$i])==$ibad) {
	delete $s2i->{$s};
      } else {
	$s2i->{$s} = $j;
      }
    }
    $ac->{ns} = $nj;
    tied(@$i2j)->flush;
  }

  ##-- filter: terms: populate $ts2t (map IDs)
  ## + $ts2t = { join(' ',@ais) => pack($pack_t,i2j(@ais)), ...}
  ## + includes attribute-id re-mappings
  ## + only populated if we have any frequency filters active
  my $ts2t  = undef;
  my $tfmin = $coldb->{tfmin}//0;
  if ($tfmin > 0 || grep {defined($_->{i2j})} @$aconf) {
    $coldb->vlog($coldb->{logCreate}, "create(): populating global term enum (tfmin=$tfmin)");
    my @ai2j  = map {defined($_->{i2j}) ? $_->{i2j} : undef} @$aconf;
    my @ai2ji = grep {defined($ai2j[$_])} (0..$#ai2j);
    my $na        = scalar(@$attrs);
    my ($nw0,$nw) = (0,0);
    my ($f);
    env_push(LC_ALL=>'C');
    my $cmdfh =
      opencmd("sort ".join(' ', map {"-nk$_"} (1..$na))." $atokfile | cut -d\" \" -f -$na | uniq -c |")
      or $coldb->logconfess("create(): failed to open pipe from sort for global term filter");
  FILTER_WTUPLES:
    while (defined($_=<$cmdfh>)) {
      chomp;
      ++$nw0;
      ($f,$aistr) = split(' ',$_,2);
      next if (!$aistr || $f < $tfmin);
      @ais = split(' ',$aistr,$na);
      foreach (@ai2ji) {
	##-- apply attribute-wise re-mappings
	$ais[$_] = $ai2j[$_][$ais[$_]//0];
	next FILTER_WTUPLES if ($ais[$_] == $ibad);
      }
      $ts2t->{$aistr} = pack($pack_t,@ais);
      ++$nw;
    }
    $cmdfh->close();
    env_pop();

    my $nwbad = $nw0 - $nw;
    my $pwbad = $nw0 ? sprintf("%.2f%%", 100*$nwbad/$nw0) : 'nan%';
    $coldb->vlog($coldb->{logCreate}, "create(): will prune $nwbad of $nw0 term tuple type(s) ($pwbad)");
  }

  ##-- compile: apply filters & assign term-ids
  $coldb->vlog($coldb->{logCreate}, "create(): filtering corpus tokens & assigning term-IDs");
  my $tokfile = "$dbdir/tokens.dat";		##-- v0.10.x: new format: "TID DATE\n" | "\n"
  CORE::open(my $tokfh, ">:raw", $tokfile)
      or $coldb->logconfess("$0: open failed for $tokfile: $!");
  my $vtokfile = "$dbdir/vtokens.bin";
  CORE::open(my $vtokfh, ">:raw", $vtokfile)	##-- format: pack($pack_t,@ais)
      or $coldb->logconfess("$0: open failed for $vtokfile: $!");
  CORE::open($atokfh, "<:raw", $atokfile)
      or $coldb->logconfess("$0: re-open failed for $atokfile: $!");
  $nt = 0;
  my $ntok_in = $toki;
  my ($toki_in,$toki_out) = (0,0);
  my $doci_cur   = 0;
  tied(@$docoff)->flush() if ($docoff);
  my $docoff_in  = $docoff ? $docoff->[$doci_cur] : -1;
  while (defined($_=<$atokfh>)) {
    chomp;
    if ($_) {
      if ($toki_in == $docoff_in) {
	##-- update break-indices for tdf

	if ($debug) {
	  ##-- BUGHUNT/Birmingham: weird errors around here: Tue, 05 Jul 2016 09:27:11 +0200
	  $coldb->logconfess("create(): \$doci_cur not defined at \$atokfh line ", $atokfh->input_line_number)
	    if (!defined($doci_cur));
	  $coldb->logconfess("create(): \$toki_out not defined at \$atokfh line ", $atokfh->input_line_number)
	    if (!defined($toki_out));
	  $coldb->logconfess("create(): \$docoff->[\$doci_cur=$doci_cur] not defined at \$atokfh line ", $atokfh->input_line_number)
	    if (!defined($docoff->[$doci_cur]));
	  $coldb->logconfess("create(): next \$docoff_in=\$docoff->[++(\$doci_cur=$doci_cur)] not defined at \$atokfh line ", $atokfh->input_line_number)
	    if (!defined($docoff->[$doci_cur+1]));
	  ##--/BUGHUNT
	}

	$docoff->[$doci_cur] = $toki_out;
	$docoff_in = $docoff->[++$doci_cur];
      }
      ++$toki_in;
      $date = $1 if (s/ ([0-9]+)$//);
      if (defined($ts2t)) {
	next if (!defined($t=$ts2t->{$_}));
      } else {
	$t = pack($pack_t, split(' ',$_));
      }
      $ti  = $ts2i->{$t} = ++$nt if (!defined($ti=$ts2i->{$t}));
      $tokfh->print($ti, "\t", $date, "\n");
      $vtokfh->print($t);
      ++$toki_out;
    }
    else {
      $tokfh->print("\n");
    }
  }
  ##-- update any trailing tdf break indices
  if ($docoff) {
    $ndocs = $#$docoff;
    for (; $doci_cur <= $ndocs; ++$doci_cur) {
      $docoff->[$doci_cur] = $toki_out;
    }
    tied(@$docoff)->flush();
  }

  CORE::close($atokfh)
      or $coldb->logconfess("create(): failed to close temporary attribute-token-file $atokfile: $!");
  CORE::close($tokfh)
      or $coldb->logconfess("create(): failed to close temporary token-file $tokfile: $!");
  CORE::close($vtokfh)
      or $coldb->logconfess("create(): failed to close temporary tdf-token-file $vtokfile: $!");
  my $ntok_out = $toki_out;
  my $ptokbad = $ntok_in ? sprintf("%.2f%%",100*($ntok_in-$ntok_out)/$ntok_in) : 'nan%';
  $coldb->vlog($coldb->{logCreate}, "create(): assigned $nt term tuple-IDs to $ntok_out of $ntok_in tokens (pruned $ptokbad)");

  ##-- cleanup: drop $aconf->[$ai]{i2j} now that we've used it
  delete($_->{i2j}) foreach (@$aconf);

  ##-- compile: tenum
  $coldb->vlog($coldb->{logCreate}, "create(): creating tuple-enum $dbdir/tenum.*");
  $tenum->fromHash($ts2i);
  $tenum->save("$dbdir/tenum")
    or $coldb->logconfess("create(): failed to save $dbdir/tenum.*: $!");

  ##-- compile: by attribute
  foreach $ac (@$aconf) {
    ##-- compile: by attribte: enum
    $coldb->vlog($coldb->{logCreate},"create(): creating enum $dbdir/$ac->{a}_enum.*");
    $ac->{enum}->fromHash($ac->{s2i});
    $ac->{enum}->save("$dbdir/$ac->{a}_enum")
      or $coldb->logconfess("create(): failed to save $dbdir/$ac->{a}_enum: $!");

    ##-- compile: by attribute: expansion multimaps (+dates)
    $coldb->create_multimap("$dbdir/$ac->{a}_2t",$ts2i,$ac->{pack_t},"attribute expansion multimap");
  }

  ##-- compute unigrams
  if ($coldb->{index_xf}//1) {
    $coldb->info("creating unigram index $dbdir/xf.*");
    my $xfdb = $coldb->{xf} = DiaColloDB::Relation::Unigrams->new(base=>"$dbdir/xf", flags=>$flags, mmap=>$coldb->{mmap},
								  pack_i=>$pack_id, pack_f=>$pack_f, pack_d=>$pack_date)
      or $coldb->logconfess("create(): could not create $dbdir/xf.*: $!");
    $xfdb->create($coldb, $tokfile)
      or $coldb->logconfess("create(): failed to create unigram index: $!");
  } else {
    $coldb->info("NOT creating unigram index $dbdir/xf.*; set index_xf=1 to enable");
  }

  ##-- compute collocation frequencies
  if ($coldb->{index_cof}//1) {
    $coldb->info("creating co-frequency index $dbdir/cof.* [dmax=$coldb->{dmax}, fmin=$coldb->{cfmin}]");
    my $cof = $coldb->{cof} = DiaColloDB::Relation::Cofreqs->new(base=>"$dbdir/cof", flags=>$flags, mmap=>$coldb->{mmap},
								 pack_i=>$pack_id, pack_f=>$pack_f, pack_d=>$pack_date,
								 dmax=>$coldb->{dmax}, fmin=>$coldb->{cfmin},
								 keeptmp=>$coldb->{keeptmp},
								)
      or $coldb->logconfess("create(): failed to create co-frequency index $dbdir/cof.*: $!");
    $cof->create($coldb, $tokfile)
      or $coldb->logconfess("create(): failed to create co-frequency index: $!");
  } else {
    $coldb->info("NOT creating co-frequency index $dbdir/cof.*; set index_cof=1 to enable");
  }

  ##-- create tdf-model (if requested & available)
  if ($coldb->{index_tdf}) {
    $coldb->info("creating (term x document) index $dbdir/tdf* [dbreak=$dbreak]");
    $coldb->{tdfopts}     //= {};
    $coldb->{tdfopts}{$_} //= $TDF_OPTS{$_} foreach (keys %TDF_OPTS);	     ##-- tdf: default options
    $coldb->{tdf} = DiaColloDB::Relation::TDF->create($coldb, undef, base=>"$dbdir/tdf", dbreak=>$dbreak);
  } else {
    $coldb->info("NOT creating (term x document) index, 'tdf' profiling relation disabled");
  }

  ##-- create ddc client relation (no-op if ddcServer option is not set)
  if ($coldb->{ddcServer}) {
    $coldb->info("creating ddc client configuration $dbdir/ddc.hdr [ddcServer=$coldb->{ddcServer}]");
    $coldb->{ddc} = DiaColloDB::Relation::DDC->create($coldb);
  } else {
    $coldb->info("ddcServer option unset, NOT creating ddc client configuration");
  }

  ##-- save header
  $coldb->saveHeader()
    or $coldb->logconfess("create(): failed to save header: $!");

  ##-- all done
  $coldb->vlog($coldb->{logCreate}, "create(): DB $dbdir created.");

  ##-- cleanup
  !$docmeta
    or !tied(@$docmeta)
    or untie(@$docmeta)
    or $coldb->logwarn("create(): could untie temporary doc-data array $dbdir/docmeta.*: $!");
  delete $coldb->{docmeta};

  !$docoff
    or !tied(@$docoff)
    or untie(@$docoff)
    or $coldb->logwarn("create(): could untie temporary doc-offset array $dbdir/docoff.*: $!");
  delete $coldb->{docoff};

  if (!$coldb->{keeptmp}) {
    foreach ($vtokfile,$tokfile,$atokfile) {
      CORE::unlink($_)
	  or $coldb->logwarne("creat(): could not remove temporary file '$_': $!");
    }
  }

  return $coldb;
}

##--------------------------------------------------------------
## create: union (aka merge)

## $coldb = $CLASS_OR_OBJECT->union(\@coldbs_or_dbdirs,%opts)
##  + populates $coldb as union over @coldbs_or_dbdirs
##  + clobbers argument dbs {_union_${a}i2u}, {_union_xi2u}, {_union_argi}
BEGIN { *merge = \&union; }
sub union {
  my ($coldb,$args,%opts) = @_;
  $coldb = $coldb->new() if (!ref($coldb));
  @$coldb{keys %opts} = values %opts;
  my @dbargs = map {ref($_) ? $_ : $coldb->new(dbdir=>$_)} @$args;
  my $flags = O_RDWR|O_CREAT|O_TRUNC;

  ##-- sanity check(s): version
  my $min_db_version = '0.10.000';
  foreach (@dbargs) {
    my $dbversion = $_->{version} // '0';
    $coldb->logconfess("union(): can't handle v$dbversion index in '$_->{dbdir}'; try running \`dcdb-upgrade.perl $_->{dbdir}'")
      if (version->parse($dbversion) < $min_db_version);
  }

  ##-- initialize: output directory
  my $dbdir = $coldb->{dbdir}
    or $coldb->logconfess("union() called but 'dbdir' key not set!");
  $dbdir =~ s{/$}{};
  $coldb->vlog('info', "union($dbdir) v$coldb->{version}: ", join(' ', map {$_->{dbdir}//''} @dbargs));
  !-d $dbdir
    or remove_tree($dbdir)
      or $coldb->logconfess("union(): could not remove stale $dbdir: $!");
  make_path($dbdir)
    or $coldb->logconfess("union(): could not create DB directory $dbdir: $!");

  ##-- attributes
  my $attrs = [map {$coldb->attrName($_)} @{$coldb->attrs(undef,[])}];
  my ($db,$dba);
  if (!@$attrs) {
    ##-- use intersection of @dbargs attrs
    my @dbakeys = map {$db=$_; scalar {map {($_=>undef)} @{$db->attrs}}} @dbargs;
    my %akeys   = qw();
    foreach $dba (map {@{$_->attrs}} @dbargs) {
      next if (exists($akeys{$dba}) || grep {!exists($_->{$dba})} @dbakeys);
      $akeys{$dba}=undef;
      push(@$attrs, $dba);
    }
  }
  $coldb->{attrs} = $attrs;
  $coldb->logconfess("union(): no attributes defined and intersection over db attributes is empty!") if (!@$attrs);

  ##-- pack-formats
  my $pack_id    = $coldb->{pack_id};
  my $pack_date  = $coldb->{pack_date};
  my $pack_f     = $coldb->{pack_f};
  my $pack_off   = $coldb->{pack_off};
  my $pack_len   = $coldb->{pack_len};
  my $pack_t     = $coldb->{pack_t} = $pack_id."[".scalar(@$attrs)."]"; ##-- pack("${pack_id}*${pack_date}", @ais)

  ##-- tuple packing
  $coldb->{"pack_t$attrs->[$_]"} = '@'.($_*packsize($pack_id)).$pack_id foreach (0..$#$attrs);

  ##-- common variables: enums
  my %efopts = (flags=>$flags, pack_i=>$coldb->{pack_id}, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_len});

  ##-- union: attribute enums; also sets $db->{"_union_${a}i2u"} for each attribute $attr
  ##   + $db->{"${a}i2u"} is a PackedFile temporary in $dbdir/"${a}_i2u.tmp${argi}"
  my ($ac,$attr,$aenum,$as2i,$argi);
  my $adata = $coldb->attrData($attrs);
  foreach $ac (@$adata) {
    $coldb->vlog($coldb->{logCreate}, "union(): creating attribute enum $dbdir/$ac->{a}_enum.*");
    $attr  = $ac->{a};
    $aenum = $coldb->{"${attr}enum"} = $ac->{enum} = $coldb->mmclass($ECLASS)->new(%efopts);
    $as2i  = $aenum->{s2i};
    foreach $argi (0..$#dbargs) {
      ##-- enum union: guts
      $db        = $dbargs[$argi];
      my $dbenum = $db->{"${attr}enum"};
      $coldb->vlog($coldb->{logCreate}, "union(): processing $dbenum->{base}.*");
      $aenum->addEnum($dbenum);
      $db->{"_union_argi"}       = $argi;
      $db->{"_union_${attr}i2u"} = (DiaColloDB::PackedFile
				    ->new(file=>"$dbdir/${attr}_i2u.tmp${argi}", flags=>'rw', packas=>$coldb->{pack_id})
				    ->fromArray( [@$as2i{$dbenum ? @{$dbenum->toArray} : ''}] ))
	or $coldb->logconfess("union(): failed to create temporary $dbdir/${attr}_i2u.tmp${argi}");
      $db->{"_union_${attr}i2u"}->flush();
    }
    $aenum->save("$dbdir/${attr}_enum")
      or $coldb->logconfess("union(): failed to save attribute enum $dbdir/${attr}_enum: $!");
  }

  ##-- union: date-range
  $coldb->vlog($coldb->{logCreate}, "union(): computing date-range");
  @$coldb{qw(xdmin xdmax)} = (undef,undef);
  foreach $db (@dbargs) {
    $coldb->{xdmin} = $db->{xdmin} if (!defined($coldb->{xdmin}) || $db->{xdmin} < $coldb->{xdmin});
    $coldb->{xdmax} = $db->{xdmax} if (!defined($coldb->{xdmax}) || $db->{xdmax} > $coldb->{xdmax});
  }
  $coldb->{xdmin} //= 0;
  $coldb->{xdmax} //= 0;

  ##-- union: tenum
  $coldb->vlog($coldb->{logCreate}, "union(): creating tuple-enum $dbdir/tenum.*");
  my $tenum = $coldb->{tenum} = $coldb->mmclass($XECLASS)->new(%efopts, pack_s=>$pack_t);
  my $ts2i  = $tenum->{s2i};
  my $nt    = 0;
  foreach $db (@dbargs) {
    $coldb->vlog($coldb->{logCreate}, "union(): processing $db->{tenum}{base}.*");
    my $db_pack_t = $db->{pack_t};
    my $dbattrs   = $db->{attrs};
    my %a2dbti  = map { ($dbattrs->[$_]=>$_) } (0..$#$dbattrs);
    my %a2i2u   = map { ($_=>$db->{"_union_${_}i2u"}) } @$attrs;
    $argi       = $db->{_union_argi};
    my $ti2u    = $db->{_union_ti2u} = DiaColloDB::PackedFile->new(file=>"$dbdir/t_i2u.tmp${argi}", flags=>'rw', packas=>$coldb->{pack_id});
    my $dbti    = 0;
    my (@dbt,@ut,$uts,$uti);
    foreach (@{$db->{tenum}->toArray}) {
      @dbt = unpack($db_pack_t,$_);
      $uts = pack($pack_t,
		  (map  {
		    (exists($a2dbti{$_})
		     ? $a2i2u{$_}->fetch($dbt[$a2dbti{$_}]//0)//0
		     : $a2i2u{$_}->fetch(0)//0)
		  } @$attrs),
		  $dbt[$#dbt]//0);
      $uti = $ts2i->{$uts} = $nt++ if (!defined($uti=$ts2i->{$uts}));
      $ti2u->store($dbti++, $uti);
    }
    $ti2u->flush()
      or $coldb->logconfess("could not flush temporary $dbdir/t_i2u.tmp${argi}");
  }
  $tenum->fromHash($ts2i);
  $tenum->save("$dbdir/tenum")
    or $coldb->logconfess("union(): failed to save $dbdir/tenum.*: $!");

  ##-- union: expansion maps
  foreach (@$adata) {
    $coldb->create_multimap("$dbdir/$_->{a}_2t",$ts2i,$_->{pack_t},"attribute expansion multimap");
  }

  ##-- intermediate cleanup: ts2i
  undef $ts2i;

  ##-- unigrams: populate
  if ($coldb->{index_xf}//1) {
    $coldb->vlog($coldb->{logCreate}, "union(): creating tuple unigram index $dbdir/xf.*");
    $coldb->{xf} = DiaColloDB::Relation::Unigrams->new(base=>"$dbdir/xf", flags=>$flags, mmap=>$coldb->{mmap},
						       pack_i=>$pack_id, pack_f=>$pack_f, pack_d=>$pack_date,
						       keeptmp => $coldb->{keeptmp},
						      )
      or $coldb->logconfess("union(): could not create $dbdir/xf.*: $!");
    $coldb->{xf}->union($coldb, [map {[@$_{qw(xf _union_ti2u)}]} @dbargs])
      or $coldb->logconfess("union(): could not populate unigram index $dbdir/xf.*: $!");
  } else {
    $coldb->vlog($coldb->{logCreate}, "union(): NOT creating unigram index $dbdir/xf.*; set index_xf=1 to enable");
  }

  ##-- co-frequencies: populate
  if ($coldb->{index_cof}//1) {
    $coldb->vlog($coldb->{logCreate}, "union(): creating co-frequency index $dbdir/cof.* [fmin=$coldb->{cfmin}]");
    $coldb->{cof} = DiaColloDB::Relation::Cofreqs->new(base=>"$dbdir/cof", flags=>$flags, mmap=>$coldb->{mmap},
						       pack_i=>$pack_id, pack_f=>$pack_f, pack_d=>$pack_date,
						       dmax=>$coldb->{dmax}, fmin=>$coldb->{cfmin},
						       keeptmp=>$coldb->{keeptmp},
						      )
      or $coldb->logconfess("create(): failed to open co-frequency index $dbdir/cof.*: $!");
    $coldb->{cof}->union($coldb, [map {[@$_{qw(cof _union_ti2u)}]} @dbargs])
      or $coldb->logconfess("union(): could not populate co-frequency index $dbdir/cof.*: $!");
  } else {
    $coldb->vlog($coldb->{logCreate}, "union(): NOT creating co-frequency index $dbdir/cof.*; set index_cof=1 to enable");
  }

  ##-- tdf: populate
  my $db_tdf            = !grep {!$_->{index_tdf}} @dbargs;
  $coldb->{index_tdf} //= $db_tdf;
  if ($coldb->{index_tdf} && $db_tdf) {
    $coldb->vlog($coldb->{logCreate}, "union(): creating (term x document) index $dbdir/tdf.*");
    ##
    my $tdfopts0          = $dbargs[0]{tdfopts};
    $coldb->{tdfopts}     //= {};
    $coldb->{tdfopts}     //= $tdfopts0->{$_} foreach (keys %$tdfopts0);   ##-- tdf: inherit options
    $coldb->{tdfopts}{$_} //= $TDF_OPTS{$_}   foreach (keys %TDF_OPTS);    ##-- tdf: default options
    ##
    my $dbreak = ($coldb->{dbreak} // $dbargs[0]{dbreak} // '#file');
    $dbreak    = "#$dbreak" if ($dbreak !~ /^#/);
    $coldb->{dbreak} = $dbreak;
    ##
    $coldb->{tdf} = DiaColloDB::Relation::TDF->union($coldb, \@dbargs,
						     base => "$dbdir/tdf",
						     flags => $flags,
						     keeptmp => $coldb->{keeptmp},
						     %{$coldb->{tdfopts}},
						    )
      or $coldb->logconfess("create(): failed to populate (term x document) index $dbdir/tdf.*: $!");
  } else {
    $coldb->vlog($coldb->{logCreate}, "union(): NOT creating (term x document) index $dbdir/tdf.*; set index_tdf=1 on all argument DBs to enable");
  }

  ##-- cleanup
  if (!$coldb->{keeptmp}) {
    $coldb->vlog($coldb->{logCreate}, "union(): cleaning up temporary files");
    foreach $db (@dbargs) {
      foreach my $pfkey ('_union_ti2u', map {"_union_${_}i2u"} @$attrs) {
	$db->{$pfkey}->unlink() if ($db->{$pfkey}->can('unlink'));
	delete $db->{$pfkey};
      }
      delete $db->{_union_argi};
    }
  }

  ##-- save header
  $coldb->saveHeader()
    or $coldb->logconfess("union(): failed to save header: $!");

  ##-- all done
  $coldb->vlog($coldb->{logCreate}, "union(): union DB $dbdir created.");

  return $coldb;
}


1; ##-- be happy
