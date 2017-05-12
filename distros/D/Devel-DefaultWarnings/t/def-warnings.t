use strict;
use Test::More tests => 3;
use Devel::DefaultWarnings;

{
  ok warnings_default;
}
{
  use warnings;
  BEGIN { ok !warnings_default; }
}
{
  no warnings;
  BEGIN { ok !warnings_default; }
}
