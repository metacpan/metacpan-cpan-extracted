#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use ExtUtils::MakeMaker;

my %args = (
    NAME                 =>  'Games::Wumpus',
    VERSION_FROM         =>  'lib/Games/Wumpus.pm',
    ABSTRACT_FROM        =>  'lib/Games/Wumpus.pm',
    PREREQ_PM            => {
        'strict'                =>  0,
        'warnings'              =>  0,
        'List::Util'            =>  0,
        'Hash::Util::FieldHash' =>  0,
        'Exporter'              =>  0,
    },
    MIN_PERL_VERSION     =>   5.010,
    AUTHOR               =>  'Abigail <cpan@abigail.be>',
    LICENSE              =>  'mit',
    META_MERGE           => {
        build_requires   => {
            'strict'         =>  0,
            'warnings'       =>  0,
            'Test::More'     =>  0.88,
        },
        resources        => {
            repository   =>  'git://github.com/Abigail/Games--Wumpus.git',
        },
        keywords         => [qw [ ]],
    },
    EXE_FILES            => [qw [bin/wumpus]],
);

$args {META_MERGE} {build_requires} ||= {
    'ExtUtils::MakeMaker' =>  0,
    %{$args {META_MERGE} {test_requires}}
};
 
$args {META_MERGE} {configure_requires} ||=
    $args {META_MERGE} {build_requires};


my %filter = (
    MIN_PERL_VERSION     => '6.48',
    LICENSE              => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
);

delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;

__END__
