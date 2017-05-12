use strict;
use warnings;
use Test::More tests => 1;

pass 'okay';

diag ''; diag '';

eval q{
  use File::LibMagic::FFI;
  diag "lib=$_" for $File::LibMagic::FFI::ffi->lib;
};

diag "error: $@" if $@;

diag ''; 
