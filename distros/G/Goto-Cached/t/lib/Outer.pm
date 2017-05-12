package Outer;

use strict;
use warnings;

use Goto::Cached;
use Inner;

sub outer { 
    goto retval;
    unused: return 42;
    retval: return __PACKAGE__;
}

sub inner {
    my $retval = 'retval';
    goto $retval;
    unused: return 42;
    retval: return [ Inner::goto_cached_is_not_enabled(), Inner::inner() ];
}

1;
