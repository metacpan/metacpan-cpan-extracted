#!perl 
use warnings;
use strict;

use Test::More tests => 2;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{# bug 49 - if a file has no subs

    my $des = Devel::Examine::Subs->new();
    my $has = $des->has(file => 't/test/no_subs.pm');
    is (@$has, 0, "has() doesn't crash if no subs are found in file" );
}

