use strict;
use warnings;
use FFI::Platypus;

my $ffi = FFI::Platypus->new;
$ffi->lang('Pascal');
$ffi->lib('./libmylib.so');

$ffi->attach(
  Add => ['Integer','Integer'] => 'Integer'
);

print Add(1,2), "\n";
