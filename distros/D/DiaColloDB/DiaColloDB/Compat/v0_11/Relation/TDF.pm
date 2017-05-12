## -*- Mode: CPerl -*-
##
## File: DiaColloDB::Compat::v0_11::Relation::TDF.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: collocation db, profiling relation: co-occurence frequencies via (term x document) raw-frequency matrix
##  + formerly DiaColloDB::Relation::Vsem.pm ("vector-space distributional semantic index")

package DiaColloDB::Compat::v0_11::Relation::TDF;
use DiaColloDB::Compat;
use DiaColloDB::Relation::TDF;

use DiaColloDB::Relation;
use DiaColloDB::Relation::TDF::Query;
use DiaColloDB::Utils qw(:pack :fcntl :file :math :json :list :pdl :temp :env :run);
use DiaColloDB::PackedFile;
use DiaColloDB::PDL::MM;
use DiaColloDB::PDL::Utils;
use File::Path qw(make_path remove_tree);
use PDL;
use PDL::IO::FastRaw;
use PDL::CCS;
use PDL::CCS::IO::FastRaw;
use Fcntl qw(:DEFAULT SEEK_SET SEEK_CUR SEEK_END);
use strict;

##==============================================================================
## Globals & Constants

our @ISA = qw(DiaColloDB::Relation::TDF DiaColloDB::Compat);

##==============================================================================
## Constructors etc.
##  + inherited

##==============================================================================
## TDF API: Utils
## + inherited

##==============================================================================
## Relation API: open/close

## $vs_or_undef = $vs->open($base)
## $vs_or_undef = $vs->open($base,$flags)
## $vs_or_undef = $vs->open()
sub open {
  my ($vs,$base,$flags) = @_;
  $base  //= $vs->{base};
  $flags //= $vs->{flags};
  $vs->close() if ($vs->opened);
  $vs->{base}  = $base;
  $vs->{flags} = $flags = fcflags($flags);

  if (fcread($flags) && !fctrunc($flags)) {
    $vs->loadHeader()
      or $vs->logconess("failed to load header from '$vs->{base}.hdr': $!");
  }

  ##-- open: maybe create directory
  my $vsdir = "$vs->{base}.d";
  if (!-d $vsdir) {
    $vs->logconfess("open(): no such directory '$vsdir'") if (!fccreat($flags));
    make_path($vsdir)
      or $vs->logconfess("open(): could not create relation directory '$vsdir': $!");
  }

  ##-- open: model data
  my %ioopts = (ReadOnly=>!fcwrite($flags), mmap=>1, log=>$vs->{logIO});
  defined($vs->{tdm} = readPdlFile("$vsdir/tdm", class=>'PDL::CCS::Nd', %ioopts))
    or $vs->logconfess("open(): failed to load term-document frequency matrix from $vsdir/tdm.*: $!");
  defined($vs->{tym} = readPdlFile("$vsdir/tym", class=>'PDL::CCS::Nd', %ioopts))
    or $vs->logconfess("open(): failed to load term-year frequency matrix from $vsdir/tym.*: $!");
  defined($vs->{cf}  = readPdlFile("$vsdir/cf.pdl", %ioopts))
    or $vs->logconfess("open(): failed to load cat-frequencies from $vsdir/cf.pdl: $!");

  defined(my $ptr0 = $vs->{ptr0} = readPdlFile("$vsdir/tdm.ptr0.pdl", %ioopts))
    or $vs->logwarn("open(): failed to load Harwell-Boeing pointer from $vsdir/tdm.ptr0.pdl: $!");
  defined(my $ptr1 = $vs->{ptr1} = readPdlFile("$vsdir/tdm.ptr1.pdl", %ioopts))
    or $vs->logwarn("open(): failed to load Harwell-Boeing pointer from $vsdir/tdm.ptr1.pdl: $!");
  defined(my $pix1 = $vs->{pix1} = readPdlFile("$vsdir/tdm.pix1.pdl", %ioopts))
    or $vs->logwarn("open(): failed to load Harwell-Boeing indices from $vsdir/tdm.pix1.pdl: $!");
  $vs->{tdm}->setptr(0, $ptr0)        if (defined($ptr0));
  $vs->{tdm}->setptr(1, $ptr1,$pix1)  if (defined($ptr1) && defined($pix1));

  ##-- open: aux data: piddles
  foreach (qw(tvals tsorti mvals msorti d2c c2d c2date)) {
    defined($vs->{$_}=readPdlFile("$vsdir/$_.pdl", %ioopts))
      or $vs->logconfess("open(): failed to load piddle data from $vsdir/$_.pdl: $!");
  }

  ##-- open: metadata: enums
  my %efopts = (flags=>$vs->{flags}); #, pack_i=>$coldb->{pack_id}, pack_o=>$coldb->{pack_off}, pack_l=>$coldb->{pack_len}
  foreach my $mattr (@{$vs->{meta}}) {
    $vs->{"meta_e_$mattr"} = $DiaColloDB::ECLASS->new(base=>"$vsdir/meta_e_$mattr", %efopts)
      or $vs->logconfess("open(): failed to open metadata enum $vsdir/meta_e_$mattr: $!");
  }

  return $vs;
}

## $vs_or_undef = $vs->close()
## + INHERITED

## $bool = $obj->opened()
## + INHERITED

##==============================================================================
## Relation API: create, union
## + DISABLED

*create = __PACKAGE__->nocompat("create");
*union = __PACKAGE__->nocompat("union");

##==============================================================================
## Relation API: export
## + INHERITED

##==============================================================================
## Relation API: dbinfo
## + INHERITED

##==============================================================================
## Relation API: profiling & comparison
## + INHERITED

##==============================================================================
## Profile: Utils: PDL-based profiling
## + INHERITED

##==============================================================================
## Profile: Utils: domain sizes
## + mostly INHERITED

## $NY = $vs->nDates()
##  + override returns undef
BEGIN { *nYears = \&nDates; }
sub nDates {
  return undef;
}

##==============================================================================
## Profile: Utils: misc
## + mostly INHERITED

##----------------------------------------------------------------------
## Profile Utils: slice frequency

## $N = $vs->sliceN($sliceBy, $dateLo)
##  + get total slice co-occurrence count, used by vprofile()
sub sliceN {
  #my ($vs,$sliceby,$dlo) = @_;
  return $_[0]{N};
}


##==============================================================================
## Footer
1;

__END__
