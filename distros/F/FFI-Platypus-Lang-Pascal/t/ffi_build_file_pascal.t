use Test2::V0 -no_srand => 1;
use FFI::Build::File::Pascal;

subtest basic => sub {

  is(
    FFI::Build::File::Pascal->new(\'Library Foo'),
    object {
      call [ isa => 'FFI::Build::File::Pascal' ] => T();
      call [ isa => 'FFI::Build::File::Base' ] => T();
      call fpc => match qr/./;
      call_list fpc_flags => [];
    },
  );

  is(
    FFI::Build::File::Pascal->new(\'Library Foo', fpc_flags => '-x'),
    object {
      call [ isa => 'FFI::Build::File::Pascal' ] => T();
      call [ isa => 'FFI::Build::File::Base' ] => T();
      call fpc => match qr/./;
      call_list fpc_flags => ['-x'];
    },
  );

  is(
    FFI::Build::File::Pascal->new(\'Library Foo', fpc_flags => ['-x','-y']),
    object {
      call [ isa => 'FFI::Build::File::Pascal' ] => T();
      call [ isa => 'FFI::Build::File::Base' ] => T();
      call fpc => match qr/./;
      call_list fpc_flags => ['-x','-y'];
    },
  );

};

done_testing;
