package Email::Send::Unavail;

use strict;
use Return::Value;

sub is_available { return failure "never available" }

sub send {
  die "this should never be called!"; # Seriously, guys.  -- rjbs, 2006-07-06
}

1;
