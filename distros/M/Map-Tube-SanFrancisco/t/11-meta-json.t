#!/usr/bin/perl
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Map::Tube::SanFrancisco;
use Test::More;
plan skip_all => 'these tests are for authors only!' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );

eval "use Test::CPAN::Meta::JSON";
plan skip_all => "Test::CPAN::Meta::JSON required for testing MYMETA.json" if $@;

my $meta    = meta_spec_ok('MYMETA.json');
my $version = $Map::Tube::SanFrancisco::VERSION;

is( $meta->{version}, $version, 'MYMETA.json distribution version matches' );

if ( $meta->{provides} ) {
  for my $mod ( keys %{ $meta->{provides} } ) {
    is( $meta->{provides}{$mod}{version}, $version, "MYMETA.json entry [$mod] version matches" );
  }
}

done_testing( );
