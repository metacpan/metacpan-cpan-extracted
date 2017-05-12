# $Id: AnyEvent.pm,v 1.9 2009/04/21 12:02:06 dk Exp $

package IO::Lambda::Loop::AnyEvent;
use strict;
use warnings;
use AnyEvent;
use IO::Lambda qw(:constants);
use Time::HiRes qw(time);

my @records;

IO::Lambda::Loop::default('AnyEvent');

sub new   { bless {} , shift }
sub empty { scalar(@records) ? 0 : 1 }

sub watch
{
	my ( $self, $rec) = @_;

	my $flags  = $rec->[WATCH_IO_FLAGS];
	my $poll = '';
	$poll .= 'r' if $flags & IO_READ;
	$poll .= 'w' if $flags & IO_WRITE;
	$poll .= 'e' if $flags & IO_EXCEPTION;
	
	push @records, $rec;
	
	push @$rec, AnyEvent-> io(
		fh    => $rec-> [WATCH_IO_HANDLE],
		poll  => $poll,
		cb    => sub {
			my $nr = @records;
			@records = grep { $_ != $rec } @records;
			return if $nr == @records;

			$nr = pop @$rec;
			pop @$rec while $nr--;

			if ( length($poll) > 1) {
				# check for fh availability
				my $o = '';
				vec( $o, fileno( $rec-> [WATCH_IO_HANDLE]), 1) = 1;
				my ( $r, $w, $e) = ($o, $o, $o);
				my $n = select( $r, $w, $e, 0);
				$rec->[WATCH_IO_FLAGS] &=
					(( $r eq $o) ? IO_READ      : 0) | 
					(( $w eq $o) ? IO_WRITE     : 0) | 
					(( $e eq $o) ? IO_EXCEPTION : 0)
				;
			}
			$rec-> [WATCH_OBJ]-> io_handler($rec)
				if $rec->[WATCH_OBJ];
		}
	);

	if ( defined $rec->[WATCH_DEADLINE]) {
		my $time = $rec-> [WATCH_DEADLINE] - time;
		$time = 0 if $time < 0;
		push @$rec, AnyEvent-> timer(
			after  => $time,
			cb     => sub {
				my $nr = @records;
				@records = grep { $_ != $rec } @records;
				return if $nr == @records;

				$nr = pop @$rec;
				pop @$rec while $nr--;

				$rec-> [WATCH_IO_FLAGS] = 0;
				$rec-> [WATCH_OBJ]-> io_handler($rec)
					if $rec->[WATCH_OBJ];
			}
		);
		push @$rec, 2;
	} else {
		push @$rec, 1;
	}
}

sub after
{
	my ( $self, $rec) = @_;

	my $time = $rec-> [WATCH_DEADLINE] - time;
	$time = 0 if $time < 0;
	push @records, $rec;
	push @$rec, AnyEvent-> timer(
		after  => $time,
		cb     => sub {
			my $nr = @records;
			@records = grep { $_ != $rec } @records;
			return if $nr == @records;

			pop @$rec;
			pop @$rec;

			$rec-> [WATCH_OBJ]-> io_handler($rec)
				if $rec->[WATCH_OBJ];
		},
	), 1;
}

sub yield
{
	AnyEvent-> one_event;
}

sub remove
{
	my ($self, $obj) = @_;

	my @r;
	for ( @records) {
		next unless $_-> [WATCH_OBJ];
		if ( $_->[WATCH_OBJ] == $obj) {
			my $nr = pop @$_;
			pop @$_ while $nr--;
		} else {
			push @r, $_;
		}
	}

	return if @r == @records;
	@records = @r;
}

sub remove_event
{
	my ($self, $rec) = @_;

	my @r;
	for ( @records) {
		if ( $_ == $rec) {
			my $nr = pop @$_;
			pop @$_ while $nr--;
		} else {
			push @r, $_;
		}
	}

	return if @r == @records;
	@records = @r;
}

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::Loop::AnyEvent - AnyEvent event loop for IO::Lambda

=head1 DESCRIPTION

This is the implementation of event loop for C<IO::Lambda> based on C<AnyEvent> event
loop. The module is not intended for direct use.

=head1 LIMITATIONS

Note that L<AnyEvent> is also a proxy event loop itself, and depending on the
actual event loop module it uses, functionality of C<IO::Lambda> might be
limited. 

Found problems:

* All but C<Event> interfaces don't support C<IO_EXCEPTION>. 

* Interface to C<Tk> fails to work when more than one listener to the same filehandle 
is registered. 

* C<EV> doesn't work with threads and disk files.

See L<AnyEvent> for more specific description.

=head1 SYNOPSIS

  use AnyEvent;
  use IO::Lambda::Loop::AnyEvent; # explicitly select the event loop module
  use IO::Lambda;

=head1 SEE ALSO

L<AnyEvent>
