use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Games::NeverwinterNights::Query',
    'VERSION'	        => '1.0',
    'PREREQ_PM'		=> {IO::Handle => 1.0, bignum => 0.1, Carp => 1.0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Classes for querying Neverwinter Nights',
       AUTHOR     => 'Salvatore ScottoDiLuzio <sscotto@cpan.org>') : ()),
);
