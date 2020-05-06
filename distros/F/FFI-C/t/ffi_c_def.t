use Test2::V0 -no_srand => 1;
use FFI::C::Def;

is(
  dies { FFI::C::Def->new },
  match qr/FFI::C::Def is an abstract class/,
  'cannot create instance'
);

done_testing;
