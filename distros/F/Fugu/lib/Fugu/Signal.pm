# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 OpenHAP Contributors
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Fugu::Signal;
our $VERSION = '0.1.2';

use Scalar::Util qw(refaddr weaken);

# Fugu::Signal - signal handlers that set an interrupt flag.
#
# Each manager owns its handlers and its interrupt flag. Two managers
# in one process do not see each other's state. The installed handlers
# close over the object, so a handler always finds the manager that
# installed it.

# Every live manager, keyed by address. The values are weak, so the
# registry never keeps an object alive. check_interrupted reads the
# whole registry for code that has no object at hand.
my %live;

# Fugu::Signal->new:
sub new ($class)
{
	my $self = bless {
		handlers    => {},
		original    => {},
		interrupted => 0,
	}, $class;

	$live{ refaddr $self } = $self;
	weaken $live{ refaddr $self };

	return $self;
}

# $self->setup_interrupt_flag(@signals):
#	Set up handlers that set the interrupt flag and do not exit.
#	Long-running operations can then check the flag and stop
#	cleanly.
sub setup_interrupt_flag ( $self, @signals )
{
	my $manager = $self;
	weaken $manager;

	for my $sig (@signals) {
		$self->{original}{$sig} = $SIG{$sig} // 'DEFAULT';
		$SIG{$sig} =
		    sub ($) { $manager->{interrupted} = 1 if $manager; };
		$self->{handlers}{$sig} = 1;
	}
	return $self;
}

# $self->restore:
#	Restore the original signal handlers
sub restore ($self)
{
	for my $sig ( keys %{ $self->{handlers} } ) {
		$SIG{$sig} = $self->{original}{$sig};
	}
	$self->{handlers} = {};
	return $self;
}

# $self->interrupted:
#	Report if this manager saw a signal.
sub interrupted ($self)
{
	return $self->{interrupted};
}

# $self->reset_interrupted:
#	Clear the interrupt flag of this manager.
sub reset_interrupted ($self)
{
	$self->{interrupted} = 0;
	return $self;
}

# check_interrupted():
#	Report if any live manager saw a signal. This package function
#	serves code that runs far from the object, for example a poll
#	loop deep in a library. Code that holds the object uses the
#	interrupted method.
sub check_interrupted()
{
	for my $key ( keys %live ) {
		my $manager = $live{$key};
		if ( !defined $manager ) {
			delete $live{$key};
			next;
		}
		return 1 if $manager->{interrupted};
	}
	return 0;
}

# DESTROY runs when the object goes out of scope
sub DESTROY ($self)
{
	delete $live{ refaddr $self };
	$self->restore;
}

1;
