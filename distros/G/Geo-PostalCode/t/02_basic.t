#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN { 
        if ($ENV{skiptests}) { 
          plan skip_all => "$ENV{skiptests}"
	} else {
	  plan tests => 16
	}
	use_ok('Geo::PostalCode');
      };

use constant DIR => 'basictest';

## Build the data file

my $gp = Geo::PostalCode->new(db_dir => 'blib/tests/'.DIR);

my $r = $gp->lookup_postal_code(postal_code => '07302');

is($r->{state}, 'NJ');
is($r->{lat}, '+40.726001');
is($r->{city}, 'JERSEY CITY');
is($r->{lon}, '-74.047304');

is(substr($gp->calculate_distance(postal_codes => ['08540','08544']), 0, 4), '2.19');

my @postal_codes = sort @{$gp->nearby_postal_codes(lat => $r->{lat}, lon => $r->{lon}, distance => 2)};

my @expected = qw(07030 07096 07097 07099 07302 07304 07306 07307 07310 07311 07399 10281 10282 10285);

is_deeply(\@expected, \@postal_codes);

@postal_codes = sort @{$gp->nearby_postal_codes(lat => $r->{lat}, lon => $r->{lon}, distance => 25)};

is(@postal_codes, 672);

my $postal_codes = $gp->query_postal_codes(lat => $r->{lat}, lon => $r->{lon}, distance => 2, select => ['distance','city','state','lat','lon'], order_by => 'distance');

my @states = map { $_->{state} } @$postal_codes;

@expected = qw(NJ NJ NJ NJ NJ NJ NJ NJ NJ NJ NJ NY NY NY);

is_deeply(\@states, \@expected);

$r = $gp->lookup_city_state(city => 'Jersey City', state => 'NJ');

is_deeply($r->{postal_codes}, [qw(07097 07302 07304 07305 07306 07307 07310 07311 07399)]);
is($r->{lat}, '40.72819');
is($r->{lon}, '-74.06449');

$r = $gp->lookup_city_state(city => 'New York', state => 'NY');

$postal_codes = $gp->query_postal_codes(lat => $r->{lat}, lon => $r->{lon}, distance => 26,
	select => ['distance','lat','lon'], order_by => 'distance');

my @a = map { $_->{postal_code} } grep { int($_->{distance}) == 25 } @$postal_codes;
my @b = map { $_->{postal_code} } grep { int($_->{distance}) > 26 } @$postal_codes;

is (@b, 0);

$postal_codes = $gp->query_postal_codes(lat => $r->{lat}, lon => $r->{lon}, distance => 60,
	select => ['distance','lat','lon'], order_by => 'distance');

my @c = map { $_->{postal_code} } grep { int($_->{distance}) == 25 } @$postal_codes;
@b = map { $_->{postal_code} } grep { int($_->{distance}) > 60 } @$postal_codes;

is_deeply(\@a,\@c);
is (@b, 0);

$r = $gp->lookup_city_state(city => 'Flushing', state => 'NY');

$postal_codes = $gp->query_postal_codes(lat => $r->{lat}, lon => $r->{lon}, distance => 60,
	select => ['distance','lat','lon'], order_by => 'distance');
@b = grep { int($_->{distance}) > 60 } @$postal_codes;
is (@b, 0);

