use strict;
use warnings;
use Test::More;
use FFI::CheckLib qw( find_lib );
use FFI::Platypus 1.00;

my $libtest = find_lib lib => 'test', libpath => 't/ffi/_build';
plan skip_all => 'test requires a C++ compiler'
  unless $libtest;

plan tests => 2;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->lang('CPP');
$ffi->lib($libtest);

$ffi->attach( c_int_sum => ['int', 'int'] => 'int');

is c_int_sum(1,2), 3, 'c_int_sum(1,2) = 3';

$ffi->attach( ['MyInteger::int_sum(int, int)' => 'cpp_int_sum'] => ['int','int'] => 'int');

is cpp_int_sum(1,2), 3, 'cpp_int_sum(1,2) = 3';
