use strict;
use warnings;

use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);

WriteMakefile(
    NAME         => 'Getopt::Module',
    VERSION_FROM => 'lib/Getopt/Module.pm',
    PREREQ_PM    => {
        'Carp'         => 0,
        'constant'     => 0,
        'Data::Dumper' => 0,
        'Exporter'     => 0,
        'Scalar::Util' => 0,
    },
    ABSTRACT_FROM => 'lib/Getopt/Module.pm',
    AUTHOR        => 'chocolateboy <chocolate@cpan.org>',
    ($EUMM_VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
    ($EUMM_VERSION >= 6.46 ?
        (
            META_MERGE => {
                test_requires => {
                    'Test::More' => 0,
                },
                resources => {
                    repository => 'http://github.com/chocolateboy/Getopt-Module',
                    bugtracker => 'http://github.com/chocolateboy/Getopt-Module/issues',
                },
            }
        )
        : ()
    ),
);
