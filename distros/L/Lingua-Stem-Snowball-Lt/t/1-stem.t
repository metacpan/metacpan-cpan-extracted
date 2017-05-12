#!/usr/bin/perl

use strict;
use Test::More;
use Lingua::Stem::Snowball::Lt qw(:all);

plan tests => 3;

is( 'Lingua::Stem::Snowball::Lt', ref Lingua::Stem::Snowball::Lt->new( ), "construct stemmer" );

my $stemmer;

$stemmer = Lingua::Stem::Snowball::Lt->new( );
is( 'Lingua::Stem::Snowball::Lt', ref($stemmer), "constuct a stemmer" );

$stemmer = Lingua::Stem::Snowball::Lt->new();
is( 'Lingua::Stem::Snowball::Lt', ref($stemmer),
    "Construct stemmer with no args" );
