# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 19_freeze_thaw.t,v 1.9 2004/03/25 14:56:37 jettero Exp $

use strict;
use Test;
use Games::Go::SGF2misc; 

{ # notice that everything below this line is scoped inside this

my $sgf = new Games::Go::SGF2misc;
   $sgf->parse("sgf/redrose-tartrate.sgf");
   # $sgf->parse("sgf/9x9-gnugo.sgf");

my @nodes = @{ $sgf->nodelist->{1}[0] };

die "um, crazy" unless @nodes > 10;
plan tests => int @nodes + 1;

my @before = ();
my @after  = ();

my $freezer = freeze $sgf;

my $fsg = new Games::Go::SGF2misc;
   $fsg->thaw( $freezer ) or die "failed to thaw(): " . $fsg->errstr;

my $s = 2;
for my $n (@nodes) {
    my $a = $sgf->as_text($n) or die "failed to as_text($n): " . $sgf->errstr;
    my $b = $fsg->as_text($n) or die "failed to as_text($n): " . $fsg->errstr;

    if( $a eq $b ) {
        ok(1);
    } else {
        ok(0);
    }
}

kill -11, $$
} ok(1); # $sgf/$fsg have gone out of scope... which was causing sagfaults...
