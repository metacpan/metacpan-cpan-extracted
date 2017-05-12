#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

use ExtUtils::MakeMaker;

my %args = (
    NAME                 => 'Lexical::Attributes',
    VERSION_FROM         => 'lib/Lexical/Attributes.pm',
    ABSTRACT_FROM        => 'lib/Lexical/Attributes.pm',
    PREREQ_PM            => {
        'Filter::Simple'     => 0.78,
        'Scalar::Util'       => 0,
        'warnings'           => 0,
        'strict'             => 0,
    },
    MIN_PERL_VERSION     =>  5.008001,
    AUTHOR               => 'Abigail <lexical-attributes@abigail.be>',
    LICENSE              => 'mit',
    META_MERGE           => {
        test_requires    => {
            'Test::More' => 0.88,
            'warnings'   => 0,
            'strict'     => 0,
        },
        resources        => {
            repository   => 'git://github.com/Abigail/lexical--attributes.git',
        },
        keywords         => [qw [Objects Encapsulation Attributes Strict]],
    },
);

$args {META_MERGE} {build_requires} ||= {
    'ExtUtils::MakeMaker' =>  0,
    %{$args {META_MERGE} {test_requires}}
};
    
$args {META_MERGE} {configure_requires} ||=
    $args {META_MERGE} {build_requires};
    
my %filter = (
    MIN_PERL_VERSION     => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
    LICENSE              => '6.07',
);

delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;

__END__
