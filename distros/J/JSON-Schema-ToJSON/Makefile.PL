#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'JSON::Schema::ToJSON',
    VERSION_FROM     => 'lib/JSON/Schema/ToJSON.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM => {
        'Cpanel::JSON::XS' => 3.0213,
        'JSON::Validator'  => 0.96,
        'String::Random'   => 0.29,
        'Mojolicious'      => '7.15',
        'DateTime'         => 0,
        'Hash::Merge'      => 0,
    },
    TEST_REQUIRES => {
        'Test::Most'       => 0.31,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/JSON::Schame::ToJSON',
            bugtracker => 'https://github.com/Humanstate/json-schema-tojson/issues',
            repository => 'https://github.com/Humanstate/json-schema-tojson'
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
