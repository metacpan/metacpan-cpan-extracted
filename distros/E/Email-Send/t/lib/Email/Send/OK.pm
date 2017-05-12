package Email::Send::OK;

use Test::More;

use strict;

sub is_available { 1 }

sub send {
  ok(1, "send message $_[0]");
}

1;
