#!/bin/env perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Memoize::Expire::ByInstance',
    AUTHOR              => q{Jamie Beverly <jbeverly@cpan.org>},
    VERSION_FROM        => 'lib/Memoize/Expire/ByInstance.pm',
    ABSTRACT_FROM       => 'lib/Memoize/Expire/ByInstance.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Class' => 0.30,
        'Scalar::Util' => 1.1,
        'Time::HiRes'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Memoize-Expire-ByInstance-*' },
);
