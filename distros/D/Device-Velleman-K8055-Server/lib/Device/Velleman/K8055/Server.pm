package Device::Velleman::K8055::Server;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %share %server $maxclientnum $clientnum $ipc);
    $VERSION     = '0.03';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
    
	$SIG{INT} = 'Device::Velleman::K8055::Server::cleanup';
	$SIG{KILL} = 'Device::Velleman::K8055::Server::cleanup';
	
}

use IPC::ShareLite qw( :lock );
use Tie::ShareLite qw( :lock );
use Time::HiRes qw(usleep);
use Data::Dumper;
use Device::Velleman::K8055::libk8055;


sub new
{
    my ($class, %parameters) = @_;

	my $self={ 'error' => undef,
			'data' => undef,
			maxclientum => 0,
			share => undef,
	};
	
	
	bless( $self, $class);
	
	$clientnum = IPC::ShareLite->new(
        -key     => 8055,
        -create  => 'yes',
        -destroy => 'yes',
        -exclusive => 'no'
	) or die $!;
	
	$clientnum->store("0");

	die ("K8055 OpenDevice failed") unless (OpenDevice($port) == 0);

	
	
	$ipc = tie %server, 'Tie::ShareLite', -key     => 8056,
                                        -mode    => 0666,
                                        -create  => 'yes',
                                        -destroy => 'no'
    or die("Could not tie to shared memory: $!");

	ClearAllDigital();
	


	return $self
    
    
}


sub create_segment($ $) {
	
	my $self = shift;
	my $clientno = shift;
	
	$self->{share}->{$clientno} = IPC::ShareLite->new(
        -key     => 8057 + $clientno,
        -create  => 'yes',
        -destroy => 'yes',
        -exclusive => 'no'
	) or die $!;
	
}





sub run {
	
	my $self = shift;
	
	
		
	while( 1 == 1) {
		
			check_for_client($self);
			
			
			my $cmd="";
			my $str="";
			my $clientno="";
			my $client;			
			my $share=$self->{share};
						
			
			foreach $client (sort keys %$share ) {

				my @data = split(/:/, $share->{$client}->fetch );
				$fetch=$data[0];
				
				if( !($fetch eq "" or $fetch eq "OK" ) ) { 
					
					$share->{$client}->lock( LOCK_EX );
					if( $fetch ne "DIE" ) {
						$str = $share->{$client}->fetch;
						my @data = split(/:/,$str);
						my $cmd = shift @data;
						print $cmd . "(" . $data[0], ")"	. "\n";
						$retval = &$cmd(@data);
						$share->{$client}->store("OK:$retval");
						$share->{$client}->unlock();
					} else {
						disconnect($self, $client);
					}
					

				}
			}
			usleep 5000;
	}
}



sub check_for_client ($) {
			
		my $self = shift;
		
		my $share = $self->{share};
		
		if( $clientnum->fetch > $maxclientnum ) {
			$maxclientnum = $clientnum->fetch;
			
			create_segment($self,$maxclientnum-1);
			
			print "Clientno $maxclientnum attached with key->" . $self->{share}->{$maxclientnum-1}->key . ". \n";
			
				
		}
			
}


sub cleanup {
	my $self = shift;
	my $share = $self;
	print "Cleaning up Shared Memory\n";
	$clientnum="";
	$ipc="";
	$server="";
	
	foreach my $client ( sort keys %$share ) {
		$self->{share}->{$client}="";
	}
	exit(1);
}


sub disconnect {
	
	my $self = shift;
	my $client = shift;
	
	print "Client $client disconnected.\n";
	$self->{share}->{$client}->destroy();	
	delete $self->{share}->{$client};
	
}

############################################################################
#
#
#
############################################################################



=head1 NAME

Device::Velleman::K8055::Server - IPCS Server for the K8055 Device

=head1 SYNOPSIS

  use Device::Velleman::K8055::Server;
  
  my $server = Device::Velleman::K8055::Server->new();


=head1 DESCRIPTION

Sets up a server that handles all communication with the K8055 device. Communicates with clients through shared memory.

=head1 USAGE

Example of a daemon that initiates the server:

	use Device::Velleman::K8055::Server;
	use Proc::Daemon;
	use Tie::Hash;
	
	$SIG{HUP} = 'shutdown';
	
	
	foreach my $argnum (0 .. $#ARGV) {
	
		if( $ARGV[$argnum] eq '--debug' ) {
			$debug=1;
		}
		if( $ARGV[$argnum] eq '--nodaemon' ) {
			$nodaemon=1;
		}
		
		if( $ARGV[$argnum] eq '--server' ) {
			$server=1;
		}
		
	}
	
	
	if($server) {
		print "Running Server\n";
		server();
	}
	
	
	sub server {
		#Run as Daemon unless -nodaemon passed.
		unless( $nodaemon ) {
			print "Running as daemon.\n";
			Proc::Daemon::Init;
		}
		my $server = K8055::Server->new();
		$server->run;
	}
	
	
	
	sub shutdown {
		$server->cleanup();
		exit;
	}


=head1 BUGS

Many.

=head1 SUPPORT



=head1 AUTHOR

    David Peters
    CPAN ID: DAVIDP
    davidp@electronf.com
    http://www.electronf.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Device::Velleman::K8055::Client, Device::Velleman::libk8055, perl(1).

=cut

#################### main pod documentation end ###################


1;


