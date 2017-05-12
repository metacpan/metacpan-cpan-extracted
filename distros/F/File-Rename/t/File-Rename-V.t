# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl -I/usr/local/bin t/File-Rename-script.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { push @INC, qw(blib/script) if -d 'blib' };

my $script = ($^O =~ m{Win} ? 'file-rename' : 'rename');
my $require_ok =  eval { require($script) };
ok( $require_ok, 'require script - '. $script);
die $@ unless $require_ok;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub main_argv { local @ARGV = @_; main (); } 

# test 2

my $buffer;
close STDOUT;
open STDOUT, '>', \$buffer or diag $!;
main_argv('-V'); 

END{ 
    close STDOUT or diag $!;
    like( $buffer, qr{
	\b $script 
	\s+ using 
	\s+ (\w+\:\:)+Rename 
	\s+ version 
	\s+ \d+(\.\d+)+[a-z]*
	$
    }msx, "-V");
}

