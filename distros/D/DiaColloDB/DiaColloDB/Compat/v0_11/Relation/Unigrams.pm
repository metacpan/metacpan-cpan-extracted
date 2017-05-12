## -*- Mode: CPerl -*-
## File: DiaColloDB::Compat::v0_11::Relation::Unigrams.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, profiling relation: unigram database (using DiaColloDB::PackedFile)

package DiaColloDB::Compat::v0_11::Relation::Unigrams;
use DiaColloDB::Relation;
use DiaColloDB::PackedFile;
use DiaColloDB::Utils qw(:fcntl :sort :env :run :pack :file);
use Fcntl qw(:DEFAULT :seek);
use File::Basename qw(dirname);
use version;
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Relation::Unigrams DiaColloDB::Compat);

##==============================================================================
## Constructors etc.

## $ug = CLASS_OR_OBJECT->new(%args)
## + %args, object structure:
##   (
##    ##-- user options
##    base     => $basename,   ##-- file basename (default=undef:none); use files "${base}.dba1", "${base}.dba2", "${base}.hdr"
##    flags    => $flags,      ##-- fcntl flags or open-mode (default='r')
##    perms    => $perms,      ##-- creation permissions (default=(0666 &~umask))
##    pack_i   => $pack_i,     ##-- pack-template for IDs (default='N')
##    pack_f   => $pack_f,     ##-- pack-template for frequencies (default='N')
##    pack_d   => $pack_d,     ##-- pack-tempalte for dates (default='n')
##    keeptmp  => $bool,       ##-- keep temporary files? (default=false)
##    mmap     => $bool,       ##-- use mmap access? (default=true)
##    logCompat => $level,     ##-- log-level for compatibility warnings (default='warn')
##    ##
##    ##-- size info (after open() or load())
##    size1    => $size1,      ##-- == $r1->size()
##    size2    => $size2,      ##-- == $r2->size()
##    ##
##    ##-- low-level data
##    r1 => $r1,               ##-- pf: [$end2]      @ $i1				: constant (logical index)
##    r2 => $r2,               ##-- pf: [$d1,$f1]*   @ end2($i1-1)..(end2($i1+1)-1)	: sorted by $d1 for each $i1
##    N  => $N,                ##-- sum($f1)
##    version => $version,     ##-- file version, for compatibility checks
##   )

## inherited

##==============================================================================
## Persistent API: disk usage

# inherited

##==============================================================================
## I/O

##--------------------------------------------------------------
## I/O: open/close

## $ug_or_undef = $ug->open($base,$flags)
## $ug_or_undef = $ug->open($base)
## $ug_or_undef = $ug->open()
sub open {
  my ($ug,$base,$flags) = @_;
  $base  //= $ug->{base};
  $flags //= $ug->{flags};
  $ug->close() if ($ug->opened);
  $ug->{base}  = $base;
  $ug->{flags} = $flags = fcflags($flags);
  my ($hdr); ##-- save header, for version-checking
  if (fcread($flags) && !fctrunc($flags)) {
    $hdr = ($ug->readHeader() || $ug->readHeader("$ug->{base}.dba.hdr"))
      or $ug->logconfess("failed to read header data from '$ug->{base}.hdr': $!");
    $ug->loadHeaderData($hdr)
      or $ug->logconess("failed to load header data from '$ug->{base}.hdr': $!");
  }

  ##-- check compatibility
  my $min_version = qv(0.10.000);
  if ($hdr && (!defined($hdr->{version}) || version->parse($hdr->{version}) < $min_version)) {
    $ug->vlog($ug->{logCompat}, "using v0.09 compatibility mode for $ug->{base}.*; consider running \`dcdb-upgrade.perl ", dirname($ug->{base}), "\'");
    DiaColloDB::Compat->usecompat('v0_09');
    bless($ug, 'DiaColloDB::Compat::v0_09::Relation::Unigrams');
    $ug->{version} = $hdr->{version};
    return $ug->open("$base.dba",$flags);
  }

  ##-- open low-level data structures
  $ug->{r1}->open("$base.dba1", $flags, perms=>$ug->{perms}, packas=>"$ug->{pack_i}")
    or $ug->logconfess("open failed for $base.dba1: $!");
  $ug->{r2}->open("$base.dba2", $flags, perms=>$ug->{perms}, packas=>"$ug->{pack_d}$ug->{pack_f}")
    or $ug->logconfess("open failed for $base.dba2: $!");
  $ug->{size1} = $ug->{r1}->size;
  $ug->{size2} = $ug->{r2}->size;

  return $ug;
}

## $ug_or_undef = $ug->close()
sub close {
  my $ug = shift;
  if ($ug->opened && fcwrite($ug->{flags})) {
    $ug->saveHeader() or return undef;
  }
  $ug->{r1}->close() or return undef;
  $ug->{r2}->close() or return undef;
  undef $ug->{base};
  return $ug;
}

## $bool = $ug->opened()
sub opened {
  my $ug = shift;
  return
    (defined($ug->{base})
     && defined($ug->{r1}) && $ug->{r1}->opened
     && defined($ug->{r2}) && $ug->{r2}->opened
    );
}

##--------------------------------------------------------------
## I/O: header
##  + inherited

##--------------------------------------------------------------
## I/O: text
##  + inherited

## $bool = $obj->loadTextFile($filename_or_handle, %opts)
##  + wraps loadTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $ug = $ug->loadTextFh($fh,%opts)
##  + loads from text file as saved by saveTextFh()
##  + input fh must be sorted by $i1,$d1
##  + supports multiple lines for pairs ($i1,$d1) provided the above conditions hold
##  + supports loading of $ug->{N} from single-component lines
##  + %opts: clobber %$ug
*loadTextFh = __PACKAGE__->nocompat('loadTextFh');

## $bool = $obj->saveTextFile($filename_or_handle, %opts)
##  + wraps saveTextFh()
##  + INHERITED from DiaColloDB::Persistent

## $bool = $ug->saveTextFh($fh,%opts)
##  + save from text file with lines of the form:
##      N                 ##-- 1 field : N
##      FREQ ID1 DATE     ##-- 3 fields: unigram frequency for (ID1,DATE)
##  + %opts:
##      i2s => \&CODE,    ##-- code-ref for formatting indices; called as $s=CODE($i)

##==============================================================================
## Relation API: create, union
##  + disabled

*create = __PACKAGE__->nocompat('create');
*union  = __PACKAGE__->nocompat('union');

##==============================================================================
## Relation API: dbinfo
##  + inherited

##==============================================================================
## Utilities: lookup

## $N = $cof->sliceN($slice,$dateLo)
##  + get total slice co-occurrence count (compatible wrapper uses constant $cof->{N} for all slices)
sub sliceN {
  #my ($cof,$slice,$dlo) = @_;
  return $_[0]{N};
}

##==============================================================================
## Relation API: default
##  + inherited

##==============================================================================
## Footer
1;

__END__
