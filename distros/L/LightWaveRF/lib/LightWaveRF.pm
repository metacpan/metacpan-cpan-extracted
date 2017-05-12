package LightWaveRF;

=head1 NAME
 
LightWaveRF - Integration with LightWaveRF modules
 
=head1 SYNOPSIS
 
 use LightWaveRF;
 my $lw = new LightWaveRF;
 $lw->register('D1', 'R1', "LivingRoom");
 $lw->on('LivingRoom');
 
=head1 DESCRIPTION
 
Provides an interface to LightWaveRF modules via the LightWaveRF Wifi Link.

=cut

=head2 Methods

=head3 new

	my $lf = new LightWaveRF;

    Instantiates a LightWaveRF object ready to register devices against.

=cut


use Moose;
use IO::Socket::INET;
use IO::Select;

our $VERSION = 0.04;

has '_devices' => (is => 'rw', default => sub{{}});
has '_current_msg_id' => (is => 'rw', default => 0 );
has '_port' => (is => 'ro', default => 9760);

=head3 register

	$lw->register(<NODE ID>, <DEVICE ID>, <NAME>);
	$lw->register('R1', 'LivingRoomLight');

=cut
sub register {
	my ( $self, $node_id, $device_id, $name ) = @_;
	
	$self->_devices->{$name} = {node => $node_id, id => $device_id};
}

=head3 on
	
	$lw->on('LivingRoomLight'); # $lw->send_device_status('LivingRoomlight', 'F1');

=cut
sub on {
	my ( $self, $name ) = @_;
	return $self->send_device_status($name, 'F1'); 
}

=head3 off
	
	$lw->on('LivingRoomLight'); # $lw->send_device_status('LivingRoomlight', 'F0');

=cut
sub off {
	my ( $self, $name ) = @_;
	return $self->send_device_status($name, 'F0');
}


=head3 send_device_status

	$lw->send_device_status('LivingRoomlight', 'F1');

=cut
sub send_device_status {
	my ( $self, $name, $status ) = @_;
	my $device = $self->_devices->{$name};

	return undef unless $device;

	$self->_send_status($device->{'node'}, $device->{'id'}, $status);

	return 1;
}

sub get_next_msg_id {
	my $self = shift;

	$self->_current_msg_id(0) if($self->_current_msg_id) >= 999;
	my $msg_id = $self->_current_msg_id($self->_current_msg_id+1);
	return $msg_id;
}

#Broadcast a status.
sub _send_status {
	my ( $self, $node, $device_id, $status ) = @_;

	my $broadcast_string = sprintf("%03d", $self->get_next_msg_id ). ",!$device_id$node$status|";

	my $sock = IO::Socket::INET->new(
		PeerPort  => $self->_port,
		PeerAddr  => inet_ntoa(INADDR_BROADCAST),
		Proto     => 'udp',    
		Broadcast => 1 ) 
    or die "Can't bind : $@\n";

    $sock->send($broadcast_string);
}

=head2 get_kwh

returns the current wattage from the power meter

=cut
sub get_kwh {
	#This routine is horrible and completely needs refactoring
	my $self = shift;


	my $sel = IO::Select->new;
	my $in_sock = IO::Socket::INET -> new (LocalPort  => 9761,
                                     Broadcast  =>  1,
                                     Proto      => 'udp')
            or die "Failed to bind to socket: $@";

	$sel->add($in_sock);
	my $timeout = 2;
	my $mess;    


	my $sock = IO::Socket::INET->new(
		PeerPort  => $self->_port,
		PeerAddr  => inet_ntoa(INADDR_BROADCAST),
		Proto     => 'udp',    
		Broadcast => 1 ) 
    or die "Can't bind : $@\n";

    $sock->send("@?W|EcoQuery");


	while (1) { 
   		my @r = $sel->can_read($timeout);
   		unless (@r) { last; } #Tiemout
   		$in_sock -> recv ($mess, 1024);
   		last;
	}

	return unless($mess);
	$mess =~ /W=(\d*)\,(\d*)\,(\d*),(\d*)/;
	my $watts = $1;

	return $watts/1000;

}


=head1 AUTHOR 
 Graeme Lawton <graeme@per.ly>
=cut

=head2 Development

This module is very much under development and not really production ready yet 
and there is lots of functinality still to be added to it. Patches welcome git 
repo is at https://github.com/grim8634/LightWaveRF.git

=cut
1;
