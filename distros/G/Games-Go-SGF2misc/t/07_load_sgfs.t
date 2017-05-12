# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 07_load_sgfs.t,v 1.5 2004/03/22 16:05:27 jettero Exp $

use strict;
use Test;
use Games::Go::SGF2misc;

my $uup;
my @sgf = <sgf/*.sgf>;
   @sgf = ($ENV{THIS_ONE_PLZ}) if $ENV{THIS_ONE_PLZ};

plan tests => int @sgf;

my $sgf = new Games::Go::SGF2misc;
for my $f (@sgf) {
    my $r = $sgf->parse($f);

    if( $r ) {
        ok 1;

    } else {
        if( $f =~ m/error\.sgf/ ) {
            ok 1;

        } else {
            print STDERR $sgf->errstr, "\n";
            ok 0;
        }
    }
}
