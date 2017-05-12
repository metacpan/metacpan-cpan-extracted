/* -*- c -*-
  Copyright (C) 2006, 2008, 2011 Rocky Bernstein <rocky@cpan.org>
  See end for license.
*/
%define DOCSTRING 
"This is a wrapper for The CD Input and Control library (libcdio) which
encapsulates CD-ROM reading and control. Python programs wishing to be
oblivious of the OS- and device-dependent properties of a CD-ROM can
use this library."
%enddef
%module(docstring=DOCSTRING) perlcdio
%{
/* Includes the header in the wrapper code */
#include <cdio/cdio.h>
#include <cdio/audio.h>
#include <cdio/cd_types.h>
#include <cdio/iso9660.h>
%}

#include <cdio/cdio.h> 
#include <cdio/audio.h>

%include "typemaps.i"
/*%include "cstring.i"*/

/* Various libcdio constants and typedefs */
%include "types.swg"

%feature("autodoc", 1);

%include "audio.swg"
%include "read.swg"
%include "track.swg"

/* In the presence of the exception handling, the order is important. 
   The below use %exception.
*/
%include "device.swg"
%include "disc.swg"

/* Encapsulation is done in two parts. The lower-level Perl interface
is called perlcdio (this file) and is generated via SWIG.

The more object-oriented module is Device::Cdio; it is a Perl class
that uses perlcdio. Although perlcdio is perfectly usable on its own,
it is expected that cdio is what most people will use. As pycdio more
closely models the C interface, it is conceivable (if unlikely) that
diehard libcdio C users who are very familiar with that interface
could prefer that.

It is probably possible to change the SWIG in such a way to combine
these pieces. However there are the problems. First, I'm not that much
of a SWIG expert. Second it looks as though the resulting SWIG code
would be more complex. Third the separation makes translation very
straight forward to understand and maintain: first get what's in C
into Python as a one-to-one translation. Then we implement some nice
abstraction off of that. The abstraction can be modified without
having to redo the underlying translation. (But the reverse is
generally not true: usually changes to the C-to-python translation,
pycdio, do result in small, but obvious and straightforward changes to
the abstraction layer cdio.)
*/

%feature("autodoc",
"Returns the libcdio version string, i.e. the library Device::Cdio
is currently using.");
%inline %{
const char * cdio_version()
{
    return cdio_version_string;
}
%}


%perlcode %{
import Device::Cdio::VERSION;
$VERSION = $Device::Cdio::VERSION;
use strict;
=pod

=head1 NAME

perlcdio - lower-level wrapper to libcdio, the CD Input and Control library

=head1 SYNOPSIS

This is fairly straight-forward wrapper around the C library libcdio.
Although this is perfectly usable on its own, it is expected that the
Object-Oriented interface L<Device::Cdio> is what most people will
want to use. 

There are various constants that are defined here.

=head1 DESCRIPTION

Encapsulation is done in two parts. The lower-level Perl
interface is called perlcdio (this file) and is generated via SWIG.

=head1 CONSTANTS

=head2 Driver ID's 

=over 4

=item DRIVER_UNKNOWN

Use when you don't know what kind of driver and you don't care if it
is an CD image driver or a real CD-ROM driver. See also DRIVER_DEVICE
which doesn't include image drivers.

=item DRIVER_AIX

Driver for IBM's AIX.

=item DRIVER_BSDI

Driver for BSDI. 

=item DRIVER_FREEBSD

Driver for Free BSD

=item DRIVER_LINUX

Driver for GNU/LINUX 

=item DRIVER_SOLARIS

Driver for Solaris 

=item DRIVER_OSX

Driver for Apple's OS X.

=item DRIVER_WIN32

Driver for Microsoft Windows

=item DRIVER_CDRDAO

Image Driver for cdrdao

=item DRIVER_BINCUE

Image driver for CDRWin BIN/CUE 

=item DRIVER_NRG

Image driver for Nero NRG

=item DRIVER_DEVICE

Use when you don't know what kind of driver but the driver must be a
real CD-ROM driver. See also DRIVER_UNKNOWN which includes image
drivers.

=back 

Real OS driver numbers come before image-disc drivers. Here are
constants that can be used in iteration.

=over 4

=item MIN_DRIVER

Smallest image or OS driver number.

=item MIN_DEVICE_DRIVER

Smallest OS device driver number.

=item MAX_DRIVER

Largest image or OS device driver number.

=item MAX_DEVICE_DRIVER

Largest device driver number.

=back 


=head2 Driver Return codes 

May driver operations return a status code. 

=over 4 

=item DRIVER_OP_SUCCESS

Driver operation was successful

=item DRIVER_OP_ERROR

Driver operation had an error of some sort

=item DRIVER_OP_UNSUPPORTED

Operation is not supported for this driver. For example
ejecting a CD from an image driver.

=item DRIVER_OP_UNINIT

Source is not initialized for this operation. 

=item DRIVER_OP_NOT_PERMITTED

Operation is not permitted 

=item DRIVER_OP_BAD_PARAMETER

An invalid parameter was passed to the routine

=item DRIVER_OP_BAD_POINTER

A pointer somehow got corrupted.

=item DRIVER_OP_NO_DRIVER 

No driver has been set.

=back

=head2 Device Capabilities

=head3 Miscellaneous 

=over 4

=item DRIVE_CAP_ERROR

=item DRIVE_CAP_UNKNOWN

=item DRIVE_CAP_MISC_CLOSE_TRAY

=item DRIVE_CAP_MISC_EJECT

=item DRIVE_CAP_MISC_LOCK	

=item DRIVE_CAP_MISC_SELECT_SPEED

=item DRIVE_CAP_MISC_SELECT_DISC

=item DRIVE_CAP_MISC_MULTI_SESSION

=item DRIVE_CAP_MISC_MEDIA_CHANGED

=item DRIVE_CAP_MISC_RESET

=item DRIVE_CAP_MISC_FILE

=back 

=head3 Read Capabilities

=over 4

=item DRIVE_CAP_READ_AUDIO

=item DRIVE_CAP_READ_CD_DA

=item DRIVE_CAP_READ_CD_G

=item DRIVE_CAP_READ_CD_R

=item DRIVE_CAP_READ_CD_RW

=item DRIVE_CAP_READ_DVD_R

=item DRIVE_CAP_READ_DVD_PR

=item DRIVE_CAP_READ_DVD_RAM

=item DRIVE_CAP_READ_DVD_ROM

=item DRIVE_CAP_READ_DVD_RW

=item DRIVE_CAP_READ_DVD_RPW

=item DRIVE_CAP_READ_C2_ERRS

=item DRIVE_CAP_READ_MODE2_FORM1

=item DRIVE_CAP_READ_MODE2_FORM2

=item DRIVE_CAP_READ_MCN

=item DRIVE_CAP_READ_ISRC

=back

=head2 Writing masks

=over 4 

=item DRIVE_CAP_WRITE_CD_R

=item DRIVE_CAP_WRITE_CD_RW

=item DRIVE_CAP_WRITE_DVD_R

=item DRIVE_CAP_WRITE_DVD_PR

=item DRIVE_CAP_WRITE_DVD_RAM

=item DRIVE_CAP_WRITE_DVD_RW 

=item DRIVE_CAP_WRITE_DVD_RPW

=item DRIVE_CAP_WRITE_MT_RAINIER

=item DRIVE_CAP_WRITE_BURN_PROOF

=back 

=head3 Derived Capabilities

=over 4

=item DRIVE_CAP_WRITE_CD

Has some sort of CD writer ability 

=item DRIVE_CAP_WRITE_DVD

Has some sort of DVD writer ability 

=item DRIVE_CAP_WRITE

Has some sort of writer ability 

=back

=head2 Filesystem type constants

These constants are used in getting drive capabilities:

=over 4

=item FS_AUDIO

audio only - not really a filesystem

=item FS_HIGH_SIERRA

High-Sierra Filesystem

=item FS_ISO_9660

ISO-9660 filesystem

=item FS_INTERACTIVE

=item FS_HFS

file system used on the Macintosh system in MacOS 6 through MacOS 9
and deprecated in OSX

=item FS_UFS

Generic Unix file system derived from the Berkeley fast file 
system.

=item FS_EXT2

EXT2 was the GNU/Linux native filesystem for early kernels. Newer
GNU/Linux OS's may use EXT3 which EXT2 with a journal. 

=item FS_ISO_HFS

both HFS & ISO-9660 filesystem 

=item FS_ISO_9660_INTERACTIVE

both CD-RTOS and ISO filesystem

=item FS_3DO

The 3DO is, technically, a set of specifications created by the 3DO
company.  These specs are for making a 3DO Interactive Multiplayer
which uses a CD-player. Panasonic in the early 90's was the first
company to manufacture and market a 3DO player.

=item FS_XISO

Microsoft X-BOX CD

=item FS_UDFX

=item FS_UDF

=item FS_ISO_UDF

=item FS_ANAL_XA

eXtended Architecture format

=item FS_ANAL_MULTISESSION

CD has multisesion

=item FS_ANAL_PHOTO_CD

Is a Kodak Photo CD

=item FS_ANAL_HIDDEN_TRACK

Hidden track at the beginning the CD

=item FS_ANAL_CDTV

=item FS_ANAL_BOOTABLE

CD is bootable

=item FS_ANAL_VIDEOCD

VCD 1.1

=item FS_ANAL_ROCKRIDGE

Has Rock Ridge Extensions to ISO 9660

=item FS_ANAL_JOLIET

Microsoft Joliet extensions to ISO 9660

=item FS_ANAL_SVCD

Super VCD or Choiji Video CD

=item FS_ANAL_CVD

Choiji Video CD

=item FS_ANAL_XISO

XBOX CD determined by some analysis

=item FS_MATCH_ALL

bitmask which can  be used to specify matching any sort of CD

=back

=head2 Sector size constants

=over 4 

=item CD_FRAMESIZE 

=item CD_FRAMESIZE_RAW 

Size of a Philip Red book CD-DA block. It is also the maximum CD sector 
size possible: 2352 bytes.

=item ISO_BLOCKSIZE

Size of an ISO 9660 block. Also the size of the data portion in CD data 
reads: 2048 bytes.

=item M2F2_SECTOR_SIZE 

Mode 2 Form 2 Data size: 2328 bytes.

=item M2RAW_SECTOR_SIZE

Mod1 Form 1 Data size: 2336 bytes.

=back 

=head2 Reading Modes

=over 4

=item READ_MODE_AUDIO 

audio mode (CD-DA) read. Blocksize is a multiple of
$perlcdio::CD_FRAMESIZE_RAW (2352) bytes.

=item READ_MODE_M1F1  

Mode 1 Form 1 read. Blocksize is a multiple of $perlcdio::CD_FRAMESIZE
(2048) bytes.

=item READ_MODE_M1F2  

Mode 1 Form 2 read. Blocksize is a multiple of $perlcdio::M2RAW_SECTIOR_SIZE
(2336) bytes.

=item READ_MODE_M2F1  

Mode 2 Form 1 read. Blocksize is a multiple of $perlcdio::CD_FRAMESIZE
(2048) bytes.

=item READ_MODE_M2F2  

Mode 2 Form 1 read. Blocksize is a multiple of (2328) bytes.

=back

=head2 Miscellaneous 

=over 4 

=item VERSION_NUM

libcdio version that is getting used

=item INVALID_LBA 

Canonical value used for an invalid LBA.

=item INVALID_LSN

Canonical value used for an invalid LSN.

=item INVALID_TRACK

Canonical value used for an invalid track number. (Valid range 
is 0 to 99.)

=item LEADOUT_TRACK

Canonical value for the "leadout" or track just after the last track. So 
again this value is outside the range 0 to 99.
The leadout track is often used to get the last LSN or LBA. The libcdio
routines also allow the last actual track plus one as a synonym for the
leadout track.

=back 

=head1 METHODS

=head2 cdio_version

    perlcdio::cdio_version

Returns the libcdio version string Device::Cdio is currently linked with.

=head2 this

This seems to be an artifact of SWIG. 

=head1 SEE ALSO

L<http://www.gnu.org/software/libcdio> has documentation on
libcdio including the a manual and the API via doxygen.

=head1 AUTHORS

Rocky Bernstein C<< <rocky at cpan.org> >>.

=head1 COPYRIGHT

Copyright (C) 2006, 2008, 2011 Rocky Bernstein <rocky@cpan.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
%}
