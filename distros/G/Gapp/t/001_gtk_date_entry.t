#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 70;

use Gtk2 '-init';
use_ok( 'Gapp::Gtk2::DateEntry' );


my $entry =  Gapp::Gtk2::DateEntry->new( value => '08-11-1986' );
is $entry->get_value->ymd, '1986-08-11', 'set value';


$entry = Gapp::Gtk2::DateEntry->new;
ok( defined $entry, qq[widget created] );

my @test_dates = (
    [qw[08-11-1986 1986-08-11 08/11/1986]],
    [qw[08.11.1986 1986-08-11 08/11/1986]],
    [qw[08/11/1986 1986-08-11 08/11/1986]],
    [qw[08111986   1986-08-11 08/11/1986]],
    [qw[081186     1986-08-11 08/11/1986]],

);

for( @test_dates ) {
    no warnings;
    
    # test the parsing of input
    $entry = Gapp::Gtk2::DateEntry->new;

    # test the setting of the value
    $entry = Gapp::Gtk2::DateEntry->new;
    $entry->set_value($_->[0]);
    is ($entry->get_value->ymd, $_->[1], qq[set value: $_->[0]]  );
    is ($entry->get_text , $_->[2], qq[test output: $_->[1]]);
}



# selecting component

my @select_tests = (
    [qw/month   month  /],
    [qw/day     day /],
    [qw/year    year/],
    [none => undef],
    [''   => undef],
);


$entry = Gapp::Gtk2::DateEntry->new;
$entry->set_value('01/01/2001');
for (@select_tests) {
    my ($component, $expect) = @$_;
    $entry->set_selected_component($component);
    is ( $entry->get_selected_component, $expect, qq[select component: $component] );
}


my @movement_tests = (
    [qw/month   right  day  /],
    [qw/day     left   month/],
    [qw/day     right  year /],
    [qw/year    left   day  /],
    [qw/all     left   year /],
    [qw/all     right  month/],
);

for (@movement_tests) {
    my ($position, $direction, $expect)  = @$_;
    my $method = "_do_key_$direction";
    $entry->set_selected_component($position);
    $entry->$method;
    is ($entry->get_selected_component, $expect, qq[key $direction from position $position]);
}

my @position_tests = (
    [qw/0 left  /, undef],
    [qw/0 right month/],
    [qw/0 up    month/],
    [qw/0 down  month/],
    [qw/1 left  month/],
    [qw/1 right month/],
    [qw/1 up    month/],
    [qw/1 down  month/],
    [qw/2 left  month/],
    [qw/2 right day/],
    [qw/2 up    month/],
    [qw/2 down  month/],
    [qw/3 left  month/],
    [qw/3 right day/],
    [qw/3 down  day/],
    [qw/3 up    day/],
    [qw/4 left  day/],
    [qw/4 right day/],
    [qw/4 up    day/],
    [qw/4 down  day/],
    [qw/5 left  day/],
    [qw/5 right year/],
    [qw/5 up    day/],
    [qw/5 down  day/],
    [qw/6 left  day/],
    [qw/6 right year/],
    [qw/6 up    year/],
    [qw/6 down  year/],
    [qw/7 left  year/],
    [qw/7 right year/],
    [qw/7 up    year/],
    [qw/7 down  year/],
    [qw/8 left  year/],
    [qw/8 right year/],
    [qw/8 up    year/],
    [qw/9 down  year/],
);


$entry = Gapp::Gtk2::DateEntry->new;
$entry->set_value('1986-08-11');
for (@position_tests ) {
    my ($position, $direction, $expect)  = @$_;
    my $method = "_do_key_$direction";
    $entry->set_selected_component('none');
    $entry->set_position($position);
    $entry->$method;
    is ($entry->get_selected_component, $expect, qq[key $direction from position $position]);
}

# value up down tests

my @change_tests = (
  [qw/2001-01-01 month    up   2001-02-01/],
  [qw/2001-02-01 month    down 2001-01-01/],
  [qw/2001-12-01 month    up   2002-01-01/],
  [qw/2001-01-01 month    down 2000-12-01/],
  [qw/2001-01-01 day      up   2001-01-02/],
  [qw/2001-01-31 day      up   2001-02-01/],
  [qw/2001-12-31 day      up   2002-01-01/],
  [qw/2001-01-02 day      down 2001-01-01/],
  [qw/2001-02-01 day      down 2001-01-31/],
  [qw/2001-01-01 day      down 2000-12-31/],

);

for (@change_tests ) {
    my ($date, $component, $direction, $expect)  = @$_;
    my $method = "_do_key_$direction";
    $entry->set_value($date);
    $entry->set_selected_component($component);
    $entry->$method;
    is ($entry->get_value->ymd, $expect, qq[key $direction on component $component]);
}


