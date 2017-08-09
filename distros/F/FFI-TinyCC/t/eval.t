use Test2::V0 -no_srand => 1;
use FFI::TinyCC::Inline qw( tcc_eval );

is tcc_eval(q{ int main() { return 1+1; } }), 2;
is tcc_eval(q{ const char *main() { return "hello"; } }), "hello";

done_testing;
