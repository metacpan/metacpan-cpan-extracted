package Device::Opto22;

use 5.008008;
use strict;
use warnings;

require Exporter;

use Device::Opto22::Firewire;

our @ISA = qw( Exporter Device::Opto22::Firewire );


# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = qw( send_PUC get_scratchpadint get_scratchpadfloat get_eu_lst get_digital_lst wr_digital_pnt serial_chat );

our @EXPORT = qw( );

our $VERSION = '0.92';

################################################33
# Opto22 Specific commands
################################################33

our $timeout = 10;

sub new {

    my $class = shift @_;
    my %args = @_;

    my $PeerAddr = $args{PeerAddr} ;
    my $PeerPort = $args{PeerPort} ;

    if (not ($PeerAddr && $PeerPort) )  {
          die "Inputs missing in Package $class in Method new";
    }

    # This establishes a SENDER socket connection OK
    my $self = new Device::Opto22::Firewire (PeerAddr => $PeerAddr ,
                          PeerPort => $PeerPort );

    unless ( $self ) { die "Error connecting in Package $class" ; }

    bless  $self, $class;

    return $self;
}

sub send_PUC {

  my ($self) = @_;

  my $packet = $self->bld_wr_quad_packet(0xf0380000,0x00000001);
  my $rsp    = $self->chat($packet);

  return ($rsp) ;
}

# Does not work... not sure what to send ... 
sub send_MMap_ver {

  my ($self) = @_;

  my $packet = $self->bld_wr_quad_packet(0xf0300000,0x00000000);
  my $rsp    = $self->chat($packet);

  return ($rsp) ;
}

#-------------------------------------------
# Load $len number of elements from the
# ScratchPad Integer Table of the brain's
# memory map
#-------------------------------------------
sub get_scratchpadint {

  my ($self) = shift @_;
  my ($len) = shift @_;   # how many ints to get
  
  my $packet  = $self->bld_rd_blk_packet(0xF0D81000,4*$len);

  my $data    = $self->chat($packet);

  my @lst = big2little_int($data);

  return (@lst) ;

}

#-------------------------------------------
# Load $len number of elements from the
# ScratchPad Float Table of the brain's
# memory map
#-------------------------------------------
sub get_scratchpadfloat {

  my ($self) = shift @_;
  my ($len) = shift @_;   # how many ints to get

  my $packet  = $self->bld_rd_blk_packet(0xF0D82000,4*$len);

  my $data    = $self->chat($packet);

  my @lst = big2little_fp($data);

  return (@lst) ;
}

sub get_eu_lst {

  my ($self) = @_;

  my $packet  = $self->bld_rd_blk_packet(0xf0600000,256);

  my $data    = $self->chat($packet);

  my @lst = big2little_fp($data);

  return (@lst) ;
}

sub get_digital_lst {

  my ($self) = @_;

  my $packet  = $self->bld_rd_blk_packet(0xf0400000,8);

  my $data    = $self->chat($packet);

  # Place 0 or 1 in each element of an array
  my @lst = split // , unpack  "B64" , $data ;

  @lst = reverse @lst ;  # Ain't Perl cool

  return @lst ;
}

sub wr_digital_pnt {

  my ($self) = shift @_;

  my ($channel, $data) = @_;

  # Note: channel is zero based
  my $offset = $channel * 64 ;

  $offset = 0xf0900000 + $offset ;

  # The set/clr byte are next to each other
  if (  not($data)  ) { $offset = $offset + 4 ; }

  my $packet  = $self->bld_wr_quad_packet($offset, "1");

  my $rtn = $self->chat($packet);

  return ($rtn) ;
}


#----------------------------------------------------------
# serial_chat() - sends and rcvs on open Opto serial port
#
# NOTE:  The self object must have opened a socket on
# a port that maps to a particular Opto serial module.
#----------------------------------------------------------
sub serial_chat {

  my ($self) = shift @_;

  my ($data) = @_;

  my $rsp ;

  my $cnt; 
  eval {

     alarm ($timeout) ;

     print $self $data;

     # Wait for data
     select(undef,undef,undef,0.5);

     $cnt = $self->recv($rsp, 30, 0 ) ;

     alarm(0);

  };

  if (not ($cnt)) {
      ${*$self}->{'error_msg'} = "Nothing returned in Serial Chat"; 
       return 0;
  }else{
       return ($rsp) ;
  }
}

#----------------------------------------------------------
# serial_send() - sends to an open Opto serial port
#
# NOTE:  The self object must have opened a socket on
# a port that maps to a particular Opto serial module.
#----------------------------------------------------------
sub serial_send {

  my ($self) = shift @_;

  my ($data) = @_;

  eval {

     alarm ($timeout) ;

     print $self $data;

     alarm(0);

  };

  return(0);
}


#----------------------------------------------------------
# serial_rcv- rcvs on an open Opto serial port
#
# NOTE:  The self object must have opened a socket on
# a port that maps to a particular Opto serial module.
#----------------------------------------------------------
sub serial_rcv {

  my ($self) = shift @_;

  my $rsp ;

  eval {

     alarm ($timeout) ;

     $rsp = <$self>;   # blocks until newline terminated

     alarm(0);

 };

 if($rsp =~ /^\*/){  # all good data starts with a *  (Paroscientific Depth Probe Specific for P3 cmd)

    $rsp =~ s/\*0001(.+)/$1/;    # strip off the *0001 leading address info

    return($rsp);

	}else{
     ${*$self}->{'error_msg'} = "Bad data received in serial_rcv ($rsp)\n$!\n" ;
    return(0);
 }
}


########################
# Private methods
########################

sub big2little_fp {

 my $data = shift @_ ;

 my @lst = () ;

 my $size = length $data ;

 for ( my $j = 0 ; $j < $size ; $j = $j + 4 ) {

   my $quadword = substr $data , $j , 4 ;

   my $reverse_quadword = reverse $quadword ;       # Big to Little Endian

   push @lst, unpack( "f", $reverse_quadword );

 }

return @lst ;

}


sub big2little_int {

 my $data = shift @_ ;

 my @lst = () ;

 my $size = length $data ;

 for (my $j = 0 ; $j < $size ; $j = $j + 4 ) {

   my $quadword = substr $data , $j , 4 ;

   my $reverse_quadword = reverse $quadword ;       # Big to Little Endian

   push @lst, unpack( "l", $reverse_quadword );

 }

return @lst ;

}

1;
__END__

=head1 NAME

Device::Opto22 - Perl Object to communicate with Opto22 Brains via Memory-mapped protocol 

=head1 SYNOPSIS

	use Device::Opto22;
	
	my $brain_ip = '192.168.1.7';
		
	my $sock  = new Device::Opto22( PeerAddr => "$brain_ip",PeerPort => '2001' );
	
	my $rtn = $sock->send_PUC();
	
	# Read Opto22 scratch pad tables
	my $int_table_sz = 15;     # number of entries to read in integer scratch pad table
	my $flt_table_sz = 18;     # number of entries to read in float scratch pad table
	
	my @int_lst = $sock->get_scratchpadint($int_table_sz);
	
	my @flt_lst = $sock->get_scratchpadfloat($flt_table_sz);

=head1 DESCRIPTION

This Module communicates with an Opto22 Brain/Controller via OptoMMP a memory-mapped protocol 
based on the IEEE 1394 standard. This module can be used to create custom software applications 
for remote monitoring, industrial control, and data acquisition using Opto22 modular components.

There is an underlying Firewire.pm module that is used. 

=head1 Methods

Methods include: 

=over

=item  * send_PUC()

Send Power Up Control 

	my $rtn = $sock->send_PUC();

Returns 1 on success and nothing on failure

=item  * get_scratchpadint()

=item  * get_scratchpadfloat()


Get Integer/Float Scratchpads

	my @lst = $sock->get_scractchpading($number_of_items_get);

Returns a list of items requested or nothing on failure	

=item * get_eu_lst()

Get Analog Bank Data in Engineering Units

	my @eu_lst  = $sock->get_eu_lst() 

Returns list of measured engineering unit values in memory map and nothing on failure 	
	

=item * get_digital_lst()

Get Digital Bank Data 

	my @dig_lst = $sock->get_digital_lst()

Returns all list of all 64 digital points. Nothing of failure. 



=item * wr_digital_pnt



Write digital point    

	$sock->wr_digital_pnt($opto_chnl,$turn_on) 

Inputs are channel to effect and a true value for $turn_on  to activate channel or nothing to 
turn channel off. 	



=item * serial_chat(@data)


=item * serial_send($data)

=item * serial_rcv()

    Send and/or Receive data from serial module 

	$sock->serial_send("*0100DB\r\n");     # ask for data in the pressure sensor buffer
	my $engr_value = $sock->serial_rcv();  # rcv buffer data
	
Communicate to the serial device. Note you will have to send \r\n characters if needed. 

=item * error_msg

Get error message on failure 

    unless ( $rtn ) { die $sock->error_msg; } 

=back

Note: The Opto22 Brains are in Big-endian format. The module translates this into common Little-endian format. 
If you are trying this module out on a Big-endian machine you will need to edit the source code as required. 


=head1 SEE ALSO

For more detailed information on Opto22 components and OptoMMP see... 

http://www.opto22.com/documents/1465_OptoMMP_Protocol_Guide.pdf
http://www.opto22.com

http://perlworks.com

=head1 AUTHOR

Written and maintained by: Steve Troxel and Duane Nightingale
(email troxel "at" perlworks.com)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
