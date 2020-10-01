use Test2::V0 -no_srand => 1;
use FFI::C::PosixFile;

skip_all 'Test requires POSIX extensions to libc File pointers'
  unless FFI::C::PosixFile->can('fileno');

subtest 'fileno' => sub {

  my $file = FFI::C::PosixFile->fopen(__FILE__, "r");
  isa_ok $file,  'FFI::C::File';
  isa_ok $file,  'FFI::C::PosixFile';
  is $file->fileno, match qr/^[0-9]+$/;
};

subtest 'fdopen' => sub {

  my $file = FFI::C::PosixFile->fdopen(0, 'r');
  isa_ok $file,  'FFI::C::File';
  isa_ok $file,  'FFI::C::PosixFile';
  is $file->fileno, 0;

  $file = FFI::C::PosixFile->fdopen(1, 'w');
  isa_ok $file,  'FFI::C::File';
  isa_ok $file,  'FFI::C::PosixFile';
  is $file->fileno, 1;

};

done_testing;
