package File::FDkeeper::Server ;
@ISA = qw(File::FDkeeper) ;

use strict ;
use File::FDpasser ;
use File::FDkeeper ;
use Digest::MD5 qw(md5_hex) ;
use IO::Select ;
use Carp ;


sub new {
	my $class = shift ;
	my $path = shift ;
	my %args = @_ ;

	my $this = {} ;
	$this->{path} = $path ;
	$this->{timeout} = delete $args{AccessTimeout} || undef ;
	$this->{timeout_check} = delete $args{AccessTimeoutCheck} || undef ;
	bless($this, $class) ;

	while (my ($k, $v) = each %args){
		croak("Invalid attribute '$k'") ;
	}

	if (-e $path){
		croak("Can't unlink '$path': $!") unless unlink($path) ;
	}
	my $server = endp_create($path) ;
	croak("Error creating server endpoint '$path': $!") unless $server ;

	$this->{server} = $server ;
	$this->{next_fhid} = 1 ;
	$this->{locker} = {} ;

	return $this ;
}


sub DESTROY {
	my $this = shift ;

	close($this->{server}) unless ! defined($this->{server}) ;
}


sub run {
	my $this = shift ;
	my $llfh = shift ;

	my $select = new IO::Select($this->{server}) ;
	# Add the lifeline filehandle
	$select->add($llfh) if $llfh ;

	while (1){
		my @ready = $select->can_read($this->{timeout_check}) ;
		foreach my $fh (@ready){
			if (($llfh)&&($fh eq $llfh)){
				# The lifeline is broken, so we die also.
				CORE::exit(0) ;
			}
			elsif ($fh eq $this->{server}){
				my $client = serv_accept_fh($fh) ;
				next if ! defined($client) ;
				$client->autoflush(1) ;
				$select->add($client) ;
			}
			else {
				my @resp = () ;
				eval {
					my $cmd = $this->_read_command($fh) ;
					if (! defined($cmd)){
						$select->remove($fh) ;
						no warnings ;
						next ;
					}

					if ($cmd eq 'put'){
						my $recvd_fh = recv_fh($fh) or die("Error receiving filehandle: $!") ;
						my $fhid = $this->put($recvd_fh) ;
						@resp = (1, $fhid, undef) ;
					}
					elsif ($cmd eq 'get'){
						my $fhid = <$fh> ;
						chomp($fhid) ;
						my $sent_fh = $this->get($fhid) ;
						@resp = ($sent_fh ? 
							(1, '', $sent_fh) : 
							(0, "Unknown filehandle '$fhid'", undef)) ;
					}
					elsif($cmd eq 'del'){
						my $fhid = <$fh> ;
						chomp($fhid) ;
						@resp = ($this->del($fhid) ? 
							(1, '', undef) : 
							(0, "Unknown filehandle '$fhid'", undef)) ;
					}
					elsif($cmd eq 'cnt'){
						@resp = (1, $this->cnt(), undef) ;
					}
					else {
						@resp = (0, "Invalid command '$cmd'", undef) ;
					}

					my ($resp_code, $resp_data, $resp_fh) = @resp ;
					if (! $resp_code){
						$resp_code = 'err' ;
						$resp_data =~ s/\r?\n/'\n'/g ;
						$resp_data .= "\n" ;
					}
					else {
						if ($resp_fh){
							$resp_code = 'okh' ;
							$resp_data = '' ;
						}
						elsif (defined($resp_data)){
							$resp_code = 'okl' ;
							$resp_data .= "\n" ;
						}
						else {
							$resp_code = 'okn' ;
						}
					}
						
					print $fh "$resp_code$resp_data" or die("Error writing response: $!") ;
					if ($resp_fh){
						send_file($fh, $resp_fh) or die("Error sending filehandle: $!") ;
					}
				} ;
				if ($@){
					carp($@) ;
					$select->remove($fh) ;
					close($fh) ;
				}
			}
		}

		# Delete expired filehandles
		if ((defined($this->{timeout}))&&($this->{timeout} > 0)){
			my $now = time() ;
			foreach my $id (keys %{$this->{locker}}){
				my $atime = $this->{locker}->{$id}->{atime} ;
				if (($now - $atime) > $this->{timeout}){
					$this->del($id) ;
				}
			}
		}
	}
}


sub get_fh_id {
	my $this = shift ;
	my $fh = shift ;

	my $fhid = undef ;
	do { $fhid = md5_hex(time() . "$fh" . $this->{next_fhid}) }
		while (exists $this->{locker}->{$fhid}) ;

	return $fhid ;
}


sub put {
	my $this = shift ;
	my $fh = shift ;

	my $fhid = $this->get_fh_id($fh) ;
	$this->{locker}->{$fhid} = {
		fh => $fh,
		atime => time(),
	} ;
	
	return $fhid ;
}


sub get {
	my $this = shift ;
	my $fhid = shift ;

	my $entry = $this->{locker}->{$fhid} ;
	return undef unless $entry ;

	$entry->{atime} = time() ;
	return $entry->{fh} ;
}


sub del {
	my $this = shift ;
	my $fhid = shift ;

	my $entry = delete $this->{locker}->{$fhid} ;
	return 0 unless $entry ;

	# shutdown also closes the same handle in other processes.
	shutdown($entry->{fh}, 2) ;

	return 1 ;
}


sub cnt {
	my $this = shift ;

	return scalar(keys %{$this->{locker}}) ;
}



1 ;
