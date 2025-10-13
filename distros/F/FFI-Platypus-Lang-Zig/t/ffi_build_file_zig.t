use Test2::V0 -no_srand => 1;
use FFI::Platypus 2.00;
use FFI::Build;
use FFI::Build::File::Zig;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

sub clean {
  path('t/ffi/_build')->remove_tree;
  path('t/ffi/zig-cache')->remove_tree;
  path('t/ffi/zig-out')->remove_tree;
}

clean();

my $lib;

subtest 'build' => sub {

  my $platform = FFI::Build::Platform->new;
  my $build = FFI::Build->new('test',
    dir => path('t/ffi/_build')->absolute->stringify,
  );

  my $file = FFI::Build::File::Zig->new('t/ffi/build.zig',
    platform => $platform,
    build => $build,
  );
  isa_ok $file, 'FFI::Build::File::Zig';

  my $out;
  try_ok { ($out, $lib) = capture_merged { $file->build_item } } '$file->build_item';

  note $out if defined $out && $out ne '';

  note "lib=$lib";

  ok -f $lib, "file exists";

};

subtest 'use' => sub {

  my $ffi;
  try_ok { $ffi = FFI::Platypus->new( api => 2, lang => 'Zig', lib => [$lib] ) } 'load platypus instance';

  is
    $ffi,
    object {
      call [find_symbol => 'add'] => T();
      call [function => 'add',  ['i32','i32'] => 'i32' ] => object {
        call [call => 1, 2] => 3;
      };
    },
    'can find and call add';
};

clean();

done_testing;
