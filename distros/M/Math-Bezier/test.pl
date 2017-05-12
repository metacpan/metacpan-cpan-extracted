#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use vars qw( $loaded );
use lib  qw( blib/lib );

my $DEBUG = 0;

print "1..27\n";
my $n = 0;

sub ok {
    shift or print "not ";
    print "ok ", ++$n, "\n";
}

use Math::Bezier;

ok( 1 );

my $control = [ 0, 0, 10, 20, 30, -20, 40, 0 ];
my $bezier1 = Math::Bezier->new(@$control);
ok( $bezier1 );

foreach my $k (0 .. 10) {
    my @pt = $bezier1->point($k / 10);
    ok( scalar @pt == 2 );
    print STDERR "point: @pt\n" if $DEBUG;
}

my @pts1 = $bezier1->curve(20);
ok( scalar @pts1 == 40 );


my $bezier2 = Math::Bezier->new($control);
ok( $bezier2 );

foreach my $k (0 .. 10) {
    my $pt = $bezier2->point($k / 10);
    ok( scalar @$pt == 2 );
    print STDERR "point: @$pt\n" if $DEBUG;
}

my $pts2 = $bezier2->curve();
ok( scalar @$pts2 == 40 );

