package Device::Serdisp;

use 5.006001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Serdisp ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.06';

require XSLoader;
XSLoader::load('Device::Serdisp', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Device::Serdisp - Perl extension for talking to the serdisplib

=head1 SYNOPSIS

    use Device::Serdisp;

    my $d = Device::Serdisp->new('USB:7c0/1501', 'ctinclud');
    $d->init();
    $d->clear();

    # reserves a color-indexed picture
    my $image = GD::Image->new(128,64);
    my $black = $image->colorAllocate(0,0,0);
    my $white = $image->colorAllocate(255,255,255);

    $image->transparent($black);
    $image->arc(10,10,10,10,0,270, $white);
    $d->copyGD($image);

=head1 DESCRIPTION

This library is a quick interface to serdisplib.

=head1 PUBLIC INTERFACE

=over 4

=item C<$d = Device::Serdisp-E<gt>new(connection,displaytype)>

This will open the serdisp library for you. The first string
is connector string that describes the kind of interface
your are using to talk to your display:

Examples:

   /dev/parport0 - parallel port
   0x378 - direct IO
   USB:7c0/1501 - USB device with the given product id
   ...

The second is the type of the display.

Examples:

   ctinclud
   PCD8544
   ...

=cut

=item C<$d-E<gt>init()>

This will init the display and turn it on. The the display can't
found with your specified parameter the method will croak.

=item C<$d-E<gt>width()>

Returns the width of the display in pixel.

=item C<$d-E<gt>copyGD(GD)>

This will copy your given GD object into the buffer of the serdisp library.
After that the display will be updated to display the content of the internal
buffer. All non-black pixels (red >0 || green > 0 || blue > 0) will be translated
to a set pixel on the display.
No dithering at all!

If you GD area is bigger than your display the rest of the GD area will be ignored.

If you GD area is lesser than your display the rest of the display area will be untouched.

=item C<$d-E<gt>clear()>

Will clear the internal buffer of the serdisp library and force an update
of the display.

=item C<$d-E<gt>set_option(OPTION, VALUE)>

Will set an option for the display. Valid values for OPTION
depends on the type of your display and may vary.

Example:

   $d->set_option("INVERT","1");

=item C<$d-E<gt>get_option(OPTION)>

This will return the current value of the display.

=head2 EXPORT

None by default.

=head1 SEE ALSO

   GD - http://www.boutell.com/gd/
   GD - perldoc GD
   Serdisplib - http://serdisplib.sourceforge.net/

=head1 AUTHOR

Erik Wasser, E<lt>erik.wasser@iquer.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Erik Wasser

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
