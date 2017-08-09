use Test2::V0 -no_srand => 1;
use FFI::TinyCC;

my $tcc = FFI::TinyCC->new;

my @list = eval { $tcc->detect_sysinclude_path };

skip_all "detect_sysinclude_path not supported on this platform"
  if $@;

cmp_ok scalar @list, '>', 0, 'returns a list';
note "$_" for @list;

eval { $tcc->compile_string(q{

#include <stdio.h>
#include <errno.h>

}) };

is $@, '';

done_testing;
