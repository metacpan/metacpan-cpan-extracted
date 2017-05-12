# vim:set filetype=perl sw=4 et:
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 08_part.t'

#########################

use Test::More tests => 21;
use Carp;

BEGIN { use_ok 'Lingua::Zompist::Barakhinei', 'part' }

sub form_ok ($$$) {
    # croak 'usage: form_ok($verb, $is, $should)' unless @_ >= 3;
    my($verb, $is, $should) = @_;

    is($is->[0], $should->[0], "present participle of $verb");
    is($is->[1], $should->[1], "past participle of $verb");
}

form_ok('elirê',  scalar(part('elirê',  1)), [ qw( eliril elirêl ) ]);
form_ok('rikha',  scalar(part('rikha',  2)), [ qw( rikhê  rikhu  ) ]);
form_ok('lelê',   scalar(part('lelê',   3)), [ qw( lelê   lelu   ) ]);
form_ok('bêshti', scalar(part('bêshti', 4)), [ qw( bêshti bêkchu ) ]);
form_ok('habê',   scalar(part('habê',   5)), [ qw( habê   habêl  ) ]);

# And now test the list context return by using [ ] to capture the output
form_ok('elirê',  [ part('elirê',  1) ], [ qw( eliril elirêl ) ]);
form_ok('rikha',  [ part('rikha',  2) ], [ qw( rikhê  rikhu  ) ]);
form_ok('lelê',   [ part('lelê',   3) ], [ qw( lelê   lelu   ) ]);
form_ok('bêshti', [ part('bêshti', 4) ], [ qw( bêshti bêkchu ) ]);
form_ok('habê',   [ part('habê',   5) ], [ qw( habê   habêl  ) ]);
