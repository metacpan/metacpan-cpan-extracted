use warnings;
use strict;

use Test::More tests => 14;

BEGIN { use_ok "Memoize::Lift", qw(lift); }

is eval q{ lift }, undef;
like $@, qr/\ANot enough arguments /;

is eval q{ lift() }, undef;
like $@, qr/\ANot enough arguments /;

is eval q{ lift(1,2) }, undef;
like $@, qr/\AToo many arguments /;

is eval q{ lift([) }, undef;
like $@, qr/^syntax error /m;
unlike $@, qr/^Not enough arguments /m;

our $i;
is eval q{ [); lift($i++) }, undef;
like $@, qr/^syntax error /m;
unlike $@, qr/^Not enough arguments /m;
is $i, undef;

1;
