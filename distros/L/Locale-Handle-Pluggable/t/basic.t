#!/usr/bin/perl

use strict;
use warnings;

use utf8;

use Test::More 'no_plan';

{
    package Foo;
    use Moose;

    #extends qw(Locale::Maketext);
    #with qw(Locale::Handle::Pluggable::DateTime Locale::Handle::Pluggable);

    extends qw(
        Locale::Maketext
        Locale::Handle::Pluggable::DateTime
        Locale::Handle::Pluggable
    );

    package Foo::en;
    use Moose;

    extends qw(Foo);

    our %Lexicon = (
        foo => "english",
    );

    package Foo::de;
    use Moose;

    extends qw(Foo);

    our %Lexicon = (
        foo => "deustsch",
    );

    package Foo::he;
    use Moose;
    
    extends qw(Foo);

    our %Lexicon = (
        foo => "ivrit",
    );
}


my $l = Foo->new;

my $en = $l->get_handle("en");
my $de = $l->get_handle("de");
my $he = $l->get_handle("he");

is( $en->loc_string("foo"), "english", "english handle" );
is( $de->loc_string("foo"), "deustsch", "german handle" );
is( $he->loc_string("foo"), "ivrit", "hebrew handle" );

is( $_->loc("foo"), $_->loc_string("foo"), "loc Str delegates to loc_str" ) for $en, $de, $he;

my $date = DateTime->now;

$en->time_zone( DateTime::TimeZone->new( name => "America/New_York" ) );
$de->time_zone( DateTime::TimeZone->new( name => "Europe/Vienna" ) );
$he->time_zone( DateTime::TimeZone->new( name => "Asia/Jerusalem" ) );

like( $en->loc_datetime($date, "full_date"), qr/day/, "good day!" );
like( $de->loc_datetime($date, "full_date"), qr/tag/, "gutten tag!" );
like( $he->loc_datetime($date, "full_date"), qr/יום/, "yom tov!" );

is( $de->loc($date, "short_date"), $de->loc_datetime($date, "short_date"), "loc DateTime" ) for $en, $de, $he;

