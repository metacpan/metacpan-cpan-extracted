#!perl -T
use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

plan tests => 1;
my $trustme = { trustme => [qr/^(new|reload|exec_file|get\w+)$/] };
pod_coverage_ok('Log::Dispatch::Configurator::Perl', $trustme);