#!/usr/bin/perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Map::Tube::RheinRuhr;
use Test::More;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing MYMETA.yml" if $@;

my $meta    = meta_spec_ok('MYMETA.yml');
my $version = $Map::Tube::RheinRuhr::VERSION;

is( $meta->{version}, $version, 'MYMETA.yml distribution version matches' );

if ( $meta->{provides} ) {
  for my $mod ( keys %{ $meta->{provides} } ) {
    is( $meta->{provides}{$mod}{version}, $version, "MYMETA.yml entry [$mod] version matches" );
  }
}

done_testing( );
