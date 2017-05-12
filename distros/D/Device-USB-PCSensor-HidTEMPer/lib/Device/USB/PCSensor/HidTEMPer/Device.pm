package Device::USB::PCSensor::HidTEMPer::Device;

use strict;
use warnings;
use Carp;

=head1

Device::USB::PCSensor::HidTEMPer::Device - Generic device class

=head1 VERSION

Version 0.02

=cut

our $VERSION = 0.02;

=head1 SYNOPSIS

None 

=head1 DESCRIPTION

This module contains a generic class that all HidTEMPer devices should 
inherit from, thereby keeping the implemented methods consistent and making it 
possible to use the same code to contact every supported device.

=head2 CONSTANTS

=over 3

=item * CONNECTION_TIMEOUT

USB communication timeout, specified in milliseconds.

=back
=cut

use constant CONNECTION_TIMEOUT => 60;

=head2 METHODS

=over 3

=item * new( $usb_device )

Creates a new generic Device object.

=cut

sub new
{
    my $class   = shift;
    my ( $usb ) = @_; # Device::USB::Device interface that should be used
    
    # Make sure that this is always a reference to the device.
    $usb = ref $usb 
            ? $usb 
            : \$usb;
    
    my $self    = {
        device  => $usb, 
    };
    
    # Possible sensors
    $self->{sensor} = {
        internal    => undef,
        external    => undef, 
    };
    
    # If the two interfaces are currently in use, detach them and thereby
    # make them available for use.
    $usb->detach_kernel_driver_np(0) if $usb->get_driver_np(0);
    $usb->detach_kernel_driver_np(1) if $usb->get_driver_np(1);
    
    # Opens the device for use by this object.
    croak 'Error opening device' unless $usb->open();
    
    # It is only needed to set the configuration used under a Windows system.
    $usb->set_configuration(1) if $^O eq 'MSWin32';
    
    # Claim the two interfaces for use by this object.
    croak 'Could not claim interface' if $usb->claim_interface(0);
    croak 'Could not claim interface' if $usb->claim_interface(1);
    
    bless $self, $class;
    return $self;    
}

sub DESTROY
{
    my $self    = shift;

    # Delete sensors
    delete $self->{sensor}->{internal};
    delete $self->{sensor}->{external};

    # Release the interfaces back to the operating system.
    $self->{device}->release_interface(0);
    $self->{device}->release_interface(1);

    delete $self->{device};
    
    return undef;
}

=item * identifier()

This method is used to acquire the numerical value representing the device 
type identifier.

=cut

sub identifier
{
    my $self    = shift;
    
    # Command 0x52 will return the following 8 byte result, repeated 4 times.
    # Position 0: unknown
    # Position 1: Device ID
    # Position 2: Calibration value one for the internal sensor
    # Position 3: Calibration value two for the internal sensor
    # Position 4: Calibration value one for the external sensor
    # Position 5: Calibration value two for the external sensor
    # Position 6: unknown
    # Position 7: unknown
    
    my ( undef, $identifier ) = $self->_read( 0x52 );
    return $identifier;
}

# _read( @command_bytes )

# Used to read information from the device. 

# Input parameter
# @command_bytes = Array of 8 bit hex values, maximum of 32 bytes, 
# representing the commands that will be executed by the device.

# Output parameter
# An array of 8 bit hex values or a text string using chars 
# (from 0x00 to 0xFF) to represent the hex values. Returns undef on error.

sub _read
{
    my $self                = shift;
    my ( @bytes )           = @_;
    my ( $data, $checksum ) = ( 0, 0 );
    
    $checksum       += $self->_command(32, 0xA, 0xB, 0xC, 0xD, 0x0, 0x0, 0x2 );
    $checksum       += $self->_command(32, @bytes );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0xA, 0xB, 0xC, 0xD, 0x0, 0x0, 0x1 );
    
    # On error a wrong amount of bytes is returened.
    carp 'The device returned to few bytes'     if $checksum < 320;
    carp 'The device returned to many bytes'    if $checksum > 320;
    return undef if $checksum != 320;
    
    # Send a message to the device, capturing the output into into $data
    $checksum   = $self->{device}->control_msg(
        0xA1,               # Request type
        0x1,                # Request
        0x300,              # Value
        0x1,                # Index
        $data,              # Bytes to be transfeered
        32,                 # Number of bytes to be transferred, more than 32 eq seg fault
        CONNECTION_TIMEOUT  # Timeout
    );
    
    # Ensure that 32 bytes are read from the device.
    carp 'Error reading information from device' if $checksum != 32;
    
    return wantarray ? unpack "C*", $data : $data;
}

# _command( $total_byte_size, @data )

# This method is used to send a command to the device, only used for commands 
# where the output is not needed to be captured.

# Input parameters
# $total_byte_size = The total size that should be sent. Zero padding will be 
# added at the end to achieve specified length.

# @data = An array of 8bit hex values representing the data that 
# should be sent.

# Output parameter
# Returns the number of bytes that where sent to the device if successful 
# execution. This is the same amout of bytes that where specified as input.
# Returns undef on error.

sub _command
{
    my $self                = shift;
    my ( $size, @bytes )    = @_;

    # Convert to char and add zero padding at the end
    my $data    = join '', map{ chr $_ } @bytes;
    $data      .= join '', map{ chr $_ } ( (0)x( $size - $#bytes ) );

    # Send the message to the device
    my $return  = $self->{device}->control_msg(
        0x21,               # Request type
        0x9,                # Request
        0x200,              # Value
        0x1,                # Index
        $data,              # Bytes to be transferred
        $size,              # Number of bytes to be transferred
        CONNECTION_TIMEOUT  # Timeout
    );
    
    # If the device returns correct amount of bytes return count, all OK.
    return $return if $return == $size;
    
    carp 'The device return less bytes than anticipated'    if $return < $size;
    carp 'The device returned more bytes than anticipated'  if $return > $size;
    return undef;
}

# _write( @bytes )

# This method is used to write information back to the device. Be carefull 
# when using this, since any wrong information sent may destroy the device.

# Input parameter
# @bytes = The bytes that should be written to the device, a maximum of 
# 32 bytes.

# Output parameter
# Returns the number of bytes that where sent to the device if successful 
# execution. This should be 288 if everything is successful.

sub _write
{
    my $self                = shift;
    my ( @bytes )           = @_;
    my ( $data, $checksum ) = ( 0, 0 );

    # Filter out possible actions
    return undef if $bytes[0] > 0x68 || $bytes[0] < 0x61;

    $checksum       += $self->_command(32, 0xA, 0xB, 0xC, 0xD, 0x0, 0x0, 0x2 );
    $checksum       += $self->_command(32, @bytes );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );
    $checksum       += $self->_command(32, 0x0 );

    # On error a wrong amount of bytes is returened.
    carp 'The device returned to few bytes'     if $checksum < 288;
    carp 'The device returned to many bytes'    if $checksum > 288;
    return undef if $checksum != 288;

    return $checksum;
}

=item * internal()

Returns the corresponding Sensor object representing the internal sensor 
connected to the device. If the device does not have an internal sensor undef 
is returned.

=cut

sub internal
{
    return $_[0]->{sensor}->{internal};
}

=item * external()

Returns the corresponding Sensor object representing the external sensor 
connected to the device. If the device does not have an external sensor undef 
is returned.

=cut

sub external
{
    return $_[0]->{sensor}->{external};
}

=item * init()

Empty method that should be implemented in order to be able to initialize 
a object instance.

=cut

sub init
{ 
    return undef; 
}

=back

=head1 DEPENDENCIES

This module internally includes and takes use of the following packages:

  use Carp;
  use Device::USB;
  use Device::USB::Device;

This module uses the strict and warning pragmas. 

=head1 BUGS

Please report any bugs or missing features using the CPAN RT tool.

=head1 FOR MORE INFORMATION

None

=head1 AUTHOR

Magnus Sulland < msulland@cpan.org >

=head1 ACKNOWLEDGEMENTS

None

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2011 Magnus Sulland

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
