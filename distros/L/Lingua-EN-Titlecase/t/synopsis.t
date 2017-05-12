#!perl

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 2;

#------------------------------------------------------------------
open F, '<', "$FindBin::Bin/../lib/Lingua/EN/Titlecase.pm"
    or die "Couldn't open self module to read!";

my $synopsis = '';
while ( <F> ) {
    if ( /=head1 SYNOPSIS/i .. /=head\d (?!S)/
                   and not /^=/ )
    {
        $synopsis .= $_;
    }
}
close F;

ok( $synopsis,
    "Got code out of the SYNOPSIS space to evaluate" );

eval "use strict; use warnings; $synopsis";

diag( $@ . "\n" . $synopsis ) if $@;

ok( ! $@, "Synopsis code sample eval'd" );
