use strict;
use warnings;
use FindBin ();
use File::Spec;
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 2;
BEGIN { $ENV{FFI_CHECKLIB_TEST_OS} = 'linux' }
use FFI::CheckLib;

$FFI::CheckLib::system_path = [];

my @libs = find_lib(
  libpath   => File::Spec->catdir( 't', 'fs', 'unix', 'foo-1.00'  ),
  lib       => 'foo',
  recursive => 1,
);

is scalar(@libs), 1, "libs = @libs";
like $libs[0], qr{libfoo.so}, "libs[0] = $libs[0]";
