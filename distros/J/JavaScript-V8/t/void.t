#!/usr/bin/perl

use strict;
use warnings;

use JavaScript::V8;
use Test::More;

my $c = JavaScript::V8::Context->new;

my $x = 0;

$c->bind(unexpected => sub { $x = 1 });

$c->eval(<<'EOF');
x = {
  get foo() {
    unexpected();
  }
}
EOF

is $x, 0, "Last expression not converted to Perl data " .
          "structure when eval() called in void context.";

done_testing;
