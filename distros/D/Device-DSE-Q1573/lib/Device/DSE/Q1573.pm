package Device::DSE::Q1573;

use DynaLoader;


use Device::SerialPort qw(:STAT);
use POSIX qw(:termios_h);
use Fcntl;

use strict;


BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $PortObj);
    $VERSION     = '0.7';
    @ISA         = qw(Exporter DynaLoader);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
    bootstrap Device::DSE::Q1573, $VERSION;
}



#################### subroutine header begin ####################

# Create Instance

#################### subroutine header end ####################


sub new
{
    my ($class, $serialport) = @_;

    
    
    
    my $self = bless ({}, ref ($class) || $class);
	
	$self->{serialport} = $serialport;

    return $self;
}
#################### subroutine header begin ####################

#Read meter

#################### subroutine header end ####################

sub rawread {
	
	my $self = shift;
		
	my $readval;
	terminal($self->{serialport}, $readval);
	return $readval;
}




#################### main pod documentation begin ###################



=head1 NAME

Device::DSE::Q1573 - Read data from DSE Q1573 Digital Multimeter

=head1 SYNOPSIS

  use Device::DSE::Q1573;
  my $meter = Device::DSE::Q1573->new("/dev/ttyS0");
  my $reading = $meter->read();
  my $reading = $meter->rawread();


=head1 DESCRIPTION

Sets up a connection to a DSE Q1573 or Metex ME-22 
Digital Multimeter, and allows you to read measurements
from it. The data return is 14 bytes of the format:

Type:Data:Units
eg  reading when temperature is selected on the meter
will return 

"TE  0019    C "   

=head1 USAGE

=head2 new(serialport)

 Usage     : my $meter=Device::DSE::Q1573->new("/dev/ttyS0")
 Purpose   : Opens the meter on the specified serial port
 Returns   : object of type Device::DSE::Q1573
 Argument  : serial port
 
=head2 rawread();

 Usage     : my $meter->rawread()
 Purpose   : Returns the 14 byte string from the meter.

=head2 read();

 Usage     : my $meter->read()
 Purpose   : Returns a hash of values for the reading:
 
 				{ 
 					setting => setting eg TE for temperature
 					value => value read eg 14
 					units => units read eg C for celsius 
 					
 				}
 
 
=head1 EXAMPLE

use Device::DSE::Q1573;

my $meter = Device::DSE::Q1573->new( "/dev/ttyS0" );

while(1) {
	my $data = $meter->read();
	print $data->{value} . "\n";
	sleep(1);
}


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


