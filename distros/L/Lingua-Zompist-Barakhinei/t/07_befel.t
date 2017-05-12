# vim:set filetype=perl:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 07_befel.t'

#########################

use Test::More tests => 32;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Barakhinei', 'befel' }

sub form_ok ($$$) {
    # croak 'usage: form_ok($verb, $is, $should)' unless @_ >= 3;
    my($verb, $is, $should) = @_;

    is($is->[0], undef,        "I.sg. of $verb");
    is($is->[1], $should->[0], "II.sg. of $verb");
    is($is->[2], $should->[1], "III.sg. of $verb");
    is($is->[3], undef,        "I.pl. of $verb");
    is($is->[4], $should->[2], "II.pl. of $verb");
    is($is->[5], $should->[3], "III.pl. of $verb");
}

form_ok('elirê',  befel('elirê',  1), [ qw( elir elira  elirêl eliran  ) ]);
form_ok('rikha',  befel('rikha',  2), [ qw( rikh rikha  rikhel rikhan  ) ]);
form_ok('lelê',   befel('lelê',   3), [ qw( lel  lela   lelel  lelan   ) ]);
form_ok('bêshti', befel('bêshti', 4), [ qw( bêch bêkcha bêkchu bêkchan ) ]);
form_ok('habê',   befel('habê',   5), [ qw( hap  haba   habu   haban   ) ]);

is(befel('chura', 2)->[2], 'chira', 'III.sg of chura');
