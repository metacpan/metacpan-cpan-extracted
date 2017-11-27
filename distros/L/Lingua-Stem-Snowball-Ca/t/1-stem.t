#!/usr/bin/perl

use strict;
use Test::More;
use Lingua::Stem::Snowball::Ca qw(:all);

plan tests => 3;

is( 'Lingua::Stem::Snowball::Ca', ref Lingua::Stem::Snowball::Ca->new( ), "construct stemmer" );

my $stemmer;

$stemmer = Lingua::Stem::Snowball::Ca->new( );
is( 'Lingua::Stem::Snowball::Ca', ref($stemmer), "constuct a stemmer" );

$stemmer = Lingua::Stem::Snowball::Ca->new();
is( 'Lingua::Stem::Snowball::Ca', ref($stemmer),
    "Construct stemmer with no args" );
