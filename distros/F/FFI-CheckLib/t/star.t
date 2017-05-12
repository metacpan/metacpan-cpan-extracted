use strict;
use warnings;
#use FindBin ();
use File::Spec;
#use lib $FindBin::Bin;
#use testlib;
use Test::More tests => 2;
BEGIN { $ENV{FFI_CHECKLIB_TEST_OS} = 'linux' }
use FFI::CheckLib;

$FFI::CheckLib::system_path = [];

my @libs = find_lib(
  libpath   => File::Spec->catdir( 't', 'fs', 'unix', 'foo-1.00'  ),
  lib       => '*',
  recursive => 1,
);

is scalar(@libs), 3, "libs = @libs";

my @fn = sort map { (File::Spec->splitpath($_))[2] } @libs;
is_deeply \@fn, [qw( libbar.so libbaz.so libfoo.so )], "fn = @fn";
