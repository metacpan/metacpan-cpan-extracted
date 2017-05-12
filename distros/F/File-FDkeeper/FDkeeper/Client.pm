package File::FDkeeper::Client ;
@ISA = qw(File::FDkeeper) ;

use strict ;
use File::FDkeeper ;
use File::FDpasser ;
use Carp ;


sub new {
	my $class = shift ;
	my $path = shift ;
	my %args = @_ ;

	my $this = {} ;
	$this->{path} = $path ;
	bless($this, $class) ;

	while (my ($k, $v) = each %args){
		croak("Invalid attribute '$k'") ;
	}

	my $client = endp_connect($path) ;
	croak("Error connecting to server endpoint '$path': $!") unless $client ;
	$client->autoflush(1) ;
	$this->{client} = $client ;

	return $this ;
}


sub put {
	my $this = shift ;
	my $fh = shift ;

	if (UNIVERSAL::isa($fh, 'GLOB')){
		$fh = *{$fh}{IO} ;
	}

	$this->_init_cmd('put') ;
	if (! send_file($this->{client}, $fh)){
		close($this->{client}) ;
		croak("Error sending filehandle: $!") ;
	}
	my @ret = $this->_wrap_up() ;

	return undef unless $ret[0] ;

	# For some reason, the filehandle needs to be closed now
	# if we want to get it back later.
	close($fh) ;
	
	return $ret[1] ;
}


sub get {
	my $this = shift ;
	my $fhid = shift ;

	$this->_init_cmd("get$fhid\n") ;
	my @ret = $this->_wrap_up() ;

	return ($ret[0] ? $ret[2] : undef) ;
}


sub del {
	my $this = shift ;
	my $fhid = shift ;

	$this->_init_cmd("del$fhid\n") ;
	my @ret = $this->_wrap_up() ;

	return $ret[0] ;
}


sub cnt {
	my $this = shift ;
	my $fhid = shift ;

	$this->_init_cmd("cnt") ;
	my @ret = $this->_wrap_up() ;

	return $ret[1] ;
}


sub _init_cmd {
	my $this = shift ;
	my $cmd = shift ;

	my $client = $this->{client} ;
	if (! print $client $cmd){
		close($this->{client}) ;
		croak("Error writing command: $!") ; 
	}
}


sub _wrap_up {
	my $this = shift ;

	my $client = $this->{client} ;

	my @ret = eval {
		my $resp_code = $this->_read_resp_code($client) ;

		# print STDERR "[$resp_code $resp_data]\n" ;
		if ($resp_code eq 'okl'){
			my $resp_data = <$client> ;
			chomp($resp_data) ;
			return (1, $resp_data, undef) ;
		}
		elsif ($resp_code eq 'okh'){
			my $resp_fh = recv_fh($client) or die("Error receiving filehandle: $!") ;
			return (1, undef, $resp_fh) ;
		}
		elsif ($resp_code eq 'okn'){
			return (1, undef, undef) ;
		}
		elsif ($resp_code eq 'err'){
			my $resp_data = <$client> ;
			chomp($resp_data) ;
			return (0, $resp_data, undef) ;
		}
		else{
			die("Invalid response code '$resp_code'") ;
		}
	} ;
	if ($@){
		close($this->{client}) ;
		croak($@) ;
	}

	return @ret ;
}


1 ;

