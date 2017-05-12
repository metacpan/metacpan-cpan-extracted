package IO::Mux::Select ;

use strict ;
use IO::Select ;
use IO::Mux ;
use IO::Mux::Handle ;
use IO::Mux::Packet ;
use Carp ;


our $VERSION = '0.08' ;


sub new {
	my $class = shift ;

	my $this = {} ;
	$this->{'select'} = new IO::Select() ;
	$this->{mux_handles} = {} ;
	bless($this, $class) ;

	$this->add(@_) ;

	return $this ;
}


sub _get_select {
	my $this = shift ;

	return $this->{'select'} ;
}


sub _get_mux_handles {
	my $this = shift ;

	return $this->{mux_handles} ;
}


sub add {
	my $this = shift ;

	foreach my $h (@_){
		if ($h->isa('IO::Mux::Handle')){
			$this->_get_mux_handles()->{$h->_get_tie()->_get_id()} = $h ;
		}
		else { 
			$this->_get_select()->add($h) ;
		}
	}
}


sub remove {
	my $this = shift ;

	foreach my $h (@_){
		if ($h->isa('IO::Mux::Handle')){
			delete $this->_get_mux_handles()->{$h->_get_tie()->_get_id()} ;
		}		
		elsif ($this->_get_select()->exists($h)){
			$this->_get_select()->remove($h) ;
		}
	}
}


sub exists {
	my $this = shift ;
	my $h = shift ;

	if ($h->isa('IO::Mux::Handle')){
		return $this->_get_mux_handles()->{$h->_get_tie()->_get_id()} ;
	}
	else {
		return $this->_get_select()->exists($h) ;
	}
}


sub handles {
	my $this = shift ;

	my @ret = () ;
	push @ret, values %{$this->_get_mux_handles()} ;
	push @ret, $this->_get_select()->handles() ;

	return @ret ;
}


sub count {
	my $this = shift ;

	return scalar($this->handles()) ;
}


sub can_read {
	my $this = shift ;
	my $timeout = shift ;

	# First, we will check to see if the IO::Mux::Handles have data in their buffers.
	my @ready = () ;
	foreach my $h (values %{$this->_get_mux_handles()}){
		if ((eof($h))||($h->_get_tie()->_get_buffer()->get_length() > 0)){
			push @ready, $h ;
		}
	}

	if (scalar(@ready)){
		# Maybe some real handles are immediately ready
		push @ready, $this->_get_select()->can_read(0) ;
		return @ready ;
	}

	# So it seems we may have to wait after all. We now need to build a list
	# of all the REAL handles underneath all the IO::Mux::Handles.
	my %mux_objects = () ;
	foreach my $h (values %{$this->_get_mux_handles()}){
		my $mux = $h->_get_tie()->_get_mux() ;
		my $rh = $mux->_get_handle() ;
		if (! exists($mux_objects{$rh})){
			$mux_objects{$rh} = {mux => $mux, mux_handles => {}} ;
		}
		$mux_objects{$rh}->{mux_handles}->{$h} = $h ;
	}

	my @real_handles = map {$_->{mux}->_get_handle()} values(%mux_objects) ;
	$this->_get_select()->add(@real_handles) ;
	@ready = $this->_get_select()->can_read($timeout) ;
	$this->_get_select()->remove(@real_handles) ;

	if (scalar(@ready)){
		my @tmp = @ready ;
		my %ready = () ;
		@ready = () ;
		foreach my $h (@tmp){
			my $mux_data = $mux_objects{$h} ;
			if ($mux_data){
				my $mux = $mux_data->{mux} ;
				# We have data ready on the REAL handle. Let's consume the packet
				# and add the corresponding IO::Mux::Handle in the new ready list.
				while ((my $p = $mux->_read_packet(0)) != -1){
					if ((! defined($p))||(! $p)){
						# ERROR or EOF on the real handle. Return all mux_handles
						# as they all now are at EOF or have an error state.
						foreach my $mh (values %{$mux_data->{mux_handles}}){
							if (! $ready{$mh}){
								push @ready, $mh ;
								$ready{$mh} = 1 ;
							}
						}
						last ;
					}
					else {
						my $mh = $this->_get_mux_handles()->{$p->get_id()} ;
						next unless defined($mh) ;
						if (! $ready{$mh}){
							push @ready, $mh ;
							if ($p->is_eof()){
								$mh->_get_tie()->_set_eof() ;
							}
							$ready{$mh} = 1 ;
						}
					}
				}
			}
			else {
				# REAL handle, we simply push it.
				push @ready, $h ;
			}
		}
	}

	return @ready ;
}


1 ;
__END__
=head1 NAME

IO::Mux::Select - Drop-in replacement for L<IO::Select> when using 
L<IO::Mux::Handle> objects.

=head1 SYNOPSIS

  use IO::Mux ;
  use IO::Mux::Select ;

  my $mux = new IO::Mux(\*R) ;
  my $alice = $mux->new_handle() ;
  open($alice, 'alice') ;
  my $bob = $mux->new_handle() ;
  open($bob, 'bob') ;

  my $ims = new IO::Mux::Select($alice, $bob) ;
  while(my @ready = $ims->can_read()){
    foreach my $h (@ready){
      # Do something useful...
    }
  }


=head1 DESCRIPTION

C<IO::Mux::Select> is a drop-in replacement for L<IO::Select> that knows how 
to deal with L<IO::Mux::Handle> handles. It also supports real handles so 
you can mix L<IO::Mux::Handle> handles with real handles.


=head1 CONSTRUCTOR

=over 4

=item new ( [ HANDLES ] )

The constructor creates a new object and optionally initialises it with a set
of handles.

=back


=head1 METHODS

The same interface as L<IO::Select> is supported, with the following 
exceptions:

=over 4

=item can_read ( [ TIMEOUT ] )

This method behaves pretty much like the L<IO::Select> one, except it is not 
guaranteed that it will return before TIMEOUT seconds. The reason for this is 
that the L<IO:Mux::Handle> objets handle data in packets, so if data is 
"detected" on such a handle, can_read() must read the entire packet before 
returning.

=item can_write ( [ TIMEOUT ] )

Not implemented.

=item has_exception ( [ TIMEOUT ] )

Not implemented.

=item bits ()

Not implemented.

=item select ( READ, WRITE, EXCEPTION [, TIMEOUT ] )

Not implemented.

=back


=head1 SEE ALSO

L<IO::Select>, L<IO::Mux>, L<IO::Mux::Handle>


=head1 AUTHOR

Patrick LeBoutillier, E<lt>patl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Patrick LeBoutillier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
