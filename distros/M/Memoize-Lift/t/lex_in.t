use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok "Memoize::Lift", qw(lift); }

eval q{ sub cc($) { my($v) = @_; return lift($v); } };
like $@, qr/\Areference to external lexical from [^ ]+::lift subexpression/;

1;
