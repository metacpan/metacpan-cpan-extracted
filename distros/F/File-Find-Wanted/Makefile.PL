#!/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %parms = (
    NAME                => 'File::Find::Wanted',
    AUTHOR              => 'Andy Lester <andy@petdance.com>',
    VERSION_FROM        => 'Wanted.pm',
    ABSTRACT_FROM       => 'Wanted.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Find-Wanted-*' },
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
    $parms{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $parms{META_MERGE} = {
        resources => {
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Find-Wanted',
            license     => 'http://www.opensource.org/licenses/artistic-license-2.0.php',
        }
    };
}

WriteMakefile( %parms );
