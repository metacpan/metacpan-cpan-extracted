#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 23;


use Gtk2 '-init';
use_ok( 'GappX::Gtk2::SSNEntry' );



my $entry = GappX::Gtk2::SSNEntry->new;
ok( defined $entry, qq[widget created] );


my @tests = (
    ['123 45 6789', '123456789', '123-45-6789'],
    ['123-45-6789', '123456789', '123-45-6789'],
    ['123 45 6789', '123456789', '123-45-6789'],
);


for( @tests) {
    no warnings;
    
    # test the parsing of input
    $entry = GappX::Gtk2::SSNEntry->new(value => $_->[0]);    
    is ($entry->get_value, $_->[1], qq[set value: $_->[0]]  );
    is ($entry->get_text , $_->[2], qq[test output: $_->[1]]);
}
#

# selecting component
my @select_tests = (
    [0, 0],
    [1, 1],
    [2, 2],
    [none => undef],
    [''   => undef],
);

$entry = GappX::Gtk2::SSNEntry->new(value => '123456789');
for (@select_tests) {
    my ($component, $expect) = @$_;
    $entry->set_selected_component($component);
    is ( $entry->get_selected_component, $expect, qq[select component: $component] );
}

my @movement_tests = (
    [qw/0   right  1/],
    [qw/1   left   0/],
    [qw/1   right  2/],
    [qw/2   left   1/],
    [qw/all left   2/],
    [qw/all right  0/],
);

for (@movement_tests) {
    my ($position, $direction, $expect)  = @$_;
    my $method = "_do_key_$direction";
    $entry->set_selected_component($position);
    $entry->$method;
    is ($entry->get_selected_component, $expect, qq[key $direction from position $position]);
}

my @position_tests = (
    [qw/3 right 1/],
    [qw/4 left  0/],
    [qw/6 right 2/],
    [qw/7 left  1/]
);


for (@position_tests ) {
    my ($position, $direction, $expect)  = @$_;
    my $method = "_do_key_$direction";
    $entry->set_selected_component('none');
    $entry->set_position($position);
    $entry->$method;
    is ($entry->get_selected_component, $expect, qq[key $direction from position $position]);
}


