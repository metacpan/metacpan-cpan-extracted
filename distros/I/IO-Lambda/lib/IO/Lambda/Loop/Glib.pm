package IO::Lambda::Loop::Glib;
use strict;
use warnings;
use Glib;
use Glib::Object::Introspection;
use IO::Lambda qw(:constants);
use Time::HiRes qw(time);

my @records;

IO::Lambda::Loop::default('Glib');

sub new   { bless {} , shift }
sub empty { scalar(@records) ? 0 : 1 }

my $reentrant = 0;
sub _yield
{
	return if $reentrant;
	$reentrant++;
	IO::Lambda::yield(1);
	$reentrant--;
}

sub watch
{
	my ( $self, $rec) = @_;
	
	my $fileno = fileno($rec-> [WATCH_IO_HANDLE]);
	die "Invalid filehandle" unless defined $fileno;

	my $flags  = $rec->[WATCH_IO_FLAGS];
	my %gio;
	%gio = (%gio, map { $_ => 1 } qw(G_IO_IN G_IO_HUP G_IO_ERR)) if $flags & IO_READ;
	%gio = (%gio, map { $_ => 1 } qw(G_IO_OUT G_IO_ERR))         if $flags & IO_WRITE;
	%gio = (%gio, map { $_ => 1 } qw(G_IO_HUP))                  if $flags & IO_EXCEPTION;
	
	push @records, $rec;
	
	push @$rec, Glib::IO->add_watch( $fileno, [keys %gio], sub {
		my $nr = @records;
		@records = grep { $_ != $rec } @records;
		goto RETURN if $nr == @records;

		$nr = pop @$rec;
		Glib::Source->remove(pop @$rec) while $nr--;

		# check for fh availability
		if ( scalar keys %gio) {
			my $o = '';
			vec( $o, $fileno, 1) = 1;
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
	RETURN:
		_yield;
	});

	if ( defined $rec->[WATCH_DEADLINE]) {
		my $time = $rec-> [WATCH_DEADLINE] - time;
		$time = 0 if $time < 0;
		push @$rec, Glib::Timeout->add($time * 1000, sub {
			my $nr = @records;
			@records = grep { $_ != $rec } @records;
			goto RETURN if $nr == @records;

			$nr = pop @$rec;
			Glib::Source->remove(pop @$rec) while $nr--;

			$rec-> [WATCH_IO_FLAGS] = 0;
			$rec-> [WATCH_OBJ]-> io_handler($rec)
				if $rec->[WATCH_OBJ];
		RETURN:
			_yield;
			return 0; # false to stop
		});
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
	push @$rec, Glib::Timeout->add($time * 1000, sub {
		my $nr = @records;
		@records = grep { $_ != $rec } @records;
		goto RETURN if $nr == @records;

		pop @$rec;
		Glib::Source->remove(pop @$rec);

		$rec-> [WATCH_OBJ]-> io_handler($rec)
			if $rec->[WATCH_OBJ];
	RETURN:
		_yield;
		return 0; # return 0 to stop
	}), 1;
}

sub yield
{
	my ($self, $nonblocking) = @_;
	Glib::Object::Introspection->invoke(
        	'Gtk', undef, 'main_iteration_do',
        	[!$nonblocking]
	) unless $reentrant;
}

sub remove
{
	my ($self, $obj) = @_;

	my @r;
	for ( @records) {
		next unless $_-> [WATCH_OBJ];
		if ( $_->[WATCH_OBJ] == $obj) {
			my $nr = pop @$_;
			Glib::Source->remove(pop @$_) while $nr--;
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
			Glib::Source->remove(pop @$_) while $nr--;
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

IO::Lambda::Loop::Glib - Glib event loop for IO::Lambda

=head1 DESCRIPTION

This is the implementation of event loop for C<IO::Lambda> based on C<Glib> event
loop. The module is not intended for direct use.

=head1 SYNOPSIS

  use AnyEvent;
  use IO::Lambda::Loop::Glib; # explicitly select the event loop module
  use IO::Lambda;

=head1 LIMITATIONS

Synchronous I/O (wait() and friends) can so far only work with either Gtk2 og
Gtk3 main loop initialized. Also, after the main loop gets stopped, this module
won't work as well.

Under Gtk2 it is not possible to run bare synchronous IO::Lambda I/O, without
calling main_loop, while under Gtk3 it works okay.

=head1 SEE ALSO

Big thanks to Martijn van Beers and Apocalypse for L<POE::Loop::Glib>.

L<AnyEvent>
