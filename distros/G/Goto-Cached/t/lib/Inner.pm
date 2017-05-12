package Inner;

use strict;
use warnings;

our $GOTO_CACHED_IS_NOT_ENABLED;

sub goto_cached_is_not_enabled {
    use Devel::Pragma qw(my_hints);
    BEGIN { $GOTO_CACHED_IS_NOT_ENABLED = not(my_hints->{'Goto::Cached'}) }
    return $GOTO_CACHED_IS_NOT_ENABLED;
}

sub inner {
    use Goto::Cached;
    goto retval;
    unused: return 42;
    retval: return __PACKAGE__;
}

1;
