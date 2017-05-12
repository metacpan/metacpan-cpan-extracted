#!perl

use Test::More;
plan skip_all => 'pkg/README tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::CPAN::README';
plan skip_all => 'Test::CPAN::README required for testing the pkg/README file' if $@;

readme_ok('File::Path::Tiny');    # this does the plan
