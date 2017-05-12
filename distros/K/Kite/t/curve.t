#!/usr/bin/perl -w

use strict;
use lib qw( ./lib ../lib);
use Kite::XML::Node::Kite;

print "1..21\n";
my $n = 0;

sub ok {
    shift or print "not ";
    print "ok ", ++$n, "\n";
}

my $c1 = Kite::XML::Node::Curve->new();
die "1: $Kite::XML::Node::Curve::ERROR\n" unless $c1;
ok( $c1 );

my $pt = $c1->point(x => 50, y => 100);
die "2: ", $c1->error(), "\n" unless $pt;
ok( $pt );
ok( $pt->x() == 50 );
ok( $pt->y() == 100 );

$pt = $c1->element('point', x => 150, y => 200);
die "3: ", $c1->error(), "\n" unless $pt;
ok( $pt );
ok( $pt->x() == 150 );
ok( $pt->y() == 200 );

$pt = $c1->child('point', x => 50);
ok( ! $pt );
ok( $c1->error() eq 'y not defined' );

my $pts = $c1->point();
ok( $pts );
ok( ref $pts eq 'ARRAY' );
ok( scalar @$pts == 2 );
ok( $pts->[0]->x() == 50 );
ok( $pts->[0]->y() == 100 );
ok( $pts->[1]->x() == 150 );
ok( $pts->[1]->y() == 200 );

my $text = $c1->text({ size => 24 });
die "4: ", $c1->error(), "\n" unless $text;
ok( $text );
ok( $text->char('The Content') );
ok( $text->char() eq 'The Content' );

$text = $c1->child('text', { size => 12 });
die "5: ", $c1->error(), "\n" unless $text;
ok( $text );
ok( $text->char("New content\n") );

#print $text->_dump();

#print $c1->_dump(), "\n";


