######################################################################
# Makefile.PL for Getopt::Fancy
# 2006, Robert Powers <batman@cpan.org>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Getopt::Fancy',
    'VERSION_FROM' => 'lib/Getopt/Fancy.pm', # finds $VERSION
    'PREREQ_PM'    => {
      Getopt::Long   => 0,
      Test::More     => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Getopt/Fancy.pm',
       AUTHOR     => 'Robert Powers <batman@cpan.org>') : ()),
);
