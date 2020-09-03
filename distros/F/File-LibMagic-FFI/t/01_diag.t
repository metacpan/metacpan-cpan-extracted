use strict;
use warnings;
use Test::More;
use File::LibMagic::FFI;

pass 'okay';

diag '';
diag '';

  diag "lib=$_" for $File::LibMagic::FFI::ffi->lib;

diag '';

done_testing;
