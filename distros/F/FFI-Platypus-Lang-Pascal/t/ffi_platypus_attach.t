use Test2::V0 -no_srand => 1;
use FFI::CheckLib qw( find_lib );
use FFI::Platypus;

my $libtest = find_lib lib => 'test', libpath => 't/ffi';
skip_all 'test requires Free Pascal'
  unless $libtest;

my $ffi = FFI::Platypus->new;
$ffi->lang('Pascal');
$ffi->lib($libtest);

subtest lib => sub {
  $ffi->attach( Add => ['Integer', 'Integer'] => 'Integer');
  is Add(1,2), 3, 'add(1,2) = 3';
};

done_testing;
