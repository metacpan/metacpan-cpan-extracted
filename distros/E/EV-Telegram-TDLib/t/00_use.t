use strict;
use warnings;

# A helper the core aliases into every mixin replaces a mixin's own sub of the
# same name, and the only trace of that is a warning at load. Some load
# warnings appear only once the whole program has compiled, so the handler
# goes in before the module and the check runs after.
our @WARNS;
BEGIN { $SIG{__WARN__} = sub { push @WARNS, $_[0] } }

use Test::More;
use EV::Telegram::TDLib;

delete $SIG{__WARN__};
is_deeply(\@WARNS, [], 'the module loads without a warning');
can_ok('EV::Telegram::TDLib', qw(new send execute close login));
is(EV::Telegram::TDLib->CLONE_SKIP, 1, 'CLONE_SKIP is 1');

done_testing;
