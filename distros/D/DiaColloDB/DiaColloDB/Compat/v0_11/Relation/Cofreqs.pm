## -*- Mode: CPerl -*-
## File: DiaColloDB::Compat::v0_11::Relation::Cofreqs.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, profiling relation: co-frequency database (using pair of DiaColloDB::PackedFile)

package DiaColloDB::Compat::v0_11::Relation::Cofreqs;
use DiaColloDB::Compat;
use DiaColloDB::Relation::Cofreqs;
use DiaColloDB::PackedFile;
use DiaColloDB::PackedFile::MMap;
use DiaColloDB::Utils qw(:fcntl :env :run :json :pack);
use Fcntl qw(:DEFAULT :seek);
use File::Basename qw(dirname);
use version;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Relation::Cofreqs DiaColloDB::Compat);

##==============================================================================
## Constructors etc.

## $cof = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- user options
##    class    => $class,      ##-- optional, useful for debugging from header file
##    base     => $basename,   ##-- file basename (default=undef:none); use files "${base}.dba1", "${base}.dba2", "${base}.dba3", "${base}.hdr"
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
##    rN => $rN,               ##-- pf: [$fN]              @ $date - $coldb->{xdmin}            : totals by date
##    N  => $N,                ##-- sum($f12) [only used for version <= 0.11; thereafter replaced by rN]
##    version => $version,     ##-- file version, for compatibility checks
##   )

#inherited

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
  my $min_version = qv(0.10.000);
  if ($hdr && (!defined($hdr->{version}) || version->parse($hdr->{version}) < $min_version)) {
    $cof->vlog($cof->{logCompat}, "using v0.09 compatibility mode for $cof->{base}.*; consider running \`dcdb-upgrade.perl ", dirname($cof->{base}), "\'");
    DiaColloDB::Compat->usecompat('v0_09');
    bless($cof, 'DiaColloDB::Compat::v0_09::Relation::Cofreqs');
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
  $cof->{size1} = $cof->{r1}->size;
  $cof->{size2} = $cof->{r2}->size;
  $cof->{size3} = $cof->{r3}->size;

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
    );
}

##--------------------------------------------------------------
## I/O: header
##  + inherited

##--------------------------------------------------------------
## I/O: text
##  + mostly inherited

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
*loadTextFh = __PACKAGE__->nocompat('loadTextFh');

## $bool = $cof->saveTextFh($fh,%opts)
##  + save from text file with lines of the form:
##      N                 ##-- 1 field : N
##      FREQ ID1 DATE     ##-- 3 fields: un-collocated portion of $f1
##      FREQ ID1 DATE ID2 ##-- 4 fields: co-frequency pair (ID2 >= 0)
##  + %opts:
##      i2s => \&CODE,    ##-- code-ref for formatting indices; called as $s=CODE($i)
##      i2s1 => \&CODE,   ##-- code-ref for formatting item1 indices (overrides 'i2s')
##      i2s2 => \&CODE,   ##-- code-ref for formatting item2 indices (overrides 'i2s')

##==============================================================================
## Relation API: create, union
##  + disabled

*create = __PACKAGE__->nocompat('create');
*union  = __PACKAGE__->nocompat('union');

##==============================================================================
## Relation API: dbinfo
## + inherited

##==============================================================================
## Utilities: lookup
##  + mostly BROKEN in v0.10.000 (x(+date)->t(-date) db tuples)
##  + inherited

## $N = $cof->sliceN($slice,$dateLo)
##  + get total slice co-occurrence count (compatible wrapper uses constant $cof->{N} for all slices)
sub sliceN {
  #my ($cof,$slice,$dlo) = @_;
  return $_[0]{N};
}

##==============================================================================
## Relation API: default
## + inherited

##==============================================================================
## Footer
1;

__END__
