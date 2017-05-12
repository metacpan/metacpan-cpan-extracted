## -*- Mode: CPerl -*-
## File: DiaColloDB::Compat::v0_09::Relation::Cofreqs.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, profiling relation: co-frequency database (v0.9x format)

package DiaColloDB::Compat::v0_09::Relation::Cofreqs;
use DiaColloDB::Compat::v0_09::Relation;
use DiaColloDB::PackedFile;
use DiaColloDB::PackedFile::MMap;
use DiaColloDB::Utils qw(:fcntl :env :run :json :pack);
use Fcntl qw(:DEFAULT :seek);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Compat::v0_09::Relation);

## $PFCLASS : object class for nested PackedFile objects
our $PFCLASS = 'DiaColloDB::PackedFile::MMap';

##==============================================================================
## Constructors etc.

## $cof = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- user options
##    class    => $class,      ##-- optional, useful for debugging from header file
##    base     => $basename,   ##-- file basename (default=undef:none); use files "${base}.dba1", "${base}.dba2", "${base}.hdr"
##    flags    => $flags,      ##-- fcntl flags or open-mode (default='r')
##    perms    => $perms,      ##-- creation permissions (default=(0666 &~umask))
##    dmax     => $dmax,       ##-- maximum distance for co-occurrences (default=5)
##    fmin     => $fmin,       ##-- minimum pair frequency (default=0)
##    pack_i   => $pack_i,     ##-- pack-template for IDs (default='N')
##    pack_f   => $pack_f,     ##-- pack-template for IDs (default='N')
##    keeptmp  => $bool,       ##-- keep temporary files? (default=false)
##    ##
##    ##-- size info (after open() or load())
##    size1    => $size1,      ##-- == $r1->size()
##    size2    => $size2,      ##-- == $r2->size()
##    ##
##    ##-- low-level data
##    r1 => $r1,               ##-- pf: [$end2,$f1] @ $i1
##    r2 => $r2,               ##-- pf: [$i2,$f12]  @ end2($i1-1)..(end2($i1)-1)
##    N  => $N,                ##-- sum($f12)
##   )
sub new {
  my $that = shift;
  my $cof  = bless({
		    base  =>undef,
		    flags =>'r',
		    perms =>(0666 & ~umask),
		    dmax  =>5,
		    fmin  =>0,
		    pack_i=>'N',
		    pack_f=>'N',
		    r1 => $PFCLASS->new(),
		    r2 => $PFCLASS->new(),
		    N  => 0,
		    @_
		   }, (ref($that)||$that));
  $cof->{class} = ref($cof);
  return $cof->open() if (defined($cof->{base}));
  return $cof;
}

sub DESTROY {
  $_[0]->close() if ($_[0]->opened);
}

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: open/close

## $cof_or_undef = $cof->open($base,$flags)
## $cof_or_undef = $cof->open($base)
## $cof_or_undef = $cof->open()
sub open {
  my ($cof,$base,$flags) = @_;
  $base  //= $cof->{base};
  $flags //= $cof->{flags};
  $cof->close() if ($cof->opened);
  $cof->{base}  = $base;
  $cof->{flags} = $flags = fcflags($flags);
  if (fcread($flags) && !fctrunc($flags)) {
    $cof->loadHeader()
      or $cof->logconess("failed to load header from '$cof->{base}.hdr': $!");
  }
  $cof->{r1}->open("$base.dba1", $flags, perms=>$cof->{perms}, packas=>"$cof->{pack_i}$cof->{pack_f}")
    or $cof->logconfess("open failed for $base.dba1: $!");
  $cof->{r2}->open("$base.dba2", $flags, perms=>$cof->{perms}, packas=>"$cof->{pack_i}$cof->{pack_f}")
    or $cof->logconfess("open failed for $base.dba2: $!");
  $cof->{size1} = $cof->{r1}->size;
  $cof->{size2} = $cof->{r2}->size;

  #$cof->debug("open(): opened level-1 relation $cof->{r1}{file}.* as ", ref($cof->{r1}));
  #$cof->debug("open(): opened level-2 relation $cof->{r2}{file}.* as ", ref($cof->{r2}));
  return $cof;
}

## $cof_or_undef = $cof->close()
sub close {
  my $cof = shift;
  if ($cof->opened && fcwrite($cof->{flags})) {
    $cof->saveHeader() or return undef;
  }
  $cof->{r1}->close() or return undef;
  $cof->{r2}->close() or return undef;
  undef $cof->{base};
  return $cof;
}

## $bool = $cof->opened()
sub opened {
  my $cof = shift;
  return
    (defined($cof->{base})
     && defined($cof->{r1}) && $cof->{r1}->opened
     && defined($cof->{r2}) && $cof->{r2}->opened);
}

##--------------------------------------------------------------
## I/O: header
##  + largely INHERITED from DiaColloDB::Persistent

## @keys = $cof->headerKeys()
##  + keys to save as header
sub headerKeys {
  return grep {!ref($_[0]{$_}) && $_ !~ m{^(?:base|flags|perms)$}} keys %{$_[0]};
}

## $bool = $cof->loadHeaderData($hdr)
##  + instantiates header data from $hdr
##  + overrides DiaColloDB::Persistent implementation
sub loadHeaderData {
  my ($cof,$hdr) = @_;
  if (!defined($hdr) && !fccreat($cof->{flags})) {
    $cof->logconfess("loadHeaderData() failed to load header data from ", $cof->headerFile, ": $!");
  }
  elsif (defined($hdr)) {
    return $cof->SUPER::loadHeaderData($hdr);
  }
  return $cof;
}

## $bool = $enum->saveHeader()
##  + inherited from DiaColloDB::Persistent

##--------------------------------------------------------------
## I/O: text
##  + largely INHERITED from DiaColloDB::Persistent

## $bool = $obj->loadTextFile($filename_or_handle, %opts)
##  + wraps loadTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $cof = $cof->loadTextFh($fh,%opts)
##  + loads from text file as saved by saveTextFh()
##  + supports semi-sorted input: input fh must be sorted by $i1,
##    and all $i2 for each $i1 must be adjacent (i.e. no intervening $j1 != $i1)
##  + supports multiple lines for pairs ($i1,$i2) provided the above conditions hold
##  + supports loading of $cof->{N} from single-value lines
##  + %opts: clobber %$cof
sub loadTextFh {
  my ($cof,$infh,%opts) = @_;
  if (!ref($cof)) {
    $cof = $cof->new(%opts);
  } else {
    @$cof{keys %opts} = values %opts;
  }
  $cof->logconfess("loadTextFh(): cannot load unopened database!") if (!$cof->opened);

  ##-- common variables
  my $pack_f   = $cof->{pack_f};
  my $pack_i   = $cof->{pack_i};
  my $pack_r1  = "${pack_i}${pack_f}"; ##-- $r1 : [$end2,$f1] @ $i1
  my $pack_r2  = "${pack_i}${pack_f}"; ##-- $r2 : [$i2,$f12]  @ end2($i1-1)..(end2($i1)-1)
  my $len_r2   = packsize($pack_r2);
  my $fmin     = $cof->{fmin} // 0;
  my ($r1,$r2) = @$cof{qw(r1 r2)};
  $r1->truncate();
  $r2->truncate();
  my ($fh1,$fh2) = ($r1->{fh},$r2->{fh});

  ##-- iteration variables
  my ($pos1,$pos2) = (0,0);
  my ($i1_cur,$f1) = (-1,0);
  my ($f12,$i1,$i2,$f);
  my $N  = 0;	  ##-- total marginal frequency as extracted from %f12
  my $N1 = 0;     ##-- total N as extracted from single-element records
  my %f12 = qw(); ##-- ($i2=>$f12, ...) for $i1_cur; un-collocated f1 counts appear as $i2='-1'

  ##-- guts for inserting records from $i1_cur,%f12,$pos1,$pos2
  my $insert = sub {
    if ($i1_cur >= 0) {
      if ($i1_cur != $pos1) {
	##-- we've skipped one or more $i1 because it had no collocates (e.g. kern01 i1=287123="Untier/1906")
	$fh1->print( pack($pack_r1,$pos2,0) x ($i1_cur-$pos1) );
      }
      ##-- dump r2-records for $i1_cur
      $f1 = 0;
      foreach (sort {$a<=>$b} keys %f12) {
	$f    = $f12{$_};
	$f1  += $f;
	next if ($f < $fmin || $_ < 0); ##-- skip here so we can track "real" marginal frequencies
	$fh2->print(pack($pack_r2, $_,$f));
	++$pos2;
      }
      ##-- dump r1-record for $i1_cur
      $fh1->print(pack($pack_r1, $pos2,$f1));
      $pos1  = $i1_cur+1;
      $N    += $f1;
    }
    $i1_cur = $i1;
    %f12    = qw();
  };

  ##-- ye olde loope
  binmode($infh,':raw');
  while (defined($_=<$infh>)) {
    chomp;
    ($f12,$i1,$i2) = split(' ',$_,3);
    if (!defined($i1)) {
      #$cof->debug("N1 += $f12");
      $N1 += $f12;		      ##-- load N values
      next;
    }
    $insert->() if ($i1 != $i1_cur);  ##-- insert record(s) for $i1_cur
    $f12{($i2//-1)} += $f12;          ##-- buffer co-frequencies for $i1_cur; track un-collocated frequencies as $i2=-1
  }
  $insert->();                        ##-- write record(s) for final $i1_cur

  ##-- adopt final $N and sizes
  #$cof->debug("FINAL: N1=$N1, N=$N");
  $cof->{N} = $N1>$N ? $N1 : $N;
  $_->remap() foreach (grep {$_->can('remap')} @$cof{qw(r1 r2)});
  $cof->{size1} = $r1->size;
  $cof->{size2} = $r2->size;

  return $cof;
}

## $cof = $cof->loadTextFile_create($fh,%opts)
##  + old version of loadTextFile() which doesn't support N, semi-sorted input, or multiple ($i1,$i2) entries
##  + not useable by union() method
BEGIN {
  *loadTextFile_create = DiaColloDB::Compat->nocompat("loadTextFile_create");
}

## $bool = $obj->saveTextFile($filename_or_handle, %opts)
##  + wraps saveTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $bool = $cof->saveTextFh($fh,%opts)
##  + save from text file with lines of the form:
##      N               ##-- 1 field : N
##      FREQ ID1        ##-- 2 fields: un-collocated portion of $f1
##      FREQ ID1 ID2    ##-- 3 fields: co-frequency pair (ID2 >= 0)
##  + %opts:
##      i2s  => \&CODE,   ##-- code-ref for formatting indices; called as $s=CODE($i)
##      i2s1 => \&CODE,   ##-- code-ref for formatting item1 indices (overrides 'i2s')
##      i2s2 => \&CODE,   ##-- code-ref for formatting item2 indices (overrides 'i2s')
sub saveTextFh {
  my ($cof,$outfh,%opts) = @_;
  $cof->logconfess("saveTextFile(): cannot save unopened DB") if (!$cof->opened);

  ##-- common variables
  my ($r1,$r2)   = @$cof{qw(r1 r2)};
  my $pack_r1    = $r1->{packas};
  my $pack_r2    = $r2->{packas};
  my $i2s        = $opts{i2s};
  my $i2s1       = exists($opts{i2s1}) ? $opts{i2s1} : $i2s;
  my $i2s2       = exists($opts{i2s2}) ? $opts{i2s2} : $i2s;
  my ($fh1,$fh2) = ($r1->{fh},$r2->{fh});

  ##-- iteration variables
  my ($buf1,$i1,$s1,$f1,$end2);
  my ($buf2,$off2,$i2,$s2,$f12,$f12sum);

  ##-- ye olde loope
  binmode($outfh,':raw');
  $outfh->print($cof->{N}, "\n");
  for ($r1->seek($i1=0), $r2->seek($off2=0); !$r1->eof(); ++$i1) {
    $r1->read(\$buf1) or $cof->logconfess("saveTextFile(): failed to read record $i1 from $r1->{file}: $!");
    ($end2,$f1) = unpack($pack_r1,$buf1);
    $s1 = $i2s1 ? $i2s1->($i1) : $i1;

    for ($f12sum=0; $off2 < $end2 && !$r2->eof(); ++$off2) {
      $r2->read(\$buf2) or $cof->logconfess("saveTextFile(): failed to read record $off2 from $r2->{file}: $!");
      ($i2,$f12) = unpack($pack_r2,$buf2);
      $f12sum   += $f12;
      $s2        = $i2s2 ? $i2s2->($i2) : $i2;
      $outfh->print(join("\t", $f12, $s1,$s2), "\n");
    }

    ##-- track un-collocated portion of $f1, if any
    $outfh->print(join("\t", $f1-$f12sum, $s1), "\n") if ($f12sum != $f1);
  }

  return $cof;
}

##==============================================================================
## Relation API: create

## $rel = $CLASS_OR_OBJECT->create($coldb,$tokdat_file,%opts)
##  + populates current database from $tokdat_file,
##    a tt-style text file containing 1 token-id perl line with optional blank lines
##  + %opts: clobber %$ug, also:
##    (
##     size=>$size,  ##-- set initial size (number of types)
##    )
##  + DISABLED

##==============================================================================
## Relation API: union

## $cof = CLASS_OR_OBJECT->union($coldb, \@pairs, %opts)
##  + merge multiple unigram unigram indices from \@pairs into new object
##  + @pairs : array of pairs ([$cof,\@xi2u],...)
##    of unigram-objects $cof and tuple-id maps \@xi2u for $cof
##    - \@xi2u may also be a mapping object supporting a toArray() method
##  + %opts: clobber %$cof
##  + implicitly flushes the new index
##  + DISABLED

##==============================================================================
## Relation API: dbinfo

## \%info = $rel->dbinfo($coldb)
##  + embedded info-hash for $coldb->dbinfo()
sub dbinfo {
  my $cof = shift;
  my $info = $cof->SUPER::dbinfo();
  @$info{qw(fmin dmax size1 size2 N)} = @$cof{qw(fmin dmax size1 size2 N)};
  return $info;
}


##==============================================================================
## Utilities: lookup

## $f = $cof->f1( @ids)
## $f = $cof->f1(\@ids)
##  + get total marginal unigram frequency (db must be opened)
sub f1 {
  my $cof = shift;
  my $ids = UNIVERSAL::isa($_[0],'ARRAY') ? @{$_[0]} : \@_;
  my $r1  = $cof->{r1};
  my $f   = 0;
  foreach (@$ids) {
    $f += $r1->fetch($_)->[1];
  }
  return $f;
}

## $f12 = $cof->f12($id1,$id2)
##  + return joint frequency for pair ($id1,$id2)
##  + UNUSED
sub f12 {
  my ($cof,$i1,$i2) = @_;
  my $beg2 = ($i1==0 ? 0 : $cof->{r1}->fetch($i1-1)->[0]);
  my $end2 = $cof->{r1}->fetch($i1)->[0];
  my $pos2 = $cof->{r2}->bsearch($i2, lo=>$beg2, hi=>$end2, packas=>$cof->{pack_i});
  return defined($pos2) ? $cof->{r2}->fetch($pos2)->[1] : 0;
}

##==============================================================================
## Relation API: default: profiling

## $prf = $cof->subprofile1(\@xids,%opts)
##  + get joint co-frequency profile for @xids (db must be opened; f1 and f12 only)
##  + %opts:
##     groupby => \&gbsub,  ##-- key-extractor $key2_or_undef = $gbsub->($i2)
##     coldb   => $coldb,   ##-- for debugging
##     onepass => $bool,    ##-- use fast but incorrect 1-pass method?
sub subprofile1 {
  my ($cof,$ids,%opts) = @_;

  $ids   = [$ids] if (!UNIVERSAL::isa($ids,'ARRAY'));
  my $r1 = $cof->{r1};
  my $r2 = $cof->{r2};
  my $pack1 = $r1->{packas};
  my $pack2 = $r2->{packas};
  my $pack1i = $cof->{pack_i};
  my $pack1f = "@".packsize($cof->{pack_i}).$cof->{pack_f};
  my $size1  = $cof->{size1} // ($cof->{size1}=$r1->size);
  my $size2  = $cof->{size2} // ($cof->{size2}=$r2->size);
  my $groupby = $opts{groupby};
  my $pack_id = $opts{coldb}{pack_id};
  my $onepass = $opts{onepass};
  my $pf1 = 0;
  my $pf12 = {};
  my $pf2  = {};
  my ($i1,$i2,$key2, $beg2,$end2,$pos2, $f1,$f12, $buf, %i2);

  foreach $i1 (@$ids) {
    next if ($i1 >= $size1);
    $beg2       = ($i1==0 ? 0 : unpack($pack1i,$r1->fetchraw($i1-1,\$buf)));
    ($end2,$f1) = unpack($pack1, $r1->fetchraw($i1,\$buf));

    $pf1       += $f1;
    next if ($beg2 >= $size2);
    for ($r2->seek($beg2), $pos2=$beg2; $pos2 < $end2; ++$pos2) {
      $r2->getraw(\$buf) or last;
      ($i2,$f12)    = unpack($pack2, $buf);
      $key2         = $groupby ? $groupby->($i2) : pack($pack_id,$i2);
      next if (!defined($key2)); ##-- item2 selection via groupby CODE-ref
      $pf12->{$key2} += $f12;
      if ($onepass && !exists($i2{$i2})) {
	$pf2->{$key2} += unpack($pack1f, $r1->fetchraw($i2,\$buf)); ##-- avoid double-counting f2 for shared collocates
	$i2{$i2}       = undef;
      }
    }
  }
  return DiaColloDB::Profile->new(
				  N=>$cof->{N},
				  f1=>$pf1,
				  f2=>$pf2,
				  f12=>$pf12,
				 );
}

##  \%slice2prf = $rel->subprofile2(\%slice2prf, %opts)
##  + populate f2 frequencies for profiles in \%slice2prf
##  + %opts:
##     groupby => \%gbreq,  ##-- parsed groupby object
##     a2data  => \%a2data, ##-- maps indexed attributes to associated datastructures
##     coldb   => $coldb,   ##-- parent DiaColloDB object (for shared data, debugging)
##     ...                  ##-- other options as for profile(), esp. qw(slice)
sub subprofile2 {
  my ($cof,$slice2prf,%opts) = @_;

  ##-- vars: common
  my $coldb   = $opts{coldb};
  my $groupby = $opts{groupby};
  my $a2data  = $opts{a2data};
  my $slice   = $opts{slice};
  #my $slices  = $opts{slices} || [sort {$a<=>$b} keys %$slice2prf];
  my ($dfilter,$slo,$shi,$dlo,$dhi) = $coldb->parseDateRequest(@opts{qw(date slice fill)});
  my $filter_by_date = $slice || defined($dlo) || defined($dhi);

  ##-- vars: relation-wise
  my $r1       = $cof->{r1};
  my $pack_r1f = '@'.packsize($cof->{pack_i}).$cof->{pack_f};

  ##-- get "most specific projected attribute" ("MSPA"): that projected attribute with largest enum
  #my $gb1      = scalar(@{$groupby->{attrs}})==1; ##-- are we grouping by a single attribute? -->optimize!
  my $mspai    = (sort {$b->[1]<=>$a->[1]} map {[$_,$a2data->{$groupby->{attrs}[$_]}{enum}->size]} (0..$#{$groupby->{attrs}}))[0][0];
  my $mspa     = $groupby->{attrs}[$mspai];
  my $mspgpack = $groupby->{gpack}[$mspai];
  my $mspxpack = $groupby->{xpack}[$mspai];
  my $msp2x = $a2data->{$mspa}{a2x};
  my %mspv  = qw(); ##-- checked MSPA-values ($mspvi)
  my $xenum = $coldb->{xenum};
  my $pack_xd = "@".(packsize($coldb->{pack_id}) * scalar(@{$coldb->{attrs}})).$coldb->{pack_date};
  my $xs2g    = $groupby->{xs2g};
  my $debug_xp2g = join('',@{$groupby->{xpack}});
  my $debug_gpack= "($coldb->{pack_id})*";
  my ($prf,$pf12, $mspvi,$i2,$x2,$d2,$ds2,$prf2,$key2, $buf,$f2);
  $prf2     = (values %$slice2prf)[0] if (!$filter_by_date);
  foreach $prf (values %$slice2prf) {
    $pf12 = $prf->{f12};
    foreach (keys %$pf12) {
      $mspvi = unpack($mspgpack,$_);
      next if (exists $mspv{$mspvi});
      $mspv{$mspvi} = undef;
      foreach $i2 (@{$msp2x->fetch($mspvi)}) {
	##-- get item2 x-tuple
	$x2  = $xenum->i2s($i2);

	if ($filter_by_date) {
	  ##-- extract item2 date slice
	  $d2  = unpack($pack_xd, $x2);
	  $ds2 = $slice ? int($d2/$slice)*$slice : 0;

	  ##-- ignore if item2 slice isn't in our target range
	  next if (!defined($prf2=$slice2prf->{$ds2})
		   || (defined($dlo) && $d2 < $dlo)
		   || (defined($dhi) && $d2 > $dhi));
	}

	##-- get groupby-key from x-tuple string & check for item2 membership in the appropriate slice-profile
	$key2 = $xs2g ? $xs2g->($x2) : pack($mspgpack, $i2);
	#$key2 = pack($debug_gpack, unpack($debug_xp2g, $x2)); ##-- ca. 6% faster than $xs2g, no having-checks
	#$key2 = pack($debug_gpack, $mspvi); ##-- ca. 12% faster than $xs2g, no having-checks, only valid for groupby single-attribute
	next if (!defined($key2) || !exists($prf2->{f12}{$key2})); ##-- having()-failure or no item2 in target slice

	##-- add item2 frequency
	$f2 = unpack($pack_r1f, $r1->fetchraw($i2,\$buf));
	$prf2->{f2}{$key2} += $f2;
      }
    }
  }

  return $slice2prf;
}


##==============================================================================
## Relation API: default: query info

## \%qinfo = $rel->qinfo($coldb, %opts)
##  + get query-info hash for profile administrivia (ddc hit links)
##  + %opts: as for profile(), additionally:
##    (
##     qreqs => \@qreqs,      ##-- as returned by $coldb->parseRequest($opts{query})
##     gbreq => \%groupby,    ##-- as returned by $coldb->groupby($opts{groupby})
##    )
sub qinfo {
  my ($rel,$coldb,%opts) = @_;
  my ($q1strs,$q2strs,$qxstrs,$fstrs) = $rel->qinfoData($coldb,%opts);

  my $q1str = '('.(@$q1strs ? join(' WITH ', @$q1strs,@$qxstrs) : '*').') =1';
  my $q2str = '('.(@$q2strs ? join(' WITH ', @$q2strs,@$qxstrs) : '*').') =2';
  my $qstr = (
	      #"$q1str && $q2str" ##-- approximate with &&-query (especially buggy since #sep doesn't work right here; see mantis bug #654)
	      "NEAR( $q1str, $q2str, ".(2*($rel->{dmax}-1)).")"
	      .' #SEPARATE'
	      .(@$fstrs ? (' '.join(' ',@$fstrs)) : ''),
	     );
  return {
	  fcoef => 2*$rel->{dmax},
	  qtemplate => $qstr,
	 };
}

##==============================================================================
## Pacakge Alias(es)
package DiaColloDB::Compat::v0_09::Cofreqs;
use strict;
our @ISA = qw(DiaColloDB::Compat::v0_09::Relation::Cofreqs);

##==============================================================================
## Footer
1;

__END__
