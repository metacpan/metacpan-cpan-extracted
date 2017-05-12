#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use ExtUtils::MakeMaker;

my %args = (
    NAME                 => 'End',
    VERSION_FROM         => 'lib/End.pm',
    ABSTRACT_FROM        => 'lib/End.pm',
    PREREQ_PM            => {'strict'    => 0,  
                             'warnings'  => 0,  
                             'Exporter'  => 0,
                            }, 
    MIN_PERL_VERSION     =>  5.006,
    AUTHOR               => 'Abigail <cpan@abigail.be>',
    LICENSE              => 'mit',
    META_MERGE           => {
        build_requires   => { },
        test_requires    => { },
        resources        => {
            repository   =>
                           'git://github.com/Abigail/end.git',
        },
        keywords         => [qw [ ]],
    },
);

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
