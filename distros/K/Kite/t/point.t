#!/usr/bin/perl -w

use strict;
use lib qw( ./lib ../lib);
use Kite::XML::Node::Kite;

print "1..9\n";
my $n = 0;

sub ok {
    shift or print "not ";
    print "ok ", ++$n, "\n";
}

my $pt = Kite::XML::Node::Point->new(x => 50, y => 70);
die "1: $Kite::XML::Node::Point::ERROR\n" unless $pt;
ok( $pt );
ok( $pt->x() == 50 );
ok( $pt->y() == 70 );

#print $pt->_dump();

$pt = Kite::XML::Node::Point->new(x => 50);
ok( ! $pt );
ok(  Kite::XML::Node::Point->error() eq 'y not defined' );
ok( $Kite::XML::Node::Point::ERROR   eq 'y not defined' );

$pt = Kite::XML::Node::Point->new(x => 100, y => 200, bad => 'text');
ok( ! $pt );
ok(  Kite::XML::Node::Point->error() eq "invalid attribute 'bad'" );
ok( $Kite::XML::Node::Point::ERROR   eq "invalid attribute 'bad'" );
