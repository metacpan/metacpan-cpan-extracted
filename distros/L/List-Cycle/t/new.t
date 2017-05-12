#!perl -T

use warnings;
use strict;

use Test::More tests => 3;

use List::Cycle;

my $cycle = List::Cycle->new( {vals=> [2112, 5150, 90125]} );
isa_ok( $cycle, 'List::Cycle' );

subtest 'Die on invalid constructor argument' => sub {
    plan tests => 2;

    my $rc = eval { List::Cycle->new( {flavors => [ qw(chocolate vanilla) ]} ); 1; };
    ok( !defined($rc), 'Constructor dies' );
    like($@, qr/not a valid constructor/, 'Error message is good' );
};

subtest 'Die on next() without values' => sub {
    my $empty = List::Cycle->new();
    isa_ok( $empty, 'List::Cycle' );
    my $rc = eval { $empty->next; 1; };
    ok( !defined($rc), 'Constructor dies' );
    like($@, qr/no cycle values/, 'Error message is good' );
};
