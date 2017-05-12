package IO::Mux ;

use 5.008 ;
use strict ;
use Symbol ;
use IO::Mux::Handle ;
use IO::Mux::Packet ;
use IO::Mux::Buffer ;
use IO::Handle ;
use IO::Select ;
use Carp ;


our $VERSION = '0.08' ;


sub new {
	my $class = shift ;
	my $fh = shift ;

	my $this = {} ;
	if (UNIVERSAL::isa($fh, 'GLOB')){
		# Make sure we save the actual IO bit, not the entire GLOB ref, because
		# one typical usage could be to place \*STDOUT in a IO::Mux object and then
		# do: *STDOUT = $mux. If we save the GLOB ref, that will create infinite
		# recursion as the GLOB is deferenced each time to get the IO bit.
		$this->{'glob'} = $fh ;
		$fh = *{$fh}{IO} ;
	}
	$fh->autoflush(1) ;

	$this->{fh} = $fh ;
	$this->{buffers} = {} ;
	$this->{'select'} = new IO::Select($fh) ;

	return bless($this, $class) ;
}


sub get_handle {
	my $this = shift ;

	return (defined($this->{'glob'}) ? $this->{'glob'} : $this->{fh}) ;
}


sub _get_handle {
	my $this = shift ;

	return $this->{fh} ;
}


sub new_handle {
	my $this = shift ;

	return new IO::Mux::Handle($this) ;
}


sub _get_buffer {
	my $this = shift ;
	my $id = shift ;

	if (! $this->_buffer_exists($id)){
		$this->{buffers}->{$id} = new IO::Mux::Buffer() ; 
	}

	return $this->{buffers}->{$id} ;
}


sub _buffer_exists {
	my $this = shift ;
	my $id = shift ;

	return defined($this->{buffers}->{$id}) ;
}


sub _kill_buffer {
	my $this = shift ;
	my $id = shift ;

	delete $this->{buffers}->{$id} ;
}


sub _read {
	my $this = shift ;
	my $id = shift ;
	my $blocking = shift ;

	my $p = undef ;
	while (! defined($p)){
		my $tp = $this->_read_packet($blocking) ;
		if (! defined($tp)){
			return undef ;
		}
		elsif (! $tp){
			return 0 ;
		}
		elsif ($tp == -1){
			# No packet available in non-blocking mode.
			return -1 ;
		}
		else {
			if ($tp->get_id() eq $id){
				if (! $tp->is_eof()){
					$p = $tp ;	
				}
				else {
					return 0 ;
				}
			}
		}
	}

	return $p->get_length() ;
}


sub _is_packet_available {
	my $this = shift ;

	my @ready = $this->{'select'}->can_read(0) ;

	return scalar(@ready) ;
}


# Returns a packet, 0 on real handle EOF or undef on error.
sub _read_packet {
	my $this = shift ;
	my $blocking = shift ;

	if (! $blocking){
		return -1 unless $this->_is_packet_available() ;
	}

	my $p = IO::Mux::Packet->read($this->_get_handle()) ;
	if (! defined($p)){
		return undef ;
	}
	elsif (! $p){
		return 0 ;
	}
	else {
		# Append the packet data to the correct buffer
		my $buf = $this->_get_buffer($p->get_id()) ;
		$buf->push_packet($p) ;

		return $p ;
	}
}


sub _write {
	my $this = shift ;
	my $packet = shift ;

	return $packet->write($this->_get_handle()) ;
}



1 ;
__END__
=head1 NAME

IO::Mux - Multiplex several virtual streams over a real pipe/socket

=head1 SYNOPSIS

  use IO::Mux ;

  pipe(R, W) ;

  if (fork){
      my $mux = new IO::Mux(\*W) ;
      my $alice = $mux->new_handle() ;
      open($alice, 'alice') ;
      my $bob = $mux->new_handle() ;
      open($bob, 'bob') ;

      print $alice "Hi Alice!\n" ;
      print $bob "Hi Bob!\n" ;
  }
  else {
      my $mux = new IO::Mux(\*R) ;
      my $alice = $mux->new_handle() ;
      open($alice, 'alice') ;
      my $bob = $mux->new_handle() ;
      open($bob, 'bob') ;

      print scalar(<$bob>) ;
      print scalar(<$alice>) ;
  }


=head1 DESCRIPTION

C<IO::Mux> allows you to multiplex several virtual streams over a single pipe
or socket. This is achieved by creating an C<IO::Mux> object on each end of the 
real stream and then creating virtual handles (C<IO::Mux::Handle> objects) from
these C<IO::Mux> objects.

Each C<IO::Mux::Handle> object is assigned a unique identifier when opened, and 
C<IO::Mux::Handle> objects on each end of the real stream that have the same
identifier are "mapped" to each other.


=head1 CONSTRUCTOR

=over 4

=item new ( HANDLE )

Creates a new C<IO::Mux> object that multiplexes over HANDLE. C<autoflush> will
be turned on for HANDLE.

=back


=head1 METHODS

=over 4

=item $mux->get_handle ()

Returns the handle passed when $mux was created. Note that if a GLOB reference
was originately passed, only the IO component of the glob will be returned. 
Therefore it is possible that the value returned here be different than the one
actually passed in the constructor.

=item $mux->new_handle ()

Convenience method. Returns a new L<IO::Mux::Handle> object
created on $mux. Is equivalent to:

  new IO::Mux::Handle($mux) ;

The handle must then be opened before being used. See L<IO::Mux::Handle>
for more details.

=back


=head1 NOTE

Once a handle has been passed to an C<IO::Mux> object, it is important that 
it is not written to/read from directly as this will corrupt the C<IO::Mux> 
stream. Once the C<IO::Mux> objects on both ends of the stream are out of 
scope (and have no data pending), normal usage of the handleis can resume.


=head1 SEE ALSO

L<IO::Mux::Handle>

=head1 AUTHOR

Patrick LeBoutillier, E<lt>patl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Patrick LeBoutillier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
