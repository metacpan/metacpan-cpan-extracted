use strict;
use warnings;
use Test::More tests => 1;

pass 'okay';

diag ''; diag '';

eval q{
  use FFI::Util;
  diag "lib=$_" for $FFI::Util::ffi->lib;
};

diag "error: $@" if $@;

diag ''; 
