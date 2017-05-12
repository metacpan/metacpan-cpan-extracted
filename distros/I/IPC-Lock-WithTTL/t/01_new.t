use strict;
use Test::More;

require IPC::Lock::WithTTL;
IPC::Lock::WithTTL->import;
note("new");
my $obj = new_ok("IPC::Lock::WithTTL" => [ file => '/dev/null' ]);

# diag explain $obj

done_testing;
