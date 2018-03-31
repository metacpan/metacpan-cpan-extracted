#! perl

use strict;
use warnings;

use Test::More;
use POSIX ();
use Linux::Epoll;

my $epoll = Linux::Epoll->new;

pipe my($in), my ($out);

tie *FH, 'TiedHandle', fileno $in;

my $colon = ':';
my $done;

$epoll->add(*FH, 'in', sub {
	my $events = shift;
	sysread FH, my $buf, 1;
	is($buf, $colon, 'Read a colon');
	$done = 1;
});

print $out $colon;
close $out;

alarm 3;
$epoll->wait(1, 1) while !$done;

ok($done, 'Received event');

done_testing(2);

package TiedHandle;

sub TIEHANDLE {
	my ($class, $fd) = @_;
	bless { fd => $fd }, $class;
}

sub FILENO {
	return $_[0]{fd};
}

sub READ {
	my ($self, undef, $count, undef) = @_;
	return POSIX::read($self->{fd}, $_[1], $count);
}
