## -*- Mode: CPerl -*-
## File: DiaColloDB::XS::CofUtils.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Descript: DiaColloDB: C++ utilities for Cofreqs relation compilation

package DiaColloDB::XS::CofUtils;
use DiaColloDB::XS;
use DiaColloDB::Utils qw(:run :env :math :temp :pack :fcntl :jobs);
use Exporter;
use strict;

##======================================================================
## Globals & Exports
BEGIN {
  #print STDERR "*** loading ", __PACKAGE__, " ***\n"; ##-- DEBUG
}

our @ISA = qw(Exporter);

our @EXPORT = qw();
our %EXPORT_TAGS =
  (
   'cof' => [qw(generatePairsXS loadTextFhXS)],
  );
our @EXPORT_OK = map {@$_} values(%EXPORT_TAGS);
$EXPORT_TAGS{all} = [@EXPORT_OK];


##======================================================================
## Cofreqs wrappers

##--------------------------------------------------------------
## $cof_or_undef = $cof->generatePairsXS( $tokfile, $outfile )
##  + XS implementation of DiaColloDB::Relation::Cofreqs::generatePairs()
sub generatePairsXS {
  my ($cof,$tokfile,$outfile) = @_;
  $cof->vlog($cof->{logXS}, "generatePairs(): using XS implementation");

  my $dmax = $cof->{dmax} // 1;
  $outfile = "$cof->{base}.dat" if (!$outfile);
  my $tmpfile = tmpfile("$outfile.tmp", UNLINK=>(!$cof->{keeptmp}))
    or $cof->logconfess("failed to create temp-file '$outfile.tmp': $!");

  env_push('LC_ALL'=>'C'
           #OMP_NUM_THREADS=>nJobs(), ##-- no effect after DiaColloDB/XS.so has been loaded
          );
  generatePairsTmpXS($tokfile, $tmpfile, ($cof->{dmax}//1))==0
    or $cof->logconfess("failed to generate co-occurrence frequencies for '$tokfile' to '$tmpfile': $!");
  runcmd("sort -nk1 -nk2 -nk3 ".sortJobs()." $tmpfile | uniq -c - $outfile")==0
    or $cof->logconfess("failed to collate co-occurrence frequencies from '$tmpfile' to '$outfile': $!");

  env_pop();

  return $cof;
}

##--------------------------------------------------------------
## utilities for loadTextFh

## $bool = canCompileXS32($cof)
sub canCompileXS32 {
  my $cof = shift;
  return (packeq($cof->{pack_i},'N')
          && packeq($cof->{pack_f},'N')
          && packeq($cof->{pack_d},'n'));
}

## $bool = canCompileXS64($cof)
sub canCompileXS64 {
  my $cof = shift;
  return (packeq($cof->{pack_i},'Q>')
          && packeq($cof->{pack_f},'Q>')
          && packeq($cof->{pack_d},'n'));
}

##--------------------------------------------------------------
## $cof = $cof->loadTextFhXS($fh,%opts)
##  + XS implementation of DiaColloDB::Relation::Cofreqs::loadTextFh()
sub loadTextFhXS {
  my ($cof,$infh,%opts) = @_;
  $cof->logconfess("loadTextFhXS(): cannot load unopened database!") if (!$cof->opened);

  ##-- underlying XS method
  my ($xsub);
  if (canCompileXS32($cof)) {
    $xsub = \&loadTextFhXS32;
  } elsif (canCompileXS64($cof)) {
    $xsub = \&loadTextFhXS64;
  } else {
    $cof->vlog('logCompat', "loadTextFhXS(): no XS support for pack signature (int:$cof->{pack_i}, freq:$cof->{pack_f}, date:$cof->{pack_date}) - using pure-perl fallback");
    return $cof->loadTextFhPP($infh,%opts);
  }
  $cof->vlog($cof->{logXS}, "loadTextFH(): using XS implementation");

  ##-- close packed-files
  $_->close() foreach (@$cof{qw(r1 r2 r3 rN)});

  ##-- guts: populate packed-file data via XS
  my $fmin = ($cof->{fmin} // 0);
  $xsub->($infh, "$infh", $cof->{base}, $fmin)==0
    or $cof->logconfess("loadTextFhXS(): failed to compile input data");

  ##-- bootstrap: get constants written by XS-compiler
  open(my $constfh, "<$cof->{base}.const")
    or $cof->logconfess("failed to open constants file $cof->{base}.const: $!");
  @$cof{qw(ymin N)} = map {($_//0)+0} split(' ', scalar(<$constfh>), 2);
  close($constfh);

  ##-- bootstrap/compat: re-open relations in append-mode & get sizes
  foreach (qw(1 2 3 N)) {
    my $r = $cof->{"r$_"};
    $r->open(undef, fcflags('rwa'));
    delete($r->{size});
    $r->flush();
    $cof->{"size$_"} = $r->size();
  }

  ##-- cleanup
  push(@DiaColloDB::Utils::TMPFILES, "$cof->{base}.const") if (!$cof->{keeptmp});

  return $cof;
}

1; ##-- be happy

__END__
