package IO::Mux::Packet ;

use strict ;
use IO::Handle ;
use Carp ;


our $VERSION = '0.08' ;


sub new {
	my $class = shift ;
	my $id = shift ;
	my $data = shift ;

	my $this = {} ;
	$this->{id} = $id ;
	$this->{data} = $data ;
	$this->{type} = 'D' ;

	return bless($this, $class) ;
}


sub get_length {
	my $this = shift ;

	return (defined($this->{data}) ? length($this->{data}) : 0) ;
}


sub get_data {
	my $this = shift ;

	return $this->{data} ;
}


sub get_id {
	my $this = shift ;

	return $this->{id} ;
}


sub get_type {
	my $this = shift ;

	return $this->{type} ;
}


sub is_eof {
	my $this = shift ;

	return $this->get_type() eq 'E' ;
}


sub make_eof {
	my $this = shift ;

	$this->{type} = 'E' ;
	$this->{data} = 0 ;
}


sub serialize {
	my $this = shift ;

	my $len = length(
		$this->get_id()) 
		+ 3 
		+ $this->get_length() ; 

	# We place the length in between 2 0x1 bytes in order to attempt
	# to detect invalid data appearing in the filehandle.
	return pack("CLC", 1, $len, 1) . 
		$this->get_id() 
		. "\t" . $this->get_type() . "\t" 
		. $this->get_data() ;
}


sub write {
	my $this = shift ;
	my $fh = shift ;

	# We do not write empty packets, but we still return success.
	return 1 if ! $this->get_length() ;

	my $ret = print $fh $this->serialize() ;
	if ($ret){
		$ret = $this->get_length() ;
	}

	return $ret ;
}


sub read {
	my $class = shift ;
	my $fh = shift ;

	my $len = '' ;
	while (length($len) < 6){
		my $rc = $fh->sysread($len, 6 - length($len), length($len)) ;
		if (! defined($rc)){
			return undef ;
		}
		elsif (! $rc){
			return 0 if ! length($len) ;
			croak("Unexpected EOF (incomplete packet length)") ;
		}
    }
	my ($mb, $me) = () ;
	($mb, $len, $me) = unpack("CLC", $len) ;
	if (($mb != 1)||($me != 1)){
		# We have bad data on the handle
		croak("Marker mismatch ($mb,$me) != (1,1): someone writing directly on IO::Mux Handle?") ;
	}

	my $buf = '' ;
	while (length($buf) < $len){
		my $rc = $fh->sysread($buf, $len - length($buf), length($buf)) ;
		if (! defined($rc)){
			return undef ;
		}
		elsif (! $rc){
			croak("Unexpected EOF (incomplete packet id or data)") ;
		}
	}

	if ($buf =~ s/^(.*?)\t([DE])\t//){
		my $id = $1 ;
		my $type = $2 ;
		my $p = new IO::Mux::Packet($id, $buf) ;
		if ($type eq 'E'){
			$p->make_eof() ; 
		}
		return $p ;
	}
	else {
		croak("Malformed packet: $buf") ;
	}
}



1 ;
