use strict;
use warnings;
use Test::More;

use Scalar::Util qw(refaddr);

use lib 't/lib';

# DDR - default default ref -- uses the default default_logger_ref
{ package DDR_P; use DDR::Parent '$Logger'; }
{ package DDR_C; use DDR::Child  '$Logger'; }

# SDR - shared default ref -- uses a default_logger_ref shared between classes
{ package SDR_P; use SDR::Parent '$Logger'; }
{ package SDR_C; use SDR::Child  '$Logger'; }

is(
  refaddr( $DDR_P::Logger ),
  refaddr( $DDR_C::Logger ),
  "DDR parent and child share logger storage",
);

# DDR::Child can store its default in a different place, but
# $DDR::Parent::Logger is already defined when we get here, so the logic is
# "already defined and not equal to *my* default, so it is untouched."
is($DDR_P::Logger->ident, 'DDR::Parent', "parent won the initialization race");

is(
  refaddr( $SDR_P::Logger ),
  refaddr( $SDR_C::Logger ),
  "SDR parent and child share logger storage",
);

is(
  $SDR_P::Logger->ident,
  'SDR::Parent',
  "SDR::Parent is initialized first, so its default wins",
);

done_testing;
