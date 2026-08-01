#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use Map::Tube::Plugin::Graph;
use Test::More;

plan skip_all => 'for authors only -- define $ENV{AUTHOR_TESTING}' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing MYMETA.yml" if $@;

my $meta    = meta_spec_ok('MYMETA.yml');
my $version = $Map::Tube::Plugin::Graph::VERSION;

is($meta->{version},$version, 'MYMETA.yml distribution version matches');

if ($meta->{provides}) {
    foreach my $mod (keys %{$meta->{provides}}) {
        eval("use $mod;");
        my $mod_version = eval(sprintf("\$%s::VERSION", $mod));
        is($meta->{provides}{$mod}{version}, $version, "MYMETA.yml entry [$mod] version matches");
        is($mod_version, $version, "Package $mod doesn't match version.");
    }
}

done_testing;
