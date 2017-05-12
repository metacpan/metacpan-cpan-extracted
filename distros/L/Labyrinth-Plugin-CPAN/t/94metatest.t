#!/usr/bin/perl -w
use strict;

use Test::More;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

eval "use Test::CPAN::Meta 0.19";
plan skip_all => "Test::CPAN::Meta 0.19 required for testing META.yml" if $@;

plan 'no_plan';

my $meta = meta_spec_ok(undef,undef,@_);

use Labyrinth::Plugin::CPAN;
my $version = $Labyrinth::Plugin::CPAN::VERSION;

is($meta->{version},$version,
    'META.yml distribution version matches');

if($meta->{provides}) {
    for my $mod (keys %{$meta->{provides}}) {
        is($meta->{provides}{$mod}{version},$version,
            "META.yml entry [$mod] version matches distribution version");

        eval "require $mod";
        my $VERSION = '$' . $mod . '::VERSION';
        my $v = eval "$VERSION";
        is($meta->{provides}{$mod}{version},$v,
            "META.yml entry [$mod] version matches module version");

        isnt($meta->{provides}{$mod}{version},0);
    }
}
