
use strict;
use warnings;
use Test::More;

eval { require "t/lib/Wrong.pm"; };
like $@, qr/Can't declare parameters after a slurpy parameter/;

eval { require "t/lib/Wrong2.pm"; };
like $@, qr/expected sigil instead of/;

eval { require "t/lib/Wrong3.pm"; };
like $@, qr/expected .* instead of/;

done_testing;


