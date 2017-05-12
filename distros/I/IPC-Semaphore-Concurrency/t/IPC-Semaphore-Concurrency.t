# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IPC-Semaphore-Concurrency.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use POSIX qw(O_WRONLY O_CREAT O_NONBLOCK O_NOCTTY WNOHANG);
use strict;
use warnings;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Skip all if the testing architecture doesn't support semaphores
# bits taken from IPC::SysV tests...
use Config;
if ($ENV{'PERL_CORE'} && $Config{'extensions'} !~ m[\bIPC/SysV\b]) {
    plan(skip_all => 'IPC::SysV was not built');
}
if ($Config{'d_sem'} ne 'define' || $Config{'d_semget'} ne 'define' ||
    $Config{'d_semctl'} ne 'define') {
  plan(skip_all => 'Lacking d_sem, d_semget or d_semctl');
}

# My handy Acme Child Reaper(tm)
$SIG{'CHLD'} = sub { while (waitpid(-1, WNOHANG) > 0) {} };

my $file = undef;
my $base = ".IPC-Semaphore-Concurrency.test";

# Try different paths for writing the semaphore files
foreach my $prefix ('/tmp/', '/var/tmp/', '') {
	my $tmpfile = $prefix.$base;
	if (sysopen(my $f, "$tmpfile-0.$$", O_WRONLY|O_CREAT|O_NONBLOCK|O_NOCTTY)) {
		$file = $tmpfile;
		# $base now becomes what we'll use for cleaning up...
		$base = $prefix;
		last;
	}
}

if (!defined($file)) {
	plan skip_all => "Can't create a file for named semaphores: $!";
} else {
	plan tests => 5;
}

# Can't do that at compile time with a flexible plan, but we don't use prototypes anyway
use_ok('IPC::Semaphore::Concurrency');

# Simple semaphore usage
my $c = IPC::Semaphore::Concurrency->new("$file-1.$$");
ok(defined($c), "Simple usage");

# Remove semaphore
ok($c->remove(), "Remove semaphore");


# Full semaphore usage
$c = IPC::Semaphore::Concurrency->new(
	path    => "$file-2.$$",
	touch   => 1,
	project => 8,
	count   => 20,
	value   => 1,
	);
ok(defined($c), "Full usage");

# Remove semaphore
ok($c->remove(), "Remove semaphore");


# Clean up files
system('rm -rf '.$base.'.IPC-Semaphore-Concurrency.test-*');

