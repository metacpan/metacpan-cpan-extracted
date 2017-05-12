package File::FDkeeper ;

use strict ;
use IO::Handle ;
use Carp ;


$File::FDkeeper::VERSION = '0.06' ;


sub new {
	my $class = shift ;
	my %args = @_ ;

	my $this = undef ;
	if ($args{'Local'}){
		# server mode
		my $path = delete $args{'Local'} ;
		require File::FDkeeper::Server ;
		$this = new File::FDkeeper::Server($path, %args) ;
	}
	elsif ($args{'Peer'}){
		# client mode
		my $path = delete $args{'Peer'} ;
		require File::FDkeeper::Client ;
		$this = new File::FDkeeper::Client($path, %args) ;
	}
	else {
		croak("You must specify either 'Local' or 'Peer' when creating an instance of File::FDkeeper") ;
	}

	return $this ;
}


sub _read_resp_code {
	my $this = shift ;
	my $h = shift ;

	return _read_n_from($h, 3, 1) ;
}


sub _read_command {
	my $this = shift ;
	my $h = shift ;

	return _read_n_from($h, 3, 0) ;
}


sub _read_n_from {
	my $h = shift ;
	my $len = shift ;
	my $hard = shift ;

	my $buf = '' ;
	my $left = $len ;
	while ($left > 0){
		my $b = _read_from($h, $left) ;
		if (! defined($b)){
			if (($left > $len)||($hard)){
				croak("Unexpected EOF ($left bytes missing)") ;
			}
			else {
				# Nothing read yet...
				return undef ;
			}
		}

		$buf .= $b ;
		$left -= length($b) ;
	}

	return $buf ;
}


sub _read_from {
    my $h = shift ;
    my $bufsize = shift ;

    my $buf = '' ;
    my $res = $h->sysread($buf, $bufsize) ;
    if ($res < 0){
        croak("I/O Error: $!") ;
    }
    elsif ($res == 0){
        return undef ;
    }
    else {
        return $buf ;
    }
}



1 ;
