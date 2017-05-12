package Device::Video::PWC;

use strict;
use warnings;

our $VERSION = '0.11';

use XSLoader;
XSLoader::load('Device::Video::PWC', $VERSION);
#=======================================================================
sub new {
	my ($class, $device) = @_;
	
	my $self = bless { device => $device }, $class;
	
	$self->set_device( $device || q[/dev/video0] );
	
	return $self;
}
#=======================================================================
sub set_pan {
	my ($self, $val) = @_;
	
	$self->set_pan_or_tilt( 0,  $val );
	
	return;
}
#=======================================================================
sub set_tilt {
	my ($self, $val) = @_;
	
	$self->set_pan_or_tilt( 1,  $val );
	
	return;
}
#=======================================================================
sub set_framerate {
	my ($self, $val) = @_;
	
	$self->set_dimensions_and_framerate( 0, 0, $val );
	
	return;
}
#=======================================================================
sub red_balance {
	my( $self, $val ) = @_;
	
	$self->set_automatic_white_balance_mode_red( $val );
}
#=======================================================================
sub blue_balance {
	my( $self, $val ) = @_;
	
	$self->set_automatic_white_balance_mode_blue( $val );
}
#=======================================================================
sub reset_pan {
	my ($self) = @_;
	
	$self->reset_pan_tilt( 0 );
}
#=======================================================================
sub reset_tilt {
	my ($self) = @_;
	
	$self->reset_pan_tilt( 1 );
}
#=======================================================================
1;
   
__END__

=head1 NAME

Device::Video::PWC


=head1 SYNOPSIS

	use Device::Video::PWC;
	
	my $cam = Device::Video::PWC->new( '/dev/video0' );
	$cam->set_pan (  3000 );
	$cam->set_tilt( -1000 );
	$cam->set_framerate( 15 );
	$cam->set electronic sharpness( 35000 );
	$cam->dump_current_settings;
	$cam->restore_factory_settings;

=head1 DESCRIPTION

This module is an adaptation of source code of C<setpwm> program. With 
this tool, you can set settings specific to the Philips WebCams.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new( '/path/to/video/device' )>

Constructor. The parameter is a path to a video device. Default value is
set to C</dev/video0>.

=item B<set_device( '/path/to/video/device' )>

This method allows to change used device.

=item B<dump_current_settings()>

Dump current settings.

=item B<set_framerate( $framerate )>

Set framerate. Parameter $framerate has to be in a range 0 - 63.

=item B<set_dimensions_and_framerate( $width, $height, $framerate)>

Set dimensions and framerate. All parameters must be set. Framerate has 
to be in a range 0 - 63.

=item B<flash_settings()>

Store settings in nonvolatile RAM.

=item B<restore_settings()>

Restore settings from nonvolatile RAM.

=item B<restore_factory_settins()>

Restore factory settings.

=item B<set_compression_preference( $val )>

Set compression preference. Value has to be in a range 0 - 3.

=item B<set_automatic_gain_control( $val )>

Set automatic gain control. Value has to be in a range 0 - 65535.

=item B<set_shutter_speed( $val )>

Set shutter speed. Value has to be in a range 1 - 65535.

=item B<set_automatic_white_balance_mode( $val )>

Set automatic white balance mode. Value has to be one of C<auto/manual/indoor/outdoor/fl> .

=item B<red_balance( $val )>

Set red balance (only if white balance mode is set to C<manual>). Value 
has to be in a range 0 - 65535.

=item B<blue_balance( $val )>

Set blue balance (only if white balance mode is set to C<manual>). Value 
has to be in a range 0 - 65535.

=item B<set_automatic_white_balance_speed( $val )>

Set speed of automatic white balance. Value has to be in a range 1 - 65535.

=item B<set_automatic_white_balance_delay( $val )>

Set delay for automatic white balance. Value has to be in a range 1 - 65535.

=item B<set_led_on_time( $val )>

Set led on time in ms. Value has to be in a range 0 - 25500.

=item B<set_led_off_time( $val )>

Set led off-time.

=item B<set_electronic_sharpness( $val )>

Set electronic sharpness. Value has t obe in a range 0 - 65535.

=item B<set_backlight_compensation( $val )>

Set backlight compensation. Possible values are 0 (for off) and 1 (for on).

=item B<set_antiflicker_mode( $val )>

Set antiflicker mode. Possible values are 0 (for off) and 1 (for on).

=item B<set_noise_reduction($val)>

Set noise reduction mode. Possible values are from 0 (none) to 3 (high).

=item B<reset_pan()>

Reset pan.

=item B<reset_tilt()>
	
Reset tilt.

=item B<query_pan_tilt_status()>

Query pan/tilt status.

=item B<set_pan( $val )>

Set pan position.

=item B<set_tilt>

Set tilt position.

=back

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None. I hope. 

=head1 THANKS

=over 4

=item Thanks to Folkert van Heusden <folkert@vanheusden.com>, who is an
author of original source code of C<setpwc>.

=back

=head1 AUTHOR

Strzelecki Lukasz <lukasz@strzeleccy.eu>

=head1 LICENCE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
