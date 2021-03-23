# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl -I/usr/local/bin t/File-Rename-script.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
push @INC, qw(blib/script) if -d 'blib';
unshift @INC, 't' if -d 't';
require 'testlib.pl';

my $script = script_name();
my $require_ok =  eval { require($script) };
ok( $require_ok, 'require script - '. $script);
die $@ unless $require_ok;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dir = tempdir();

create(qw(bing.txt bong.txt));

# test 2

main_argv('-E', 's/i/a/', '-E', 's/g/j/',
	glob File::Spec->catfile($dir,'b*') ); 
is_deeply( [ sort(listdir($dir)) ],
		[qw(banj.txt bonj.txt)], 'rename - files' );

File::Path::rmtree($dir);
