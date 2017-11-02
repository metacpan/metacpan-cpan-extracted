package Device::Cdio::ISO9660::FS;
use Device::Cdio::ISO9660;
require 5.8.6;
#
#  See end for copyright and license.

=pod

=head1 NAME

Device::Cdio::ISO9660::FS - Class for ISO 9660 CD reading

=head1 SYNOPSIS

This encapsulates ISO 9660 Filesystem aspects of CD Tracks.
As such this is a This library
however needs to be used in conjunction with Device::Cdio::ISO9660.

    use Device::Cdio::ISO9660:FS;
    $cd = Device::Cdio::ISO9660::FS->new(-source=>'/dev/cdrom');
    $statbuf = $cd->stat ($iso9660_path.$local_filename);

    $blocks = POSIX::ceil($statbuf->{size} / $perlcdio::ISO_BLOCKSIZE);
    for (my $i = 0; $i < $blocks; $i++) {
        my $buf = $cd->read_data_blocks ($statbuf->{LSN} + $i);
        die if !defined($buf);
    }

    print $buf;

=head1 DESCRIPTION

This is an Object-Oriented interface to the GNU CD Input and Control
library (C<libcdio>) which is written in C. This class handles ISO
9660 tracks on a CD or in a CD-ROM.

Note that working with a CD in a CD-ROM which has tracks in the
ISO-9660 format is distinct working with a I<file> in a filesystem
which contains an ISO-9660 image. See also
L<Device::Cdio::ISO9660::IFS> for working with an ISO 9660 image
stored as a file in a filesystem.

=head2 CALLING ROUTINES

Routines accept named parameters as well as positional parameters.
For named parameters, each argument name is preceded by a dash. For
example:

    Device::Cdio::ISO9660::FS->new(-source=>'MYISO.CUE')

Each argument name is preceded by a dash.  Neither case nor order
matters in the argument list.  -driver_id, -Driver_ID, and -DRIVER_ID
are all acceptable.  In fact, only the first argument needs to begin
with a dash.  If a dash is present in the first argument, we assume
dashes for the subsequent parameters.

In the documentation below and elsewhere in this package the parameter
name that can be used in this style of call is given in the parameter
list. For example, for "close_tray" the documentation below reads:

   close_tray(drive=undef, driver_id=$perlcdio::DRIVER_UNKNOWN)
    -> ($drc, $driver_id)

So the parameter names are "drive", and "driver_id". Neither parameter
is required. If "drive" is not specified, a value of "undef" will be
used. And if "driver_id" is not specified, a value of
$perlcdio::DRIVER_UNKNOWN is used.

The older, more traditional style of positional parameters is also
supported. So the "new" example from above can also be written:

    Device::Cdio::ISO9660::FS->new('MYISO.CUE')

Finally, since no parameter name can be confused with a an integer,
negative values will not get confused as a named parameter.

=cut

$revision = '$Id$';

$Device::Cdio::ISO9660::FS::VERSION = $Device::Cdio::VERSION;

use warnings;
use strict;
use Exporter;
use perliso9660;
use Carp;

use vars qw($VERSION $revision @EXPORT_OK @EXPORT @ISA %drivers);
use Device::Cdio::Util qw( _check_arg_count _extra_args _rearrange );


@ISA = qw(Exporter Device::Cdio::Device);
@EXPORT_OK  = qw( close open );

=pod

=head2 find_lsn

  find_lsn(lsn)->$stat_href

Find the filesystem entry that contains LSN and return information
about it. Undef is returned on error.

=cut

sub find_lsn {
    my($self,@p) = @_;
    my($lsn, @args) = _rearrange(['LSN'], @p);
    return undef if _extra_args(@args);

    if (!defined($lsn)) {
      print "*** An LSN parameter must be given\n";
      return undef;
    }

    my @values = perliso9660::fs_find_lsn($self->{cd}, $lsn);

    # Remove the two input parameters
    splice(@values, 0, 2) if @values > 2;

    return Device::Cdio::ISO9660::stat_array_to_href(@values);
}

=pod

=head2 readdir

  readdir(dirname)->@iso_stat

Read path (a directory) and return a list of iso9660 stat references

Each item of @iso_stat is a hash reference which contains

=over 4

=item LSN

the Logical sector number (an integer)

=item size

the total size of the file in bytes

=item  sec_size

the number of sectors allocated

=item  filename

the file name of the statbuf entry

=item XA

if the file has XA attributes; 0 if not

=item is_dir

1 if a directory; 0 if a not;

=back

FIXME: If you look at iso9660.h you'll see more fields, such as for
Rock-Ridge specific fields or XA specific fields. Eventually these
will be added. Volunteers?

=cut

sub readdir {
    my($self,@p) = @_;

    my($dirname, @args) = _rearrange(['DIRNAME'], @p);
    return undef if _extra_args(@args);

    if (!defined($dirname)) {
      print "*** A directory name must be given\n";
      return undef;
    }

    my @values = perliso9660::fs_readdir($self->{cd}, $dirname);

    # Remove the two input parameters
    splice(@values, 0, 2) if @values > 2;

    my @result = ();
    while (@values) {
	push @result, Device::Cdio::ISO9660::stat_array_to_href(@values);
	splice(@values, 0, 14);
    }
    return @result;
}

=pod

=head2 read_pvd

  read_pvd()->pvd

Read the Super block of an ISO 9660 image. This is the Primary Volume
Descriptor (PVD) and perhaps a Supplemental Volume Descriptor if
(Joliet) extensions are acceptable.

=cut

sub read_pvd {
    my($self,@p) = @_;
    return 0 if !_check_arg_count($#_, 0);

    # FIXME call new on PVD object
    return perliso9660::fs_read_pvd($self->{cd});
}

=pod

=head2 read_superblock

  read_superblock(iso_mask=$libiso9660::EXTENSION_NONE)->bool

Read the Super block of an ISO 9660 image. This is the rimary Volume
Descriptor (PVD) and perhaps a Supplemental Volume Descriptor if
(Joliet) extensions are acceptable.

=cut

sub read_superblock {
    my($self,@p) = @_;
    my($iso_mask) = _rearrange(['ISO_MASK'], @p);

    $iso_mask = $perliso9660::EXTENSION_NONE if !defined($iso_mask);

    return perliso9660::fs_read_superblock($self->{cd}, $iso_mask);
}

=pod

=head2 stat

  stat(path, translate=0)->\%stat

Return file status for path name psz_path. NULL is returned on error.

If translate is 1,  version numbers in the ISO 9660 name are dropped, i.e. ;1
is removed and if level 1 ISO-9660 names are lowercased.

Each item of @iso_stat is a hash reference which contains

=over 4

=item LSN

the Logical sector number (an integer)

=item size

the total size of the file in bytes

=item  sec_size

the number of sectors allocated

=item  filename

the file name of the statbuf entry

=item XA

if the file has XA attributes; 0 if not

=item is_dir

1 if a directory; 0 if a not;

=back

=cut

sub stat {
    my($self, @p) = @_;
    my($path, $translate, @args) =
	_rearrange(['PATH', 'TRANSLATE'], @p);

    return undef if _extra_args(@args);
    $translate = 0 if !defined($translate);

    if (!defined($path)) {
      print "*** An CD-ROM or CD-image must be given\n";
      return undef;
    }

    my @values;
    if ($translate) {
	@values = perliso9660::fs_stat_translate($self->{cd}, $path);
    } else {
	@values = perliso9660::fs_stat($self->{cd}, $path);
    }

    # Remove the input parameters
    splice(@values, 0, 2) if @values > 2;

    return undef if !@values;
    return Device::Cdio::ISO9660::stat_array_to_href(@values);
}

1; # Magic true value requred at the end of a module

__END__

=pod

=head1 SEE ALSO

This is a subclass of Device::Cdio::Device. See also
L<Device::Cdio::Device>. See
L<Device::Cdio::ISO9660::IFS> for working with ISO 9660
images.

L<perliso9660> is the lower-level interface to C<libiso9660>,
the ISO 9660 library of C<libcdio>.

L<http://www.gnu.org/software/libcdio/doxygen/iso9660_8h.html> is
documentation via doxygen of C<libiso9660>.
doxygen.

=head1 AUTHORS

Rocky Bernstein

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2008, 2017 Rocky Bernstein <rocky@cpan.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<The GNU General Public
License|http://www.gnu.org/licenses/#GPL>.

=cut
