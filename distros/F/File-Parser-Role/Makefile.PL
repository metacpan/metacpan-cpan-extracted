use strict;
use warnings;
use ExtUtils::MakeMaker;
use utf8;

WriteMakefile(
    NAME                => 'File::Parser::Role',
    AUTHOR              => 'Torbjørn Lindahl <torbjorn.lindahl@gmail.com>',
    VERSION_FROM        => 'lib/File/Parser/Role.pm',
    ABSTRACT_FROM       => 'lib/File/Parser/Role.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Moo'                  => '1.006001',
        'Moo::Role'            => '1.006001',
        'IO::String'           => '1.08',
        'Pod::Coverage::Moose' => '0.02',
        'Test::Most'           => '0.34',
        'Test::Perl::Critic'   => '1.02',
        'Test::Pod'            => '1.48',
        'Test::Pod::Coverage'  => '1.08',
        'Test::Output'         => '1.02',
        'Test::Warnings'       => '0.010',
        'MooX::Aliases'        => '0.001',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Parser-Role-*' },
);
