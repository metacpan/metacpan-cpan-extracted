package Device::QuickCam;

#Ni!
#Note to Testers

#Yes, know this module will probably not pass any of the tests
#unless you for some odd, mysterious reason do have everything installed
#JUST like it should.

use strict;
use warnings;
use vars qw(@ISA $VERSION);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

$VERSION = '0.02';

#And when I boot it up...
bootstrap Device::QuickCam $VERSION;

#Ekki ekki ekki ekki pikang zoom-boing!

1;
__END__
=head1 NAME

Device::QuickCam - Perl extension for using the Connectix QuickCam

=head1 SYNOPSIS

  use Device::QuickCam;

  my $cam = Device::QuickCam->new();
  $cam->set_quality(50); #Set JPEG Quality in %
  $cam->set_bpp(24); #Set bits per pixel (24 or 32)
  $cam->set_width(320); #Set image width
  $cam->set_height(240); #Set image height
  for(1..10)
  { $cam->set_file("foo-$_.jpg"); #Use filename
    $cam->grab(); #Grab it
  }

=head1 DESCRIPTION

This module allows access to the Connectix/Logitech QuickCam. This module uses libcqcam and expects the user to play around with it. libcqcam isn't installed as library during a default cqcam installation (altho Debian does appear to provide it as a package).

=head1 REQUIREMENTS

You'll need 

=over 4

=item root

Root access or similar permissions to access the port.

=item libcqcam 

libcqcam installed and headers nearby. You will need them while building the C++ code. Location of libcqcam can be found below.

=item libjpeg 

libcqcam and this module output images in JPEG. You will need libjpeg installed.

=item a Connectix/Logitech QuickCam

Well, obviously a QuickCam. These cameras were first manufactured by Connectix. Logitech later bought the company and same webcams were then/now sold under the Logitech brand.
There are FAQs on how to get these cameras working in Linux. (working)

=item Linux

Well, It helps anyway. I have no idea how this might work on other platforms altho libcqcam supports a few.

=back

=head1 FUNCTIONS

=over 4

=item grab()

This function grabs image data, using settings defined beforehand.

=item set_quality(int)

This function can be used to set JPEG Quality. Values range from 0 to 100. Default is 50.

=item set_bpp(int)

This function can be used to set a bits per pixel rate. Valid values are 24 and 32. Default is 24.

=item set_width(int)

This function can be used to set the output image width. Values range from 0 to 640. Default is 320.

=item set_height(int)

This function can be used to set the output image height. Values range from 0 to 480. Default is 240.

=item set_red(int)

This function can be used to set the red level of the output image. Values range from 0 to 255.

=item set_green(int)

This function can be used to set the green level of the output image. Values range from 0 to 255.

=item set_blue(int)

This function can be used to set the blue level of the output image. Values range from 0 to 255.

=item set_decimation(int)

This function can be used to set scaling of the image. Valid values are 1, 2 and 4. Default is 1.

=item set_autoadj(int)

This function can be used to toggle auto adjusting. Set 0 for off, 1 for on. Default is on.

=item set_port(int)

This function can be used to set a camera port. Default value is 0 for autoprobe. Valid values are 0x378, 0x278 and 0x3bc. If unsure, leave this at 0.

=item set_debug(int)

This function allows you to toggle debug info. 0 is off, 1 is on. Default is off.

=item set_file(string)

This functions allows you to set a filename for output. 
By not setting a filename, you force output to STDOUT.

=item set_http(int)

This function allows you to toggle HTTP Support. 0 is off, 1 is on. Default is off.

=back

=head1 NOTES

I included libcqcam in this archive. You need to build this yourself before installing this module.
Go into the libcqcam directory and type : 

make

Then copy libcqcam.a to a directory in which is listed in ld.so.conf (I used /usr/lib) and run ldconfig. Then you should be able to make this module.

=head1 EXPORT

None by default.

=head1 AUTHOR

Hendrik Van Belleghem, E<lt>beatnik - at - quickndirty - dot - orgE<gt>

Based on code by Patrick Reynolds E<lt>reynolds - at - cs - dot - duke - dot - eduE<gt>

=head1 SEE ALSO

L<perl>.

libcqcam, part of cqcam. http://www.cs.duke.edu/~reynolds/cqcam/

=cut
