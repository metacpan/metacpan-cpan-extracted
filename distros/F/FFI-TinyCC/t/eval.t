use strict;
use warnings;
use Test::More tests => 2;
use FFI::TinyCC::Inline qw( tcc_eval );

is tcc_eval(q{ int main() { return 1+1; } }), 2;
is tcc_eval(q{ const char *main() { return "hello"; } }), "hello";
