use strict;
use warnings;

use Error::Pure::Output::JSON qw(err_json);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $input_s = { 'foo' => ['bar', 'baz'] };
my $ret = err_json($input_s);
is($ret, '{"foo":["bar","baz"]}', 'Serialize simple hash (no pretty).');

# Test.
$Error::Pure::Output::JSON::PRETTY = 1;
$ret = err_json($input_s);
my $right_ret = <<'END';
{
   "foo" : [
      "bar",
      "baz"
   ]
}
END
is($ret, $right_ret, 'Serialize simple hash (pretty).');
