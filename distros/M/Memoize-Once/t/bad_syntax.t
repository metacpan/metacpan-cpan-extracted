use warnings;
use strict;

use Test::More tests => 13;

BEGIN { use_ok "Memoize::Once", qw(once); }

is eval q{ once }, undef;
like $@, "$]" >= 5.009005 ? qr/\ANot enough arguments / : qr/\Asyntax error /;

is eval q{ once() }, undef;
like $@, qr/\ANot enough arguments /;

is eval q{ once(1,2) }, undef;
like $@, qr/\AToo many arguments /;

is eval q{ once([) }, undef;
like $@, qr/^syntax error /m;
unlike $@, qr/^Not enough arguments /m;

is eval q{ [); once(1) }, undef;
like $@, qr/^syntax error /m;
unlike $@, qr/^Not enough arguments /m;

1;
