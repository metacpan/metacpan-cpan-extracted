
use strict;
use Test;

plan tests => 1;

eval 'use Devel::FindBlessedRefs'; ok( not $@ );
if( $@ ) {
    if( open IN, "Makefile" ) {
        warn " curious\n";
        while(<IN>) {
            warn $_ if m/(VERSION|REVISION)/ and not m/^\t/
        }
    }
}
