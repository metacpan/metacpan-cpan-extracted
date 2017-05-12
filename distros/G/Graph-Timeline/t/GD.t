#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 104;

use_ok('Graph::Timeline::GD');

################################################################################
# Create a new object
################################################################################

eval { Graph::Timeline::GD->new(1); };
like( $@, qr/^Timeline->new\(\) takes no arguments /, 'Too many arguments' );

my $x = Graph::Timeline::GD->new();

isa_ok( $x, 'Graph::Timeline::GD' );

################################################################################
# Add some events
################################################################################

eval { $x->add_interval(1); };
like( $@, qr/^Timeline->add_interval\(\) expected HASH as parameter/, 'Too many arguments' );

eval { $x->add_interval( start => '1950/01/01', end => '1955/01/01' ); };
like( $@, qr/^Timeline->add_interval\(\) missing key 'label'/, 'Missing argument' );

eval { $x->add_interval( label => '1', end => '1955/01/01' ); };
like( $@, qr/^Timeline->add_interval\(\) missing key 'start'/, 'Missing argument' );

eval { $x->add_interval( label => '1', start => '1950/01/01' ); };
like( $@, qr/^Timeline->add_interval\(\) missing key 'end'/, 'Missing argument' );

eval { $x->add_interval( banana => 1, label => '1', start => '1950/01/01', end => '1955/01/01' ); };
like( $@, qr/^Timeline->add_interval\(\) invalid key 'banana' passed as data/, 'Missing argument' );

eval { $x->add_interval( label => '1', start => '1950/01/01', end => 'wrong' ); };
like( $@, qr/^Timeline->add_interval\(\) invalid date for 'end'/, 'Missing argument' );

eval { $x->add_interval( label => '1', start => 'wrong', end => '1955/01/01' ); };
like( $@, qr/^Timeline->add_interval\(\) invalid date for 'start'/, 'Missing argument' );

eval { $x->add_interval( label => '1', start => '1950/01/01', end => '1955/01/01' ); };
is( $@, '', 'That one worked' );

eval { $x->add_interval( label => '6', start => '1972/01/01', end => '1980/01/01' ); };
is( $@, '', 'That one worked' );

eval { $x->add_interval( label => '2', start => '1950/01/01', end => '1965/01/01' ); };
is( $@, '', 'That one worked' );

eval { $x->add_interval( label => '4', start => '1965/01/01', end => '1969/01/01' ); };
is( $@, '', 'That one worked' );

eval { $x->add_interval( label => '5', start => '1965/01/01', end => '1972/01/01' ); };
is( $@, '', 'That one worked' );

eval { $x->add_interval( label => '3', start => '1950/01/01', end => '1972/01/01' ); };
is( $@, '', 'That one worked' );

################################################################################
# Get the data
################################################################################

eval { $x->data(1); };
like( $@, qr/^Timeline->data\(\) takes no arguments /, 'Too many arguments' );

my @l = $x->data();

is( scalar(@l), 6, 'Correct length' );

foreach my $y (qw/1 2 3 4 5 6/) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

################################################################################
# Set a window
################################################################################

eval { $x->window( wrong => 1, start => '1961/01/01', end => '1971/01/01', start_in => 1, end_in => 1, span => 1, callback => \&filter ); };
like( $@, qr/^Timeline->window\(\) invalid key 'wrong' passed as data/, 'Incorrect argument' );

eval { $x->window( start => 'wrong', end => '1971/01/01', start_in => 1, end_in => 1, span => 1, callback => \&filter ); };
like( $@, qr/^Timeline->window\(\) invalid date for 'start'/, 'Incorrect argument' );

eval { $x->window( start => '1961/01/01', end => 'wrong', start_in => 1, end_in => 1, span => 1, callback => \&filter ); };
like( $@, qr/^Timeline->window\(\) invalid date for 'end'/, 'Incorrect argument' );

eval { $x->window( start => '1961/01/01', end => '1971/01/01', start_in => 1, end_in => 1, span => 1, callback => 'wrong' ); };
like( $@, qr/^Timeline->window\(\) 'callback' can only be a CODE reference/, 'Incorrect argument' );

eval { $x->window( end => '1971/01/01', span => 1 ); };
like( $@, qr/^Timeline->window\(\) 'span' can only be defined with a 'start' and 'end'/, 'Incorrect argument' );

eval { $x->window( start => '1961/01/01', span => 1 ); };
like( $@, qr/^Timeline->window\(\) 'span' can only be defined with a 'start' and 'end'/, 'Incorrect argument' );

$x->window( start => '1961/01/01', end => '1971/01/01' );

@l = $x->data();

is( scalar(@l), 3, 'Correct length' );

foreach my $y ((undef, undef, 4)) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

$x->window( start => '1961/01/01', end => '1971/01/01', start_in => 1 );

@l = $x->data();

is( scalar(@l), 4, 'Correct length' );

foreach my $y ((undef, undef, 4, 5)) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

$x->window( start => '1961/01/01', end => '1971/01/01', end_in => 1 );

@l = $x->data();

is( scalar(@l), 5, 'Correct length' );

foreach my $y ((undef, undef, 2, 4, 5)) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

$x->window( start => '1961/01/01', end => '1971/01/01', start_in => 1, end_in => 1 );

@l = $x->data();

is( scalar(@l), 5, 'Correct length' );

foreach my $y ((undef, undef, 2, 4, 5)) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

$x->window( start => '1961/01/01', end => '1971/01/01', start_in => 1, end_in => 1, span => 1 );

@l = $x->data();

is( scalar(@l), 6, 'Correct length' );

foreach my $y ((undef, undef, 2, 3, 4, 5)) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

$x->window( start => '1961/01/01' );

@l = $x->data();

is( scalar(@l), 6, 'Correct length' );

foreach my $y ((undef, 2, 3, 4, 5, 6)) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

$x->window( start => '1961/01/01', end_in => 1 );

@l = $x->data();

is( scalar(@l), 6, 'Correct length' );

foreach my $y ((undef, 2, 3, 4, 5, 6)) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

$x->window( end => '1971/01/01' );

@l = $x->data();

is( scalar(@l), 6, 'Correct length' );

foreach my $y ((undef, 1, 2, 3, 4, 5)) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

$x->window( end => '1971/01/01', start_in => 1 );

@l = $x->data();

is( scalar(@l), 6, 'Correct length' );

foreach my $y ((undef, 1, 2, 3, 4, 5)) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

$x->window( callback => \&filter );

@l = $x->data();

is( scalar(@l), 3, 'Correct length' );

foreach my $y (qw/1 3 5/) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

################################################################################
# Add a point event
################################################################################

eval { $x->add_point(1); };
like( $@, qr/^Timeline->add_point\(\) expected HASH as parameter/, 'Too many arguments' );

eval { $x->add_point( start => '1961/01/01' ); };
like( $@, qr/^Timeline->add_point\(\) missing key 'label'/, 'Missing argument' );

eval { $x->add_point( label => '1' ); };
like( $@, qr/^Timeline->add_point\(\) missing key 'start'/, 'Missing argument' );

eval { $x->add_point( banana => 1, label => '1', start => '1961/01/01' ); };
like( $@, qr/^Timeline->add_point\(\) invalid key 'banana' passed as data/, 'Missing argument' );

eval { $x->add_point( label => '1', start => 'wrong' ); };
like( $@, qr/^Timeline->add_point\(\) invalid date for 'start'/, 'Missing argument' );

eval { $x->add_point( label => '7', start => '1961/01/01' ); };
is( $@, '', 'That one worked' );

$x->window();

@l = $x->data();

is( scalar(@l), 7, 'Correct length' );

foreach my $y (qw/1 2 3 7 4 5 6/) {
    my $z = shift @l;
    is( $z->{label}, $y, 'Correct order' );
}

################################################################################
# A support function
################################################################################

sub filter {
    my ($data) = @_;

    return ( $data->{label} % 2 ) == 1;
}

# vim: syntax=perl:
