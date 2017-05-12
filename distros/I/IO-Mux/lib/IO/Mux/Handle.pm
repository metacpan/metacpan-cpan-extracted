package IO::Mux::Handle ;
@ISA = qw(IO::Handle) ;

use strict ;
use IO::Handle ;


our $VERSION = '0.08' ;


sub new {
	my $class = shift ;
	my $mux = shift ;

	my $this = $class->SUPER::new() ;
    tie(*{$this}, 'IO::Mux::Tie::Handle', $mux) ;

	return $this ;	
}


sub open {
 	my $this = shift ;
 	my $id = shift ;

 	return open($this, $id) ;
}


sub get_error {
	my $this = shift ;

	return $this->_get_tie()->_get_error() ;
}


sub _get_tie {
	my $this = shift ;

	return tied(*{$this}) ;
}



#################################################
package IO::Mux::Tie::Handle ;
@IO::Mux::Tie::Handle::ISA = qw(Tie::Handle) ;

use Tie::Handle ;
use IO::Mux::Packet ;
use Errno ;


sub TIEHANDLE {
	my $class = shift ;
	my $mux = shift ;

	return $class->new($mux) ;
}


sub new {
	my $class = shift ;
	my $mux = shift ;

	my $this = {} ;
	$this->{mux} = $mux ;
	$this->{id} = undef ;
	$this->{closed} = 1 ;
	$this->{'eof'} = 0 ;
	$this->{error} = undef ;

	bless($this, $class) ;
}


sub OPEN {
	my $this = shift ;
	my $id = shift ;

	$this->CLOSE() ;

	$id =~ s/\t/ /g ; # no \t's allowed in the id
	if ($this->_get_mux()->_buffer_exists($id)){
		$this->_set_error("Id '$id' is already in use by another handle") ;
		return undef ;
	}

	$this->{id} = $id ;
    # Allocate the buffer
    $this->_get_mux()->_get_buffer($id) ;
	$this->{closed} = 0 ;
	$this->{'eof'} = 0 ;
	$this->{error} = undef ;

    return 1 ;
}


sub _get_mux {
	my $this = shift ;

	return $this->{mux} ;
}


sub _get_id {
	my $this = shift ;

	return $this->{id} ;
}


sub _get_eof {
	my $this = shift ;

	return $this->{'eof'} ;
}


sub _set_eof {
	my $this = shift ;

	$this->{'eof'} = 1 ;
}


sub _get_error {
	my $this = shift ;

	return $this->{error} ;
}


sub _set_error {
	my $this = shift ;
	my $msg = shift ;

	$this->{error} = $msg ;
	if (exists($!{EIO})){
		$! = Errno::EIO() ; 
	}
	else {
		$! = 99999 ; 
	}
}


sub _get_buffer {
	my $this = shift ;

	return $this->_get_mux()->_get_buffer($this->_get_id()) ;
}


sub _kill_buffer {
	my $this = shift ;

	return $this->_get_mux()->_kill_buffer($this->_get_id()) ;
}



sub WRITE {
	my $this = shift ;
	my ($buf, $len, $offset) = @_ ;

	if ($this->{closed}){
		$this->_set_error("WRITE on closed filehandle") ;
		return undef ;
	}

	my $p = new IO::Mux::Packet($this->_get_id(), substr($buf, $offset || 0, $len)) ;
	my $rc = $this->_get_mux()->_write($p) ;

	return $rc ;
}


sub READ {
	my $this = shift ;
	my ($buf, $len, $offset) = @_ ;

	if ($this->{closed}){
		$this->_set_error("READ on closed filehandle") ;
		return undef ;
	}
	return 0 if $this->_get_eof() ;

	# Load the buffer until there is enough data or EOF.
	#while ($this->_get_buffer()->get_length() < $len){

	# We must block if the buffer is empty, otherwise we just check
	# if there is something pending.
	my $probe = 1 ;
	if (! $this->_get_buffer()->get_length()){
		my $rc = $this->_read_more_data(1) ;
		if (! defined($rc)){
			return undef ; # error already set by read_more_data
		}
		elsif (! $rc){
			# EOF
			$probe = 0 ;
		}
	}

	if ($probe){
		my $rc = 1 ;
		while ($rc > 0){
			$rc = $this->_read_more_data(0) ;
		}

		if (! defined($rc)){
			return undef ; # error already set by read_more_data
		}
	}

	# Shorten the length if we hit EOF...
	if ($this->_get_buffer()->get_length() < $len){
		$len = $this->_get_buffer()->get_length() ;
	}

	if ($len > 0){
		# Extract $len bytes from the beginning of the buffer and
		my $data = $this->_get_buffer()->shift_data($len) ;
		substr($buf, $offset || 0, $len) = $data ;
		$_[0] = $buf ;
	}

	return $len ;
}


sub READLINE {
	my $this = shift ;

	if ($this->{closed}){
		$this->_set_error("READLINE on closed filehandle") ;
		return undef ;
	}
	return (wantarray ? () : undef) if $this->_get_eof() ;

	my @ret = () ;
	while (1){
		my $idx = -1 ;
		my $buf = undef ;
		while ((! length($/))||(($idx = index($this->_get_buffer()->get_data(), $/)) == -1)){
			my $rc = $this->_read_more_data(1) ;
			if (! defined($rc)){
				# Return what we got or return undef/() ?
				last ; # error already set by read_more_data
			}
			elsif (! $rc){
				# EOF
				last ;
			}
		}

		if ($idx != -1){
			$buf = $this->_get_buffer()->shift_data($idx + length($/)) ;
		}
		else {
			# Empty the buffer
			my $len = $this->_get_buffer()->get_length() ;
			if ($len){
				$buf = $this->_get_buffer()->shift_data($len) ;
			}
		}

		if (defined($buf)){
			push @ret, $buf ;
			last unless wantarray ;
		}
		else {
			last ;
		}
	}

	return (wantarray ? @ret : $ret[0]) ;
}


sub _read_more_data {
	my $this = shift ;
	my $blocking = shift ;

	if ($this->_get_buffer()->is_closed()){
		# The handle is closed.
		$this->_set_eof() ;
		return 0 ;
	}

	my $rc = undef ;
	eval {
		$rc = $this->_get_mux()->_read($this->_get_id(), $blocking) ;
	} ;
	if ($@){
		$this->_set_error($@) ;
		return undef ;
	}
	elsif (! defined($rc)){
		return $rc ;
	}
	elsif ($rc == -1){
		# No data available in non-blocking mode.
		return -1 ;
	}
	elsif (! $rc){
		# We have reached EOF.
		$this->_set_eof() ;
	}
	
	return $rc ;
}


sub EOF { 
	my $this = shift ;

	return 1 if $this->{closed} ;
	return $this->_get_eof() ;
}


sub CLOSE { 
	my $this = shift ;

	my $ret = 0 ;
	if (! $this->{closed}){
		my $p = new IO::Mux::Packet($this->{id}, 0) ;
		$p->make_eof() ;
		# Here the real filehandle is possibly closed, so we must silence
		# the warning. We may also get a SIGPIPE, which we will solve
		# by closing the real handle.
		local $SIG{__WARN__} = sub { 
			warn $_[0] unless ($_[0] =~ /closed filehandle/i) ; 
		} ;
		local $SIG{PIPE} = sub {
			close($this->_get_mux()->_get_handle()) ;
		} ;

		$ret = $this->_get_mux()->_write($p) ;
		$this->{closed} = 1 ;
		$this->_kill_buffer() ;
		return 1 ;
	}

	return $ret ;
}


sub SEEK {
	my $this = shift ;
	my $pos = shift ;
	my $whence = shift ;

	return 0 ;
}


sub BINMODE {
	my $this = shift ;

	if ($this->{closed}){
		$this->_set_error("BINMODE on closed filehandle") ;
		return undef ;
	}

	return 1 ;
}


sub FILENO {
	my $this = shift ;

	return $this->_get_id() ;
}


sub TELL {
	my $this = shift ;

	if ($this->{closed}){
		$this->_set_error("TELL on closed filehandle") ;
		return -1 ;
	}

	return 0 ;
}


sub DESTROY {
	my $this = shift ;

	$this->CLOSE() ;
}



1 ;
__END__
=head1 NAME

IO::Mux::Handle - Virtual handle used with the L<IO::Mux> multiplexer.

=head1 SYNOPSIS

  use IO::Mux ;

  my $mux = new IO::Mux(\*SOCKET) ;
  my $iomh = new IO::Mux::Handle($mux) ;

  open($iomh, "identifier") or die("Can't open: " . $io->get_error()) ;
  print $iomh "hello\n" ;
  while (<$iomh>){ 
    print $_ ;
  }
  close($iomh) ;


=head1 DESCRIPTION

C<IO::Mux::Handle> objects are used to create virtual handles that are 
multiplexed through an L<IO::Mux> object.


=head1 CONSTRUCTOR

=over 4

=item new ( IOMUX )

Creates a new C<IO::Mux::Handle> that is multiplexed over the real handle 
managed by IOMUX.

=back


=head1 METHODS

Since C<IO::Mux::Handle> extends L<IO::Handle>, most L<IO::Handle> methods 
that make sense in this context are supported. The corresponding builtins can 
also be used. Errors are reported using the standard return values and 
mechanisms. See below (L<IO::Mux::Handle/ERROR REPORTING>) for more details.

=over 4

=item $iomh->open ( ID )

Opens $iomh and associates it with the identifier ID. ID can be any scalar 
value, but any tabs ('\t') in ID will be replaced by spaces (' ') in order to 
make it compatible with the underlying multiplexing protocol.

Returns 1 on success or undef on error (the error message can be retreived by 
calling $iomh->get_error()).

=item $iomh->fileno ()

Since there is no real filehandle associated with C<IO::Mux::Handle> objects, 
$iomh->fileno() returns the ID identifier that was passed to $iomh->open().

=item $iomh->get_error ()

Returns the last error associated with $iomh.

=back


=head1 ERROR REPORTING

While manipulating C<IO::Mux::Handle> objects, two types of errors can occur:

=over 4

=item Errors encountered on the real underlying handle

When error occurs on the underlying (real) handle, $! is set as usual and 
the approriate return code is used.

=item Errors generated by C<IO::Mux::*> module code

Sometimes errors can be generated by the C<IO::Mux:*> code itself. In this 
case, $! is set to C<EIO> if possible (see L<Errno> for more details). If 
C<EIO> does not exists on your system, $! is set to 99999. Also, the actual 
C<IO::Mux::*> error message can be retrieved by calling $iomh->get_error().

Therefore, when working with C<IO::Mux::Handle> objects, it is always a good 
idea to check $iomh->get_error() when $! is supposed to be set, i.e.:

  print $iomh "hi!\n" or die("Can't print: $! (" . $iomh->get_error() . ")") ;

=back


=head1 SEE ALSO

L<IO::Handle>, L<IO::Mux>

=head1 AUTHOR

Patrick LeBoutillier, E<lt>patl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Patrick LeBoutillier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
