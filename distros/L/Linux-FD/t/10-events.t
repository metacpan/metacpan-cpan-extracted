# perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 14;
use Linux::FD 'eventfd';
use IO::Select;

my $selector = IO::Select->new;

alarm 2;

my $fd = eventfd(0, 'non-blocking');
$selector->add($fd);

ok !$selector->can_read(0), "Can't read an empty eventfd";

ok $selector->can_write(0), "Can write to an empty eventfd";

ok !defined $fd->get, 'Can\'t read an empty eventfd';

$fd->add(42);

ok $selector->can_read(0), "Can read a filled eventfd";

is($fd->get, 42, 'Value of eventfd was 42');

ok !$selector->can_read(0), "Can't read an emptied eventfd";

SKIP: {
	my $fd2 = eval { eventfd(0, 'semaphore', 'non-blocking') };
	skip 'Semaphores not supported', 8 if not $fd2 and $@ =~ /^No such flag 'semaphore' known/;

	$selector->add($fd2);

	ok !$selector->can_read(0), "Can't read an empty eventfd";

	ok $selector->can_write(0), "Can write to an empty eventfd";

	ok !defined $fd2->get, 'Can\'t read an empty eventfd';

	$fd2->add(2);

	ok $selector->can_read(0), "Can read a filled eventfd";

	is($fd2->get, 1, 'Value of eventfd was 1');
	is($fd2->get, 1, 'Value of eventfd was 1');
	is($fd2->get, undef, 'Value of eventfd was undef');

	ok !$selector->can_read(0), "Can't read an emptied eventfd";
}

