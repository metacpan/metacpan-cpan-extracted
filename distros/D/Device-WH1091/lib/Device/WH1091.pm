package Device::WH1091;

use Inline C => DATA => LIBS => '-lusb';
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION $VENDOR_ID $PRODUCT_ID $CONFIG_NO $INTERFACE_NO
    				$INTERFACES_NUM $REQTYPE $REQ $VAL $GET_SIZE $TIMEOUT
    				@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS 
    				);
    $VERSION     = '0.03';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
    $VENDOR_ID = 0x1941;
	$PRODUCT_ID = 0x8021;

	$CONFIG_NO = 1;
	$INTERFACE_NO = 0;
	
	$INTERFACES_NUM = 2;

	$REQTYPE = 0xA1;
	
	$REQ = 0x1;
	$VAL = 0x300;
	$GET_SIZE = 8;
	$TIMEOUT = 500;
  

}

sub new                                                                                                       
{                                                                                                             
	my ($class, %parameters) = @_;                                                                        
	my $self = bless ({}, ref ($class) || $class);                                                        
	$self->{'error'} = undef;                                                                             
	$self->{'data'} = undef;                                                                              
	
	return $self;                                                                                         
}                                                                                                             
                                                                                                                                                         

sub error {
	my $self = shift;
	return $self->{'error'};
}


sub DESTROY {
	my $self = shift;

	if($self->{'dev'}) {
		$self->{'dev'}->release_interface($INTERFACE_NO);
	
	}
}


sub getdata {
	
	my $self = shift;
	
	my $buffer2;
	my $current={};
	my @dir = ['N','NNE','NE','ENE','E','SEE','SE','SSE','S','SSW','SW','WSW','W','WNW','NW','NNW'];
	    
	getweather($buffer2);
	
	$self->{tindoor} = (get_bufferval($buffer2,242,243)) / 10 ;
	$self->{toutdoor} = (get_bufferval($buffer2, 245, 246) ) / 10;
	$self->{hindoor} = get_bufferval($buffer2, 241);
	$self->{houtdoor} = get_bufferval($buffer2, 244);
	$self->{windspeed} = get_bufferval($buffer2, 249)/10;
	$self->{windgust} = get_bufferval($buffer2, 250)/10;
	$self->{winddir} = get_bufferval($buffer2, 252) * 22.5;
	$self->{winddirtext} = $dir[$self->{winddir}];  
	$self->{pressure} = get_bufferval($buffer2, 247, 248)/10;
	$self->{raintot} = get_bufferval($buffer2,253,254) * 3 / 10;
	return 1;	
	
}




sub get_bufferval {
	
	my $buffer = shift;
	my $byte1 = shift;
	my $byte2 = shift;
	
	
	my $ret = ord(substr($buffer,$byte1,1));
	if( defined $byte2 ) {
		$ret = $ret + ord(substr($buffer,$byte2,1)) *256;
	}
	return $ret;
}






=head1 NAME

Device::WH1091 - Access data from the WH1081/1091 weather station.

=head1 SYNOPSIS

  use Device::WH1091;
  my $weather=Device::WH1091->new();
  
  $weather->getdata();
  
  
  my $tindoor = $weather->{tindoor}; 		# Indoor Temp
  my $toutdoor = $weather->{toutdoor}; 		# Outdoor Temp
  my $hindoor = $weather->{hindoor};		# Indoor Humidity
  $houtdoor = $weather->{houtdoor};			# OutDoor Humidity
  $windspeed = $weather->{windspeed};		# WindSpeed (m/s)
  $windgust = $weather->{windgust};			# Wind Gust (m/s)
  $winddir = $weather->{winddir};			# Wind Direction Degrees
  $winddirtext = $weather->{winddirtext};	# Wind Direction Text
  $pressure = $weather->{pressure};			# Air Pressure
  $raintot = $weather->{raintot};			# Total Rain

=head1 DESCRIPTION

Provides an interface to the WH1081/WH1091 weather stations (and others based on the same hardware).

Requires libusb to be installed so essentially limited at this stage to Linux/Unix platforms that have libusb.
Currently, the usb code is inlined C, however this will bechanging to Perl USB at some stage so that this platform dependency is removed.


=head1 USAGE

Instatiate an instance by call WH1091->new();

Whenever you want data, call getdata() and the object variables mention in the SYNOPSIS will be populated.
When you want more data, call getdata() again.

Be aware that the usb weather station only gets wireless updates from the weather head every 30 seconds, so polling more often than that would be pointless. 

=head1 BUGS

I am still not 100% confident with the rain data. Your mileage may vary. 

I have had this running a continuous loop getting data on an NSLU2 with openwrt for over three months now.

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

perl(1).

=cut

#################### main pod documentation end ###################


1;




__DATA__    

__C__

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <signal.h>
#include <ctype.h>
#include <usb.h>

struct usb_dev_handle *devh;
int	ret,mempos=0,showall=0,shownone=0,resetws=0,pdebug=0,postprocess=0;
int	o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12,o13,o14,o15;
char	buf[1000],*endptr;
char	buf2[400];
int other=0, i=0;

void _close_readw() {
    ret = usb_release_interface(devh, 0);
    if (ret!=0) printf("could not release interface: %d\n", ret);
    ret = usb_close(devh);
    if (ret!=0) printf("Error closing interface: %d\n", ret);
}

struct usb_device *find_device(int vendor, int product) {
    struct usb_bus *bus;
    
    for (bus = usb_get_busses(); bus; bus = bus->next) {
	struct usb_device *dev;
	
	for (dev = bus->devices; dev; dev = dev->next) {
	    if (dev->descriptor.idVendor == vendor && dev->descriptor.idProduct == product)
			return dev;
		}
    }
    return NULL;
}


void _open_readw() {
    struct usb_device *dev;
    int vendor, product;

    usb_init();

    usb_find_busses();
    usb_find_devices();

    vendor = 0x1941;
    product = 0x8021; 

    dev = find_device(vendor, product);
    assert(dev);
    devh = usb_open(dev);
    assert(devh);
    signal(SIGTERM, _close_readw);
    ret = usb_get_driver_np(devh, 0, buf, sizeof(buf));
    if (ret == 0) {
		ret = usb_detach_kernel_driver_np(devh, 0);
    }
    ret = usb_claim_interface(devh, 0);
    if (ret != 0) {
		printf("Could not open usb device, errorcode - %d\n", ret);
		exit(1);
    }
    ret = usb_set_altinterface(devh, 0);
    assert(ret >= 0);
}


void _init_wread() {
	char tbuf[1000];
	ret = usb_get_descriptor(devh, 1, 0, tbuf, 0x12);

	ret = usb_get_descriptor(devh, 2, 0, tbuf, 9);

	ret = usb_get_descriptor(devh, 2, 0, tbuf, 0x22);

	ret = usb_release_interface(devh, 0);
	if (ret != 0) printf("failed to release interface before set_configuration: %d\n", ret);
	ret = usb_set_configuration(devh, 1);
	ret = usb_claim_interface(devh, 0);
	if (ret != 0) printf("claim after set_configuration failed with error %d\n", ret);
	ret = usb_set_altinterface(devh, 0);

	ret = usb_control_msg(devh, USB_TYPE_CLASS + USB_RECIP_INTERFACE, 0xa, 0, 0, tbuf, 0, 1000);

	ret = usb_get_descriptor(devh, 0x22, 0, tbuf, 0x74);
}

void _send_usb_msg( char msg1[1],char msg2[1],char msg3[1],char msg4[1],char msg5[1],char msg6[1],char msg7[1],char msg8[1] ) {
	char tbuf[1000];
	tbuf[0] = msg1[0];
	tbuf[1] = msg2[0];
	tbuf[2] = msg3[0];
	tbuf[3] = msg4[0];
	tbuf[4] = msg5[0];
	tbuf[5] = msg6[0];
	tbuf[6] = msg7[0];
	tbuf[7] = msg8[0];

	ret = usb_control_msg(devh, USB_TYPE_CLASS + USB_RECIP_INTERFACE, 9, 0x200, 0, tbuf, 8, 1000);

}

void _read_usb_msg(char *buffer) {
   char tbuf[1000];
   usb_interrupt_read(devh, 0x81, tbuf, 0x20, 1000);
   memcpy(buffer, tbuf, 0x20);

}



int getweather(SV* buffer2) {
    
    int	buftemp;
    char ec='n';
    
	_open_readw();
  	_init_wread();

	// Read 0-31
  	_send_usb_msg("\xa1","\x00","\x00","\x20","\xa1","\x00","\x00","\x20");
  	_read_usb_msg(buf2);
	// Read next 31
	_send_usb_msg("\xa1","\x00","\x20","\x20","\xa1","\x00","\x20","\x20");
	_read_usb_msg(buf2+32);
	_send_usb_msg("\xa1","\x00","\x40","\x20","\xa1","\x00","\x40","\x20");
	_read_usb_msg(buf2+64);
	_send_usb_msg("\xa1","\x00","\x60","\x20","\xa1","\x00","\x60","\x20");
	_read_usb_msg(buf2+96);
  	_send_usb_msg("\xa1","\x00","\x80","\x20","\xa1","\x00","\x80","\x20");
  	_read_usb_msg(buf2+128);
  	_send_usb_msg("\xa1","\x00","\xa0","\x20","\xa1","\x00","\xa0","\x20");
  	_read_usb_msg(buf2+160);
  	_send_usb_msg("\xa1","\x00","\xc0","\x20","\xa1","\x00","\xc0","\x20");
  	_read_usb_msg(buf2+192);
  	_send_usb_msg("\xa1","\x00","\xe0","\x20","\xa1","\x00","\xe0","\x20");
 	_read_usb_msg(buf2+224);
   
   	// Get History Start Address
	int offset;
	offset = (unsigned char) buf2[30] + ( 256 * buf2[31] );
   
   	if (mempos!=0) offset = mempos;
   	
   	buftemp = 0;
	if (offset!=0) buftemp = offset - 0x10;
	
	buf[1] = ( buftemp >>8 & 0xFF ) ;
	buf[2] = buftemp & 0xFF;
	buf[3] = ( buftemp >>8 & 0xFF ) ;
	buf[4] = buftemp & 0xFF;
	
	_send_usb_msg("\xa1",buf+1,buf+2,"\x20","\xa1",buf+3,buf+4,"\x20");
	_read_usb_msg(buf2+224);
	
	ret = usb_control_msg(devh, USB_TYPE_CLASS + USB_RECIP_INTERFACE, 0x0000009, 0x0000200, 0x0000000, buf, 0x0000008, 1000);
	ret = usb_interrupt_read(devh, 0x00000081, buf, 0x0000020, 1000);
	memcpy(buf2+256, buf, 0x0000020);
	
	_close_readw();
		
	sv_setpvn(buffer2,buf2,1000);
	return 0;
}


__END__



