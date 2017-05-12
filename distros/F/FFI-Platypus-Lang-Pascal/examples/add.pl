use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->lang('Pascal');
$ffi->lib('./add.so');

$ffi->attach(
  ['Add.Add(SmallInt,SmallInt):SmallInt' => 'Add'] => ['Integer','Integer'] => 'Integer'
);

print Add(1,2), "\n";

