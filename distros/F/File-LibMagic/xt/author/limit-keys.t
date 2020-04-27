use strict;
use warnings;

use File::LibMagic;
use File::LibMagic::Constants qw( constants );
use List::Util qw ( max );

use Test::More;

my %keys
    = map { $_ => File::LibMagic->$_() } grep {/^MAGIC_PARAM/} constants();
my $max = max values %keys;

# We can only assume these tests will pass on machines where we do the entire
# build from scratch using a version of libmagic that supports all the
# documented keys. That way we know that the constants match what's defined by
# the machine's magic.h.

is(
    File::LibMagic->max_param_constant,
    $max,
    'max_param_constant matches the max constant we know about',
);

## no critic (Subroutines::ProtectPrivateSubs)
for my $p ( File::LibMagic->_all_limit_params ) {
    ok(
        File::LibMagic->limit_key_is_supported($p),
        "$p limit is supported",
    );
}

done_testing();
