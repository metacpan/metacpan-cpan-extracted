## -*- Mode: CPerl -*-
## File: DiaColloDB::Relation::Cofreqs.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, profiling relation: co-frequency database (using pair of DiaColloDB::PackedFile)

package DiaColloDB::Relation::Cofreqs;
use DiaColloDB::Compat;
use DiaColloDB::Relation;
use DiaColloDB::PackedFile;
use DiaColloDB::PackedFile::MMap;
use DiaColloDB::Utils qw(:fcntl :env :run :json :pack);
use Fcntl qw(:DEFAULT :seek);
use File::Basename qw(dirname);
use version;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Relation);

## $PFCLASS : object class for nested PackedFile objects
our $PFCLASS = 'DiaColloDB::PackedFile::MMap';

##==============================================================================
## Constructors etc.

## $cof = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- user options
##    class    => $class,      ##-- optional, useful for debugging from header file
##    base     => $basename,   ##-- file basename (default=undef:none); use files "${base}.dba1", "${base}.dba2", "${base}.dba3", "${base}.dbaN", "${base}.hdr"
##    flags    => $flags,      ##-- fcntl flags or open-mode (default='r')
##    perms    => $perms,      ##-- creation permissions (default=(0666 &~umask))
##    dmax     => $dmax,       ##-- maximum distance for co-occurrences (default=5)
##    fmin     => $fmin,       ##-- minimum pair frequency (default=0)
##    pack_i   => $pack_i,     ##-- pack-template for IDs (default='N')
##    pack_f   => $pack_f,     ##-- pack-template for frequencies (default='N')
##    pack_d   => $pack_d,     ##-- pack-tempalte for dates (default='n')
##    keeptmp  => $bool,       ##-- keep temporary files? (default=false)
##    logCompat => $level,     ##-- log-level for compatibility warnings (default='warn')
##    ##
##    ##-- size info (after open() or load())
##    size1    => $size1,      ##-- == $r1->size()
##    size2    => $size2,      ##-- == $r2->size()
##    size3    => $size3,      ##-- == $r3->size()
##    sizeN    => $sizeN,      ##-- == $rN->size()
##    ##
##    ##-- low-level data
##    r1 => $r1,               ##-- pf: [$end2]            @ $i1				: constant (logical index)
##    r2 => $r2,               ##-- pf: [$end3,$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)	: sorted by $d1 for each $i1
##    r3 => $r3,               ##-- pf: [$i2,$f12]*        @ end3($d1-1)..(end3($d1+1)-1)	: sorted by $i2 for each ($i1,$d1)
##    rN => $rN,               ##-- pf: [$fN]              @ $date - $ymin                      : totals by date
##    ymin => $dmin,           ##-- constant == $coldb->{xdmin}
##    N  => $N,                ##-- sum($f12) [always used for version <= 0.11; used here only for slice==0]
##    version => $version,     ##-- file version, for compatibility checks
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
		    pack_d=>'n',
		    N  => 0,
		    version => $DiaColloDB::VERSION,
		    logCompat => 'warn',
		    @_
		   }, (ref($that)||$that));
  $cof->{$_} //= $cof->mmclass($PFCLASS)->new() foreach (qw(r1 r2 r3 rN));
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
  my ($hdr); ##-- save header, for version-checking
  if (fcread($flags) && !fctrunc($flags)) {
    $hdr = $cof->readHeader()
      or $cof->logconess("failed to read header data from '$cof->{base}.hdr': $!");
    $cof->loadHeaderData($hdr)
      or $cof->logconess("failed to load header data from '$cof->{base}.hdr': $!");
  }

  ##-- check compatibility
  my $min_version = qv(0.12.000);
  if ($hdr && (!defined($hdr->{version}) || version->parse($hdr->{version}) < $min_version)) {
    $cof->vlog($cof->{logCompat}, "using v0.11 compatibility mode for $cof->{base}.*; consider running \`dcdb-upgrade.perl ", dirname($cof->{base}), "\'");
    DiaColloDB::Compat->usecompat('v0_11');
    bless($cof, 'DiaColloDB::Compat::v0_11::Relation::Cofreqs');
    $cof->{version} = $hdr->{version};
    return $cof->open($base,$flags);
  }

  ##-- open low-level data structures
  $cof->{r1}->open("$base.dba1", $flags, perms=>$cof->{perms}, packas=>"$cof->{pack_i}")
    or $cof->logconfess("open failed for $base.dba1: $!");
  $cof->{r2}->open("$base.dba2", $flags, perms=>$cof->{perms}, packas=>"$cof->{pack_i}$cof->{pack_d}$cof->{pack_f}")
    or $cof->logconfess("open failed for $base.dba2: $!");
  $cof->{r3}->open("$base.dba3", $flags, perms=>$cof->{perms}, packas=>"$cof->{pack_i}$cof->{pack_f}")
    or $cof->logconfess("open failed for $base.dba3: $!");
  $cof->{rN}->open("$base.dbaN", $flags, perms=>$cof->{perms}, packas=>"$cof->{pack_f}")
    or $cof->logconfess("open failed for $base.dbaN: $!");
  $cof->{size1} = $cof->{r1}->size;
  $cof->{size2} = $cof->{r2}->size;
  $cof->{size3} = $cof->{r3}->size;
  $cof->{sizeN} = $cof->{rN}->size;

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
  $cof->{r3}->close() or return undef;
  $cof->{rN}->close() or return undef;
  undef $cof->{base};
  return $cof;
}

## $bool = $cof->opened()
sub opened {
  my $cof = shift;
  return
    (defined($cof->{base})
     && defined($cof->{r1}) && $cof->{r1}->opened
     && defined($cof->{r2}) && $cof->{r2}->opened
     && defined($cof->{r3}) && $cof->{r3}->opened
     && defined($cof->{rN}) && $cof->{rN}->opened
    );
}

##--------------------------------------------------------------
## I/O: header
##  + largely INHERITED from DiaColloDB::Persistent

## @keys = $cof->headerKeys()
##  + keys to save as header
sub headerKeys {
  return grep {!ref($_[0]{$_}) && $_ !~ m{^(?:base|flags|perms|log.*)$}} keys %{$_[0]};
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
##  + loads from text file as saved by saveTextFh():
##      N                       ##-- 1 field : N
##      FREQ ID1 DATE           ##-- 3 fields: un-collocated portion of $f1
##      FREQ ID1 DATE ID2       ##-- 4 fields: co-frequency pair (ID2 >= 0)
##      FREQ ID1 DATE ID2 DATE2 ##-- 5 fields: redundant date (used by create(); DATE2 is ignored)
##  + supports semi-sorted input: input fh must be sorted by $i1,$d1
##    and all $i2 for each $i1,$d1 must be adjacent (i.e. no intervening ($j1,$e1) with $j1 != $i1 or $e1 != $d1)
##  + supports multiple lines for pairs ($i1,$d1,$i2) provided the above conditions hold
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
  ##   $r1 : [$end2]            @ $i1
  ##   $r2 : [$end3,$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)
  ##   $r3 : [$i2,$f12]*        @ end3($d1-1)..(end3($d1+1)-1)
  my $fmin  = $cof->{fmin} // 0;
  my ($r1,$r2,$r3,$rN)            = @$cof{qw(r1 r2 r3 rN)};
  my ($pack_r1,$pack_r2,$pack_r3) = map {$_->{packas}} ($r1,$r2,$r3);
  $r1->truncate();
  $r2->truncate();
  $r3->truncate();
  $rN->truncate();
  my ($fh1,$fh2,$fh3) = ($r1->{fh},$r2->{fh},$r3->{fh});

  ##-- iteration variables
  my ($pos1,$pos2,$pos3) = (0,0,0);
  my ($i1_cur,$d1_cur,$f1) = (-1,undef,0);
  my ($f12,$i1,$d1,$i2,$d2,$f);
  my $N  = 0;	  ##-- total marginal frequency as extracted from %f12
  my $N1 = 0;     ##-- total N as extracted from single-element records
  my %f12 = qw(); ##-- ($i2=>$f12, ...) for $i1_cur
  my %fN  = qw(); ##-- ($d=>$Nd, ...)

  ##-- guts for inserting records from $i1_cur,$d1_cur,%f12,$pos1,$pos2 : call on changed ($i1_cur,$d1_cur)
  my $insert = sub {
    if ($i1_cur >= 0) {
      if ($i1_cur != $pos1) {
	##-- we've skipped one or more $i1 because it had no collocates (e.g. kern01 i1=287123="Untier/1906")
	$fh1->print( pack($pack_r1,$pos2) x ($i1_cur-$pos1) );
	$pos1 = $i1_cur;
      }

      ##-- dump r3-records for ($i1_cur,$d1_cur,*)
      $f1 = 0;
      foreach (sort {$a<=>$b} keys %f12) {
	$f    = $f12{$_};
	$f1  += $f;
	next if ($f < $fmin || $_ < 0); ##-- skip here so we can track "real" marginal frequencies
	$fh3->print(pack($pack_r3, $_,$f));
	++$pos3;
      }

      ##-- dump r2-record for ($i1_cur,$d1_cur), and track $fN by date
      if (defined($d1_cur)) {
	$fh2->print(pack($pack_r2, $pos3,$d1_cur,$f1));
	$fN{$d1_cur} += $f1;
	++$pos2;
      }

      ##-- maybe dump r1-record for $i1_cur
      if ($i1 != $i1_cur) {
	$fh1->print(pack($pack_r1, $pos2));
	$pos1  = $i1_cur+1;
      }
      $N += $f1;
    }
    $i1_cur = $i1;
    $d1_cur = $d1;
    %f12    = qw();
  };

  ##-- ye olde loope
  binmode($infh,':raw');
  while (defined($_=<$infh>)) {
    chomp;
    ($f12,$i1,$d1,$i2,$d2) = split(' ',$_,5);
    if (!defined($i1)) {
      #$cof->debug("N1 += $f12");
      $N1 += $f12;		      ##-- load N values
      next;
    }
    elsif (!defined($d1)) {
      $cof->logconfess("loadTextFh(): failed to parse input line ", $infh->input_line_number);
    }
    $insert->()			      ##-- insert record(s) for ($i1_cur,$d1_cur)
      if ($i1 != $i1_cur || $d1 != $d1_cur);
    $f12{$i2//-1} += $f12;            ##-- buffer co-frequencies for ($i1_cur,$d1_cur); track un-collocated frequencies as $i2=-1
  }
  $i1 = -1;
  $insert->();                        ##-- write record(s) for final ($i1_cur,$d1_cur)

  ##-- create $rN by date
  my @dates  = sort {$a<=>$b} keys %fN;
  my $ymin   = $cof->{ymin} = $dates[0];
  $rN->{fh}->print(pack("($rN->{packas})*", map {$fN{$_}//0} ($ymin..$dates[$#dates])));

  ##-- adopt final $N and sizes
  #$cof->debug("FINAL: N1=$N1, N=$N");
  $cof->{N} = $N1>$N ? $N1 : $N;
  foreach (qw(1 2 3 N)) {
    my $r = $cof->{"r$_"};
    $r->flush();
    $cof->{"size$_"} = $r->size;
  }

  return $cof;
}

## $cof = $cof->loadTextFile_create($fh,%opts)
##  + old version of loadTextFile() which doesn't support N, semi-sorted input, or multiple ($i1,$i2) entries
##  + not useable by union() method
##  + obsolete; now just an alias for loadTextFile()
sub loadTextFile_create {
  my $cof = shift;
  return $cof->loadTextFile(@_);
}

## $bool = $obj->saveTextFile($filename_or_handle, %opts)
##  + wraps saveTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $bool = $cof->saveTextFh($fh,%opts)
##  + save from text file with lines of the form:
##      N                 ##-- 1 field : N
##      FREQ ID1 DATE     ##-- 3 fields: un-collocated portion of $f1
##      FREQ ID1 DATE ID2 ##-- 4 fields: co-frequency pair (ID2 >= 0)
##  + %opts:
##      i2s => \&CODE,    ##-- code-ref for formatting indices; called as $s=CODE($i)
##      i2s1 => \&CODE,   ##-- code-ref for formatting item1 indices (overrides 'i2s')
##      i2s2 => \&CODE,   ##-- code-ref for formatting item2 indices (overrides 'i2s')
sub saveTextFh {
  my ($cof,$outfh,%opts) = @_;
  $cof->logconfess("saveTextFile(): cannot save unopened DB") if (!$cof->opened);

  ##-- common variables
  ##   $r1 : [$end2]            @ $i1
  ##   $r2 : [$end3,$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)
  ##   $r3 : [$i2,$f12]*        @ end3($d1-1)..(end3($d1+1)-1)
  my ($r1,$r2,$r3) = @$cof{qw(r1 r2 r3)};
  my ($pack1,$pack2,$pack3) = map {$_->{packas}} ($r1,$r2,$r3);
  my $i2s  = $opts{i2s};
  my $i2s1 = exists($opts{i2s1}) ? $opts{i2s1} : $i2s;
  my $i2s2 = exists($opts{i2s2}) ? $opts{i2s2} : $i2s;

  ##-- iteration variables
  my ($buf1,$i1,$s1,$end2);
  my ($buf2,$off2,$end3,$d1,$f1);
  my ($buf3,$off3,$i2,$s2,$f12,$f12sum);

  ##-- ye olde loope
  binmode($outfh,':raw');
  $outfh->print($cof->{N}, "\n");
  for ($r1->seek($i1=0), $r2->seek($off2=0), $r3->seek($off3=0); !$r1->eof(); ++$i1) {
    $r1->read(\$buf1) or $cof->logconfess("saveTextFile(): failed to read record $i1 from $r1->{file}: $!");
    $end2 = unpack($pack1,$buf1);
    $s1 = $i2s1 ? $i2s1->($i1) : $i1;

    for ( ; $off2 < $end2 && !$r2->eof(); ++$off2) {
      $r2->read(\$buf2) or $cof->logconfess("saveTextFile(): failed to read record $off2 from $r2->{file}: $!");
      ($end3,$d1,$f1) = unpack($pack2,$buf2);

      for ($f12sum=0; $off3 < $end3 && !$r3->eof(); ++$off3) {
	$r3->read(\$buf3) or $cof->logconfess("saveTextFile(): failed to read record $off3 from $r3->{file}: $!");
	($i2,$f12) = unpack($pack3,$buf3);
	$f12sum   += $f12;
	$s2        = $i2s2 ? $i2s2->($i2) : $i2;
	$outfh->print(join("\t", $f12, $s1, $d1, $s2), "\n");
      }

      ##-- track un-collocated portion of ($f1,$d1), if any
      $outfh->print(join("\t", $f1-$f12sum, $s1, $d1), "\n") if ($f12sum != $f1);
    }
  }

  return $cof;
}

##==============================================================================
## Relation API: create

## $rel = $CLASS_OR_OBJECT->create($coldb,$tokdat_file,%opts)
##  + populates current database from $tokdat_file,
##    a tt-style text file with lines of the form:
##      TID DATE	##-- single token
##	"\n"		##-- blank line: EOS
##  + %opts: clobber %$ug
sub create {
  my ($cof,$coldb,$tokfile,%opts) = @_;

  ##-- create/clobber
  $cof = $cof->new() if (!ref($cof));
  @$cof{keys %opts} = values %opts;

  ##-- ensure openend
  $cof->opened
    or $cof->open(undef,'rw')
      or $cof->logconfess("create(): failed to open co-frequency database '", ($cof->{base}//'-undef-'), "': $!");

  ##-- token reader fh
  CORE::open(my $tokfh, "<$tokfile")
    or $cof->logconfess("create(): open failed for token-file '$tokfile': $!");
  binmode($tokfh,':raw');

  ##-- sort filter
  env_push(LC_ALL=>'C');
  my $tmpfile = "$cof->{base}.dat";
  my $sortfh = opencmd("| sort -nk1 -nk2 -nk3 | uniq -c - $tmpfile")
    or $cof->logconfess("create(): open failed for pipe to sort|uniq: $!");
  binmode($sortfh,':raw');

  ##-- stage1: generate pairs
  my $n = $cof->{dmax} // 1;
  $cof->vlog('trace', "create(): stage1: generate pairs (dmax=$n)");
  my (@sent,$i,$j,$wi,$wj);
  while (!eof($tokfh)) {
    @sent = qw();
    while (defined($_=<$tokfh>)) {
      chomp;
      last if (/^$/ );
      push(@sent,$_);
    }
    next if (!@sent);

    ##-- get pairs
    foreach $i (0..$#sent) {
      $wi = $sent[$i];
      print $sortfh
	(map {"$wi\t$sent[$_]\n"}
	 grep {$_>=0 && $_<=$#sent && $_ != $i}
	 (($i-$n)..($i+$n))
	);
    }
  }
  $sortfh->close()
    or $cof->logconfess("create(): failed to close pipe to sort|uniq: $!");
  env_pop();

  ##-- stage2: load pair-frequencies
  $cof->vlog('trace', "create(): stage2: load pair frequencies (fmin=$cof->{fmin})");
  $cof->loadTextFile($tmpfile)
    or $cof->logconfess("create(): failed to load pair frequencies from $tmpfile: $!");

  ##-- stage3: header
  $cof->saveHeader()
    or $cof->logconfess("create(): failed to save header: $!");

  ##-- unlink temp file
  unlink($tmpfile) if (!$cof->{keeptmp});

  ##-- done
  return $cof;
}

##==============================================================================
## Relation API: union


## $cof = CLASS_OR_OBJECT->union($coldb, \@pairs, %opts)
##  + merge multiple unigram unigram indices from \@pairs into new object
##  + @pairs : array of pairs ([$cof,\@ti2u],...)
##    of unigram-objects $cof and tuple-id maps \@ti2u for $cof
##    - \@ti2u may also be a mapping object supporting a toArray() method
##  + %opts: clobber %$cof
##  + implicitly flushes the new index
sub union {
  my ($cof,$coldb,$pairs,%opts) = @_;

  ##-- create/clobber
  $cof = $cof->new() if (!ref($cof));
  @$cof{keys %opts} = values %opts;

  ##-- tempfile (input for sort)
  my $tmpfile = "$cof->{base}.udat";
  my $tmpfh   = IO::File->new(">$tmpfile")
    or $cof->logconfess("union(): open failed for tempfile $tmpfile: $!");
  binmode($tmpfh,':raw');

  ##-- stage1: extract pairs and N
  $cof->vlog('trace', "union(): stage1: collect pairs");
  my ($pair,$pcof,$pi2u);
  my $pairi=0;
  foreach $pair (@$pairs) {
    ($pcof,$pi2u) = @$pair;
    $pi2u         = $pi2u->toArray() if (UNIVERSAL::can($pi2u,'toArray'));
    $pcof->saveTextFh($tmpfh, i2s=>sub {$pi2u->[$_[0]]})
      or $cof->logconfess("union(): failed to extract pairs for argument $pairi");
    ++$pairi;
  }
  $tmpfh->close()
    or $cof->logconfess("union(): failed to close tempfile $tmpfile: $!");

  ##-- stage2: sort & load tempfile
  env_push(LC_ALL=>'C');
  $cof->vlog('trace', "union(): stage2: load pair frequencies (fmin=$cof->{fmin})");
  my $sortfh = opencmd("sort -n -k2 -k3 -k4 $tmpfile |")
    or $cof->logconfess("union(): open failed for pipe from sort: $!");
  binmode($sortfh,':raw');
  $cof->loadTextFh($sortfh)
    or $cof->logconfess("union(): failed to load pair frequencies from $tmpfile: $!");
  $sortfh->close()
    or $cof->logconfess("union(): failed to close pipe from sort: $!");
  env_pop();

  ##-- stage3: header
  $cof->saveHeader()
    or $cof->logconfess("union(): failed to save header: $!");

  ##-- cleanup: unlink temp file
  CORE::unlink($tmpfile) if (!$cof->{keeptmp});

  return $cof;
}

##==============================================================================
## Relation API: dbinfo

## \%info = $rel->dbinfo($coldb)
##  + embedded info-hash for $coldb->dbinfo()
sub dbinfo {
  my $cof = shift;
  my $info = $cof->SUPER::dbinfo();
  @$info{qw(fmin dmax size1 size2 size3 sizeN N)} = @$cof{qw(fmin dmax size1 size2 size3 sizeN N)};
  return $info;
}


##==============================================================================
## Utilities: lookup

## $f = $cof->f1( @xids)
## $f = $cof->f1(\@xids)
##  + get total marginal unigram frequency (db must be opened)
##  + no longer supported since v0.10.000
sub f1 {
  $_[0]->logconfess("f1(): method no longer supported");
}

## $f12 = $cof->f12($xid1,$xid2)
##  + return joint frequency for pair ($xid1,$xid2)
##  + no longer supported since v0.10.000
sub f12 {
  $_[0]->logconfess("f12(): method no longer supported");
}

##==============================================================================
## Relation API: default

##--------------------------------------------------------------
## Relation API: default: sliceN

## $N = $rel->sliceN($sliceBy, $dateLo)
##  + get total slice-wise co-occurrence count for a slice of size $sliceBy starting at $dateLo
##  + INHERITED from DiaColloDB::Relation

##--------------------------------------------------------------
## Relation API: default: profile

## \%slice2prf = $rel->subprofile1(\@tids,\%opts)
##  + get slice-wise joint co-frequency profile(s) for @tids (db must be opened; f1 and f12 only)
##  + %opts: as for profile(), also:
##     coldb => $coldb,   ##-- parent DiaColloDB object (for shared data, debugging)
##     dreq  => \%dreq,   ##-- parsed date request
sub subprofile1 {
  my ($cof,$tids,$opts) = @_;

  ##-- common variables
  $tids = [$tids] if (!UNIVERSAL::isa($tids,'ARRAY'));
  my $coldb = $opts->{coldb};
  my $slice = $opts->{slice};
  my $dreq  = $opts->{dreq};
  my $dfilter = $dreq->{dfilter};
  my $groupby = $opts->{groupby}{ti2g};
  my $onepass = $opts->{onepass};
  my $pack_id = $coldb->{pack_id};

  ##-- vars: relation-wise
  ##   $r1 : [$end2]            @ $i1
  ##   $r2 : [$end3,$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)
  ##   $r3 : [$i2,$f12]*        @ end3($d1-1)..(end3($d1+1)-1)
  my ($r1,$r2,$r3)          = @$cof{qw(r1 r2 r3)};
  my ($pack1,$pack2,$pack3) = map {$_->{packas}} ($r1,$r2,$r3);
  my $pack2e = $cof->{pack_i};
  my $pack2d = '@'.packsize("$cof->{pack_i}").$cof->{pack_d};
  my $pack2f = '@'.packsize("$cof->{pack_i}$cof->{pack_d}").$cof->{pack_f};
  my $size1  = $cof->{size1} // ($cof->{size1}=$r1->size);
  my $size2  = $cof->{size2} // ($cof->{size2}=$r2->size);
  my $size3  = $cof->{size3} // ($cof->{size3}=$r3->size);

  ##-- setup %slice2prf
  my %slice2prf = map {
    ($_ => DiaColloDB::Profile->new(f1=>0, N=>$cof->sliceN($slice,$_)))
  } ($slice ? (map {$_*$slice} (($dreq->{slo}/$slice)..($dreq->{shi}/$slice))) : 0);

  ##-- ye olde loope
  my ($i1,$beg2,$end2, $pos2,$beg3,$end3,$d1,$ds,$dprf,$f1, $pos3,$i2,$f12,$key2, $buf,%id2);
  my ($blo,$bhi,$bi); ##-- one-pass guts
  foreach $i1 (@$tids) {
    next if ($i1 >= $size1);
    $beg2 = ($i1==0 ? 0 : unpack($pack1,$r1->fetchraw($i1-1,\$buf)));
    $end2 = unpack($pack1, $r1->fetchraw($i1,\$buf));

    next if ($beg2 >= $size2);
    for ($pos2=$beg2; $pos2 < $end2; ++$pos2) {
      $beg3           = ($pos2==0 ? 0 : unpack($pack2e, $r2->fetchraw($pos2-1,\$buf)));
      ($end3,$d1,$f1) = unpack($pack2, $r2->fetchraw($pos2,\$buf));

      ##-- check date-filter & get slice-local profile $dprf
      next if ($dfilter && !$dfilter->($d1));
      $ds   = $slice ? int($d1/$slice)*$slice : 0;
      $dprf = $slice2prf{$ds};
      $dprf->{f1} += $f1;

      next if ($beg3 >= $size3);
      for ($pos3=$beg3; $pos3 < $end3; ++$pos3) {
	($i2,$f12) = unpack($pack3, $r3->fetchraw($pos3,\$buf));
	$key2      = $groupby ? $groupby->($i2) : pack($pack_id,$i2);
	next if (!defined($key2)); ##-- item2 selection via groupby CODE-ref
	$dprf->{f12}{$key2} += $f12;

	if ($onepass && !exists($id2{"$i2 $d1"})) {
	  ##-- search for ($i2,$date) offset in r2
	  $id2{"$i2 $d1"} = undef;
	  $blo = ($i2==0 ? 0 : unpack($pack1,$r1->fetchraw($i2-1,\$buf)));
	  $bhi = unpack($pack1, $r1->fetchraw($i2,\$buf));
	  $bi  = $r2->bsearch($d1,lo=>$blo,hi=>$bhi,packas=>$pack2d);
	  $dprf->{f2}{$key2} += unpack($pack2f, $r2->fetchraw($bi,\$buf));
	}
      }
    }
  }

  return \%slice2prf;
}

##--------------------------------------------------------------
## Relation API: default: subprofile2

##  \%slice2prf = $rel->subprofile2(\%slice2prf, \%opts)
##  + populate f2 frequencies for profiles in \%slice2prf
##  + %opts: as for subprofile1()
sub subprofile2 {
  my ($cof,$slice2prf,$opts) = @_;

  ##-- vars: common
  my $coldb   = $opts->{coldb};
  my $groupby = $opts->{groupby};
  my $a2data  = $opts->{a2data};
  my $slice   = $opts->{slice};
  my $dfilter = $opts->{dreq}{dfilter};

  ##-- vars: relation-wise
  ##   $r1 : [$end2]            @ $i1
  ##   $r2 : [$end3,$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)
  ##   #$r3 : [$i2,$f12]*        @ end3($d1-1)..(end3($d1+1)-1)
  my ($r1,$r2)  = @$cof{qw(r1 r2)};
  my $pack1   = $r1->{packas};
  my $pack2df = '@'.packsize("$cof->{pack_i}",0)."$cof->{pack_d}$cof->{pack_i}";

  ##-- optimize tightest loop for direct mmap buffer access if available
  my $bufr2 = UNIVERSAL::isa($r2,'DiaColloDB::PackedFile::MMap') ? $r2->{bufr} : undef;
  my $len2  = $r2->{reclen};

  ##-- get "most specific projected attribute" ("MSPA"): that projected attribute with largest enum
  #my $gb1      = scalar(@{$groupby->{attrs}})==1; ##-- are we grouping by a single attribute? -->optimize!
  my $mspai    = (sort {$b->[1]<=>$a->[1]} map {[$_,$a2data->{$groupby->{attrs}[$_]}{enum}->size]} (0..$#{$groupby->{attrs}}))[0][0];
  my $mspa     = $groupby->{attrs}[$mspai];
  my $mspgpack = $groupby->{gpack}[$mspai];
  my $msptpack = $groupby->{tpack}[$mspai];
  my $msp2t    = $a2data->{$mspa}{a2t};
  my %mspv     = qw(); ##-- checked MSPA-values ($mspvi)
  my $tenum    = $coldb->{tenum};
  my $ts2g     = $groupby->{ts2g};

  my ($prf1, $mspvi,$i2,$t2,$key2, $beg2,$end2,$pos2, $d2,$f2,$ds2,$prf2, $buf);
  foreach $prf1 (values %$slice2prf) {
    foreach (keys %{$prf1->{f12}}) {
      $mspvi = unpack($mspgpack,$_);
      next if (exists $mspv{$mspvi});
      $mspv{$mspvi} = undef;

      foreach $i2 (@{$msp2t->fetch($mspvi)}) {
	##-- get item2 t-tuple
	$t2 = $tenum->i2s($i2);

	##-- get groupby-key from tuple-string
	next if (!defined($key2 = $ts2g ? $ts2g->($t2) : pack($mspgpack, $i2))); ##-- having() failure

	##-- scan all dates for $i2
	$beg2 = ($i2==0 ? 0 : unpack($pack1,$r1->fetchraw($i2-1,\$buf)));
	$end2 = unpack($pack1, $r1->fetchraw($i2,\$buf));
	for ($pos2=$beg2; $pos2 < $end2; ++$pos2) {
	  ($d2,$f2) = unpack($pack2df, $bufr2 ? substr($$bufr2, $pos2*$len2, $len2) : $r2->fetchraw($pos2,\$buf));

	  ##-- check date-filter & get slice
	  next if ($dfilter && !$dfilter->($d2));
	  $ds2 = $slice ? int($d2/$slice)*$slice : 0;

	  ##-- ignore if item2 isn't in target slice
	  $prf2 = $slice2prf->{$ds2};
	  next if (!exists($prf2->{f12}{$key2}));

	  ##-- add independent f2
	  $prf2->{f2}{$key2} += $f2;
	}
      }
    }
  }

  return $slice2prf;
}

##--------------------------------------------------------------
## Relation API: default: subextend

## \%slice2prf = $rel->subextend(\%slice2prf,\%opts)
##  + populate f2 frequencies for profiles in \%slice2prf
##  + %opts: as for subprofile1()
##  + override calls subprofile2()
sub subextend {
  my $cof = shift;
  return $cof->subprofile2(@_);
}

##--------------------------------------------------------------
## Relation API: default: qinfo

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
package DiaColloDB::Cofreqs;
use strict;
our @ISA = qw(DiaColloDB::Relation::Cofreqs);


##==============================================================================
## Footer
1;

__END__
