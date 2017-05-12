package IO::Select::Trap;

use strict;
use IO::Select;
use Carp;

use vars qw/$VERSION/;
$VERSION = '0.032';

sub new {
	my $pkg = shift;
	my $opts = (ref $_[0] eq 'HASH') ? shift : {};
	my $self = bless {
		ioselect => new IO::Select(),
		handles => {},
		traps => ($opts->{traps} or 'String|Scalar'),
		debug => (exists $opts->{debug} ? $opts->{debug} : 1),
	}, (ref $pkg || $pkg);

	$self->add(@_) if @_;
	$self;
}

sub _update {
	my ($self) = shift;
	my $add = shift eq 'add';

	my @pthru;
	foreach my $h (@_) {
		next unless defined $h;
		unless ($self->_trapped($h)) {
			push @pthru, $h;
			next;
		}

		if ($add) {
				$self->{handles}->{\*{$h}} = $h;
		} else {
				delete $_[0]->{handles}->{\*{$h}};
		}
	}
	return \@pthru;
}

sub _trapped {
	my ($self, $h) = @_;
	if ((ref $h) =~ /$self->{traps}/i) {
		carp (ref $h)." is trapped.";
		return 1;
	} else {
		carp (ref $h)." is NOT trapped.";
		return 0;
	}
}

sub _count {
	my $self = shift;
	return scalar keys %{$self->{handles}};
}

sub _can_read {
	my $self = shift;
	return unless $self->_count;
	my @result;
	while (my ($k, $h) = each %{$self->{handles}}) {
		push @result, $h if (length ${$h->sref});
	}
	return wantarray ? @result : \@result;
}

sub _can_write {
	my $self = shift;
	return unless $self->_count;
	my @result;
	while (my ($k, $h) = each %{$self->{handles}}) {
		push @result, $h if ($h->opened);
	}
	return wantarray ? @result : \@result;
}

sub _has_exception {}

sub add {
	my $self = shift;
	my $pthru = $self->_update('add', @_);
	$self->{ioselect}->add(@$pthru) if @$pthru;
}

sub remove {
	my $self = shift;
	my $pthru = $self->_update('remove', @_);
	$self->{ioselect}->remove(@$pthru) if @$pthru;
}

sub select {
	shift if defined $_[0] && !ref($_[0]);
	my ($r, $w, $e, $t) = @_;
	my (@RR, @WR, @ER);

	my $rready = defined $r ? $r->_can_read : undef;
	my $wready = defined $w ? $w->_can_write : undef;
	my $eready = defined $e ? $e->_has_exception : undef;

	push @RR, @$rready if defined $rready;
	push @WR, @$wready if defined $wready;
	push @ER, @$eready if defined $eready;

	my ($ir) = defined $r ? $r->{ioselect} : undef;
	my ($iw) = defined $w ? $w->{ioselect} : undef;
	my ($ie) = defined $e ? $e->{ioselect} : undef;

	if (@RR || @WR || @ER) {
		$t = 0 unless (defined $t); # Force non-blocking select()
	}

	($rready, $wready, $eready) = IO::Select->select($ir, $iw, $ie, $t);
	push @RR, @$rready if defined $rready;
	push @WR, @$wready if defined $wready;
	push @ER, @$eready if defined $eready;


	return (\@RR, \@WR, \@ER);
}

sub exists {
	return unless defined $_[1];
	exists $_[0]->{handles}->{\*{$_[1]}};
}

sub can_read {
	my ($self, $t) = @_;
	my @hready = $self->_can_read();
	$t = 0 if (! defined $t && @hready);
	my @iready = $self->{ioselect}->can_read($t);
	return
		@iready ?
			@hready ? (@iready, @hready) : @iready
				: @hready;
}

sub can_write {
	my ($self, $t) = @_;
	my @hready = $self->_can_write();
	$t = 0 if (! defined $t && @hready);
	my @iready = $self->{ioselect}->can_write($t);
	return
		@iready ?
			@hready ? (@iready, @hready) : @iready
				: @hready;
}

sub has_exception {
	my ($self, $t) = @_;
	my @hready = $self->_has_exception();
	$t = 0 if (! defined $t && @hready);
	my @iready = $self->{ioselect}->has_exception($t);
	return
		@iready ?
			@hready ? (@iready, @hready) : @iready
				: @hready;
}

sub count {
	my $self = shift;
	return $self->{ioselect}->count
		+ scalar keys %{$self->{handles}};
}

sub _debug {
	my $self = shift;
	print STDERR "$self: ", @_ if $self->{debug};
}


1;
__END__

=head1 NAME

IO::Select::Trap - IO::Select() functionality on Scalar-based Filehandles

=head1 SYNOPSIS

 use IO::Select::Trap;
 use IO::String;

 my $ios = new IO::String();
 my $sock = new IO::Socket();
 my $rb = new IO::Select::Trap(<{ trap=>'Scalar|String' }>, $ios, $sock);
 my $wb = new IO::Select::Trap(<{ trap=>'Scalar|String' }>, $ios, $sock);
 my ($rready, $wready) = IO::Select::Trap->select($rb, $wb);

=head1 DESCRIPTION

IO::Select::Trap is a wrapper for C<IO::Select> which enables use of the
C<IO::Select-E<gt>select()> method on IO::Scalar or IO::String
object/filehandles. Other filehandle object types (ie IO::Socket) are passed
through to IO::Select for processing.  Most of the IO::Select interface is
supported.

An IO::String/Scalar object/filehandle is ready for reading when it contains
some amount of data.  It will always be ready for writing.  Also, IO::String/Scalar
objects will *never* block.

When calling select(), the trapped objects are evaluated first.  If any
are found to be ready, the IO::Select->select() is called with a timeout of
'0'.  Otherwise it is called with the supplied timeout (or undef).

=head1 OPTIONS

=over 4

=item trap I<experimental>

REGEX that specifies the IO objects to trap.

=back

=head1 LIMITATIONS

Currently, the select(), can_read(), etc. methods only support
trapped IO::Scalar or IO::String objects.  Other trapped objects will
probably break the tests that the methods use to determine read/write ability.

The is a bug when using IO::Scalar objects, in that two IO::Scalars can't be
compared.  Eg:

  $ios = new IO::Scalar;
  $ios2 = $ios;

  if ($ios == $ios2) { #...

.. causes a runtime error.  A fix has been sent to to the author, and should be
included in a future version.

=head1 AUTHOR & COPYRIGHT

Scott Scecina, E<lt>scotts@inmind.comE<gt>

Except where otherwise noted, IO::Select::Trap is
Copyright 2001 Scott Scecina. All rights reserved.
IO::Select::Trap is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<IO::Select>.

=cut
