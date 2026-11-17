#! perl

use strict;
use warnings;
use Test::More tests => 21;
use Linux::Epoll;
use POSIX qw/raise sigprocmask SIG_BLOCK SIGUSR1/;

use Socket qw/AF_UNIX SOCK_STREAM PF_UNSPEC/;
use Scalar::Util qw/weaken/;

my $poll = Linux::Epoll->new();

is $poll->wait(1, 0), 0, 'No events to wait for';

socketpair my $in, my $out, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die 'Failed';
$_->blocking(0) for $in, $out;

my $subnum = 1;
my $sub = sub { 
	my $event = shift;
	is $subnum, 1, 'Anonymous closure works';
	ok $event->{in}, '$event->{in} is true';
	is sysread($in, my $buffer, 3), 3, 'Read 3 bytes';
};
ok $poll->add($in, 'in', $sub), 'Can add to the set';
weaken $sub;
ok defined $sub, '$sub is still defined';

syswrite $out, 'foo', 3;
is $poll->wait(1, 0), 1, 'Finally an event';
is $poll->wait(1, 0), 0, 'No more events to wait for';

my $sigset = POSIX::SigSet->new(SIGUSR1);
my $empty = POSIX::SigSet->new;
sigprocmask(SIG_BLOCK, $sigset);

$SIG{USR1} = sub {
	$subnum = 2;
	syswrite $out, 'bar', 3;
};
raise(SIGUSR1);

my $sub2 = sub {
	my $event = shift;
	is $subnum, 2, 'New handler works too'; 
	ok $event->{in}, '$event->{in} is true';
	is sysread($in, my $buffer, 3), 3, 'Got 3 more bytes';
};
ok $poll->modify($in, [ qw/in prio/ ], $sub2), 'Can modify the set';
weaken $sub2;
ok defined $sub2, '$sub2 is still defined';
is $subnum, 1, 'subnum is still 1';
is $poll->wait(2, 1, $empty), undef, 'Interrupted event';
is $poll->wait(2, 0, $empty), 1, 'Yet another event';

ok $poll->delete($in), 'Can delete from set';
ok !defined $sub2, '$sub2 is no longer defined';

syswrite $out, 'baz', 3;
is $poll->wait(1, 0), 0, 'No events on empty epoll';

my $sub3 = sub { $subnum };
$poll->add($out, 'in', $sub3);
weaken $sub3;

undef $out;
ok !defined $sub3, '$sub3 is no longer defined';

my @gen_globs = grep { /^_GEN_\d+$/ } keys %Linux::Epoll::;
is_deeply \@gen_globs, [], 'Epoll leaves nothing in the stash';
