use Test2::V0 -no_srand => 1;
use FFI::Platypus::Legacy::Raw::Platypus;

isa_ok( _ffi_package, 'FFI::Platypus' );
isa_ok( _ffi_libc,    'FFI::Platypus' );

done_testing;
