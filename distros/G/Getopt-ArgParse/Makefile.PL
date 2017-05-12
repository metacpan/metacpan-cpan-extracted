use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    'ABSTRACT'       => 'Parsing args with a richer and more user-friendly API',
    'AUTHOR'         => 'Mytram <mytram2@gmail.com>',
    'BUILD_REQUIRES' => {},
    'DISTNAME'       => 'Getopt-ArgParse',
    'EXE_FILES'      => [],
    'LICENSE'        => 'artistic_2',
    'NAME'           => 'Getopt-ArgParse',
    MIN_PERL_VERSION => '5.008',
    'PREREQ_PM' => {
        'Moo'             => '1.003',
        'Getopt::Long'    => '2.38',
        'Test::Exception' => '0.31',
    },
    'VERSION_FROM' => 'lib/Getopt/ArgParse.pm',
    'test' => {
        'TESTS' => 't/*.t'
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/mytram/perl-argparse',
        },
   },
);

WriteMakefile(%WriteMakefileArgs);
