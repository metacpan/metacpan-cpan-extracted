
# Time-stamp: "2004-12-29 19:28:24 AST"

use strict;
use Test;
BEGIN { plan tests => 5 };
BEGIN { ok 1 }
BEGIN { @ARGV = ('-foo', '-bar=4,5,6', '--', '-baz', '123') }
my %opts;
use Getopt::constant (
    ':prefix' => 'C_',
    'foo' => 0,
    'bar' => [],
    'quux' => 45,
  );
ok join('~',@ARGV), '-baz~123';
ok join('~',C_bar), '4~5~6';
ok C_foo, 1;
ok C_quux, 45;
print "#So there!\n";
