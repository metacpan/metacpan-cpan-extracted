#!perl 
use warnings;
use strict;

use Test::More tests => 2;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{# bug 50 check - subs pushed repeatedly if search
 # found numerous times

    my $des = Devel::Examine::Subs->new();
    my $has = $des->has(file => 't/test/bug-50.data', search => 'this' );
    is (@$has, 6, "has() returns sub name only once if multiple lines contain search" );
}

