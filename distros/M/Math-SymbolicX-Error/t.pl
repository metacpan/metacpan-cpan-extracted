use strict;
use warnings;
use Math::Symbolic qw/:all/;
use Math::SymbolicX::ParserExtensionFactory (
  'foo' => sub {
    warn "foo\n";
    return Math::Symbolic::Constant->one();
  },
);

print parse_from_string("b + foo(a)");
print "\n";

