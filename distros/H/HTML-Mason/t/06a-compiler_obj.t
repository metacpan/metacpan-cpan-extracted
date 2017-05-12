use strict;
use warnings;

use HTML::Mason;
use Test;
plan tests => 4;

ok 1;  # Loaded

# We use the Interp class as a front-end to the compiler, but we're
# really testing the compiler here.  We could change this to eliminate
# the Interp stuff, probably.

my $interp = HTML::Mason::Interp->new;
ok $interp;

# Make sure the compiler can recover properly after a syntax error
eval {$interp->make_component( comp_source => <<'EOF' )};
  <&| syntax_error, in => "this" &>
    component
  </&|>
EOF
ok $@, qr{ending tag};

eval {$interp->make_component( comp_source => <<'EOF' )};
  <&| syntax_error, in => "this" &>
    component
  </&>
EOF
ok $@, '';

