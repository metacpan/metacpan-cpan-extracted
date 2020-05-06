use Test2::V0 -no_srand => 1;
use FFI::Platypus 1.24;
use FFI::Platypus::Type::GoString;

my $ffi = FFI::Platypus->new( api => 1 );
$ffi->load_custom_type('::GoString' => 'gostring');
is(
  lives { $ffi->type('gostring') },
  T(),
);

done_testing;
