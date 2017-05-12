# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 09_memory_test.t,v 1.3 2004/03/24 14:23:58 jettero Exp $

use strict;
use Test;
use Games::Go::SGF2misc;

my $uup = !(eval "use Unix::Process; 1");
my $tests = 50;

plan tests => $tests;

if( $uup or $ENV{SKIP_MEM} ) {
    warn( $uup ? " skipping tests: $@" : " skipping tests by request");
    skip( 1 ) for 1 .. $tests;
    exit 0; # heh
}

my $freebies = 132;  # On my system, the pid grows by 132 bytes for every call of parse().
   $freebies *=  2;  # If you can tell me why, I'll be glad to hear it, because I have
                     # pretty carefully made sure I'm not leaving any circular refs around...
                     # Personally, I think it's a perl internal thing that I can't help.
                     # -jet

my $file      = "sgf/crazy.sgf";
my $sgf       = new Games::Go::SGF2misc;
my $size      = undef;
my $last_size = undef;

for my $i (1 .. $tests+1) {
    my $r = $sgf->parse($file);

    $size = Unix::Process->vsz;

    if( defined $last_size ) {
        if( $size <= $freebies + $last_size ) {
            ok 1;

        } else {
            ok 0;
        }
    }

    $last_size = $size;
}
