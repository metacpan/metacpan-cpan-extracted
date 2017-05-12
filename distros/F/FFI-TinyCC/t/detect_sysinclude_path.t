use strict;
use warnings;
use Test::More;
use FFI::TinyCC;

my $tcc = FFI::TinyCC->new;

my @list = eval { $tcc->detect_sysinclude_path };

plan skip_all => "detect_sysinclude_path not supported on this platform"
  if $@;

plan tests => 2;

cmp_ok scalar @list, '>', 0, 'returns a list';
note "$_" for @list;

eval { $tcc->compile_string(q{

#include <stdio.h>
#include <errno.h>

}) };

is $@, '';
