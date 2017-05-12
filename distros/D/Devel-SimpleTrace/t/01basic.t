use strict;
use Test;
BEGIN { plan test => 3 }
END { ok(0) unless $::loaded }

# try to load the module
use Devel::SimpleTrace;
$::loaded = 1;
ok(1);  #01

# check if the version is defined
ok( defined $Devel::SimpleTrace::VERSION );  #02
ok( $Devel::SimpleTrace::VERSION, '/^\d+\.\d+(?:_\d{2}|b\d*)?$/' );  #03
