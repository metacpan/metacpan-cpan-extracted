use 5.008;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'LaTeX::Table',
    AUTHOR              => '<limaone@cpan.org>',
    VERSION_FROM        => 'lib/LaTeX/Table.pm',
    ABSTRACT_FROM       => 'lib/LaTeX/Table.pm',
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
            ('LICENSE'  => 'perl')         : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'Test::NoWarnings' => 0,
        'File::Spec'       => 0,
        'English'        => 0,
        'Moose'     => 0.76,
        'MooseX::FollowPBP'    => 0.03,
        'Module::Pluggable'    => 0,
        'Carp'           => 0,
        'Scalar::Util'   => 0,
        'version'        => 0,
        'Template'       => 0,
        'Text::CSV'      => 0,
        'Cwd'            => 0,
    },
    (   ( ExtUtils::MakeMaker->VERSION() gt '6.46' )
        ? ( META_MERGE => {
                resources => {
                    repository => 'http://github.com/lima1/p5-latex-table',
                },
            }
            )
        : ()
    ),
    EXE_FILES         => [ 'bin/csv2pdf', 'bin/ltpretty' ], 
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LaTeX-Table-*' },
);
