use warnings;
use strict;

use IPC::Shareable;
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process);


my @command = ('date');
my $rc = system( @command );

is $rc, 0, "system() returns success ok after moving CHLD handler";

IPC::Shareable::_end;

assert_clean_process();

done_testing();
