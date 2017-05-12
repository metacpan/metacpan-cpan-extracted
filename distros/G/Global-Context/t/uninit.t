use strict;
use warnings;

use Global::Context -all, '$Context';

use Global::Context::AuthToken::Basic;
use Global::Context::Terminal::Basic;

use Test::More;
use Test::Fatal;

like(
  exception { ctx_push("foo") },
  qr/uninitialized/,
  "can't push onto uninitialized context",
);

done_testing;
