use strict;
use warnings;
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl -I/usr/local/bin t/File-Rename-script.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
push @INC, qw(blib/script blib/bin) if -d 'blib';
unshift @INC, 't' if -d 't';
require 'testlib.pl';

my $script = unsafe_script_name(); 
my $require_ok =  eval { require($script) };
ok( $require_ok, 'require script - '. $script);
die $@ unless $require_ok;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# test 2

my $buffer;
open my $stdout, '>', \$buffer or diag $!;
select $stdout;
main_argv('-V'); 

END{
    close $stdout or diag $!;
    like( $buffer, qr{
	\b $script 
	\s+ using 
	\s+ (\w+\:\:)+Rename 
	\s+ version 
	\s+ \d+(\.\d+)(_\d+)*
	(	, \s+ 
		(\w+\:\:)+Rename\:\:\w+ 
		\s+ version 
		\s+ \d+(\.\d+)(_\d+)* 
	)*
	$
    }msx, "-V");
}

