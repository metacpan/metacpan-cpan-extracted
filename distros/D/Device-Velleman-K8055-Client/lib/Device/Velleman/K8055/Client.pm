package Device::Velleman::K8055::Client;

use IPC::ShareLite qw( :lock );
use Time::HiRes qw(usleep);
use strict;
use Data::Dumper;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $share $clientnum $count $gotok $clientnum);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


sub new
{
    my ($class, %parameters) = @_;

    $SIG{INT} = 'Device::Velleman::K8055::Client::destroy';
	my $self = {};

	$self->{'error'} = undef;
	$self->{'data'} = undef;
	$self->{'clientno'} = undef;

	bless($self, $class);

	
	$clientnum = IPC::ShareLite->new(
	        -key     => 8055,
	        -create  => 'no',
	        -destroy => 'no',
	        -exclusive => 'no'
	) or die $!;
	
	
	$clientnum->lock( LOCK_EX );
	my $clientno = $clientnum->fetch();
	$clientnum->store($clientno+1);
	$clientnum->unlock();
	
	
	sleep 1;
	print $clientno . "\n";
	$share = IPC::ShareLite->new(
	        -key     => 8057 + $clientno,
	        -create  => 'no',
	        -destroy => 'no',
	        -exclusive => 'no'
	) or die $!;

	
	$count = 0;
	$gotok = 0;

	$self->{clientno} = $clientno;
	
	return $self;
}

sub sendserver {
	
	
	my $cmd = shift;
	my $fetch;
	my @data;
	$gotok=0;
	
	
	while($gotok ==0 ) {
		if($share->fetch eq "" ) {
			
			
			$share->store( $cmd );
		

			$share->unlock();
			
			$gotok=0;
			while( $gotok == 0){

				while(!$share->lock(LOCK_EX)) {
					usleep(5000);
				}
				$fetch = $share->fetch;
				@data = split(/:/, $share->fetch );
				$cmd = $data[0];				
				if($cmd eq "OK") {
	
						
					$share->store("");
					$gotok = 1;
					usleep 1000;
				}
				$share->unlock();
			}
		} else {
			$share->unlock();
		}
		
	}
	$share->unlock();
	
	return $fetch;
}
	

sub sendcmd (@){
	
	my $send = shift;
		
	while ( @_ > 0 ) {
		my $arg = shift;
		$send = $send . ":" . $arg;	
	}
	
	my $fetch = sendserver($send);
	return split /:/, $fetch;
}


sub ReadAnalogChannel {
	shift;
	
	my @ret = sendcmd("ReadAnalogChannel",$_[0]);
	return $ret[1];
	
}

sub ClearDigitalChannel {
	
	shift;
	usleep 1000;
	return sendcmd("ClearDigitalChannel",$_[0]);
	
}

sub SetDigitalChannel {
	
	shift;
	
	return sendcmd("SetDigitalChannel",$_[0]);
	
}

sub destroy {
	print "\nDisconnecting\n";
	$share->store("DIE");
	$share="";
	exit $@;
}

=head1 NAME

Device::Velleman::K8055::Client - Client for connecting to K8055::Server

=head1 SYNOPSIS

  use Device::Velleman::K8055::Client;
  my $k8055 = Device::Velleman::K8055::Client->new();
  .
  $k8055->SetDigitalChannel(8);
  $volts = $k8055->ReadAnalogChannel(1) * 0.086;
  print "$volts\n";
  .
  .
  $k8055->destroy();
  

=head1 DESCRIPTION

Connects to Device::Velleman::K8055::Server via IPCS and sends commands for the Server to 
execute on the K8055 board.
  
Handles multiple clients connecting at the same time and ensures only one command gets sent to the 
physical board at a time.
  

=head1 METHODS

=head2 new()

Create a new instance of the Client. Sets up a shared memory connection to the server. 

=head2 ReadAnalogChannel($channel) 

Read the analog channel specified by channel.

Returns the value read from the channel. 

=head2 ClearDigitalChannel($channel)

Set the digital channel $channel to 0 or low.

=head2 SetDigitalChannel($channel) 

Set the digital channel($channel to 1 or high.

=head2 destroy 

Kill the client connection and tell the server to free any shared memory we have.

=head1 BUGS

 Does NOT ensure that two different processes arent using the same digital or 
 analog i/o's at the same time.
 
 Not all functions of the K8055 (reading the digital inputs or talking to the pwm)
 are implemented yet.
 
 You need to be careful at which speed you talk to the board as it has 10us resolution.
 Any quicker than this and you will get wierd results.

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

Device::Velleman::K8055::Server, Device::Velleman::K8055::libk8055, perl(1).

=cut

#################### main pod documentation end ###################




1;


