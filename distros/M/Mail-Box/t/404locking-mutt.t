#!/usr/bin/env perl
#### test run untainted!  Otherwise we will not find a relative
#### mutt_dotlock program.
#
# Test the locking methods.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Mbox;
use Mail::Box::Locker::Mutt;

use Test::More;

use Log::Report;

BEGIN {
	eval qq{
		use POSIX 'sys_wait_h';
		close STDERR;    ### remove this to debug this test
		system('mutt_dotlock', '-u', '$0');
		die "OK!" if WIFEXITED(\$?);
	};

	$@ =~ m/OK!/
		or plan skip_all => "mutt_dotlock cannot be used";
}

my $foldername = $0;
my $fakefolder = bless +{ MB_foldername => $foldername }, 'Mail::Box::Mbox';

my $lockfile   = "$foldername.lock";
unlink $lockfile;

my $locker = Mail::Box::Locker->new(
	method  => 'MUTT',
	timeout => 1,
	wait    => 1,
	folder  => $fakefolder,
);

ok($locker, 'Created locker');
is($locker->name, 'MUTT', 'locker name');

ok($locker->lock,    'can lock');
ok(-f $lockfile,     'lockfile found');
ok($locker->hasLock, 'locked status');

# Already got lock, so should return immediately.
ok try(sub { $locker->lock }, hide => 'ALL'), 'second attempt';
my @e1 = $@->exceptions;
cmp_ok @e1, '==', 1;
like $e1[0]->message->toString, qr/already mutt-locked/;

$locker->unlock;
ok(! $locker->hasLock, 'released lock');

done_testing;
