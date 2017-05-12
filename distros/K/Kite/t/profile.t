#!/usr/bin/perl -w

use strict;
use lib qw( ./lib ../lib);
use Kite;

print "1..20\n";
my $n = 0;

sub ok {
    shift or print "not ";
    print "ok ", ++$n, "\n";
}

my $p0 = Kite->profile({
    NAME => 'Foo Bar',
});

ok( ! $p0 );
ok( $Kite::ERROR eq 'profile X values not specified' );

$p0 = Kite->profile( name => 'Foo Bar', x => [], y => [] );
ok( $p0 );
ok( $p0->name eq 'Foo Bar' );

my $p1 = Kite::Profile->new({
    NAME => 'My Test Profile',
    X    => [ 2, 3, 11, 5, 7 ],
    Y    => [ 4, 6, 22, 10, 14 ]
});

ok( $p1 );
ok( $p1->name() eq 'My Test Profile' );
ok( $p1->n_nodes() == 5 );
ok( $p1->min_x() == 2 );
ok( $p1->max_x() == 11 );
ok( $p1->min_y() == 4 );
ok( $p1->max_y() == 22 );
ok( $p1->length() == 9 );
ok( $p1->height() == 18 );

$p1->translate_x(5);
ok( $p1->max_x == 16 );
ok( $p1->min_x == 7 );
ok( $p1->length() == 9 );

$p1->scale_y(4);
ok( $p1->min_y == 16 );
ok( $p1->max_y == 88 );
ok( $p1->height() == 72 );

$p1->close();

ok( $p1->n_nodes() == 6 );
