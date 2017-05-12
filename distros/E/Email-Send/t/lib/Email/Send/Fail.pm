package Email::Send::Fail;

use strict;
use Return::Value;

sub is_available { 1 }

sub send {
  return failure "no bounce, no play";
}

1;
