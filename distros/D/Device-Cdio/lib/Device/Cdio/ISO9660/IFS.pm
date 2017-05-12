package Device::Cdio::ISO9660::IFS;
require 5.8.6;
#
#  $Id$
#  See end for copyright and license.

=pod

=head1 NAME

Device::Cdio::ISO9660::IFS - Class for ISO 9660 Filesystem image reading

=head1 SYNOPSIS

This encapsulates ISO 9660 Filesystem Image handling. The class is
often used in conjunction with Device::Cdio::ISO9660.

    use Device::Cdio::ISO9660;
    use Device::Cdio::ISO9660::IFS;

    $iso = Device::Cdio::ISO9660::IFS->new(-source=>'copying.iso');
    $id = $iso->get_application_id();
    @file_stats = $iso->readdir($path);
    foreach my $href (@file_stats) {    
       printf "%s [LSN %6d] %8d %s%s\n", 
       $href->{is_dir} ? "d" : "-",
       $href->{LSN}, $href->{size},
       $path,
        Device::Cdio::ISO9660::name_translate($href->{filename});
    }

=head1 DESCRIPTION

This is an Object-Oriented interface to the GNU CD Input and Control
library (C<libcdio>) which is written in C. This class handles ISO
9660 aspects of an ISO 9600 image. 

An ISO-9660 image is distinct from a CD in a CD-ROM which has ISO-9660
tracks; the latter contains other CD-like information (e.g. tracks,
information or assocated with the CD). An ISO-9660 filesystem image on
the other hand doesn't and is generally file in some file system,
sometimes with the file extension ".iso"; perhaps it can be burned
into a CD with a suitable tool, perhaps is can be "mounted" as a
filesystem on some OS's.

=head2 CALLING ROUTINES

Routines accept named parameters as well as positional parameters.
For named parameters, each argument name is preceded by a dash. For
example:

    Device::Cdio::ISO9660::IFS->new(-source=>'MYISO.ISO')

Each argument name is preceded by a dash.  Neither case nor order
matters in the argument list.  -driver_id, -Driver_ID, and -DRIVER_ID
are all acceptable.  In fact, only the first argument needs to begin
with a dash.  If a dash is present in the first argument, we assume
dashes for the subsequent parameters.

In the documentation below and elsewhere in this package the parameter
name that can be used in this style of call is given in the parameter
list. For example, for "open" the documentation below reads:

   open(source, iso_mask=$pyiso9660::EXTENSION_NONE)->bool

So the parameters are "source", and "is_mask". The iso_mask parameter
is not required and if not specified a value of
$perliso9660:EXTENSION_NON will be used.

The older, more traditional style of positional parameters is also
supported. So the "have_driver example from above can also be written:

    Cdio::open($s, $i)

Finally, since no parameter name can be confused with an integer,
negative values will not get confused as a named parameter.

=cut

$revision = '$Id$';

$Device::Cdio::ISO9660::IFS::VERSION = $Device::Cdio::VERSION;

use warnings;
use strict;
use Exporter;
use perliso9660;
use perlcdio;
use Carp;

use vars qw($VERSION $revision @EXPORT_OK @EXPORT @ISA %drivers);
use Device::Cdio::Util qw( _check_arg_count _extra_args _rearrange );


@ISA = qw(Exporter);
@EXPORT     = qw( new );
@EXPORT_OK  = qw( close open );

# Note: the keys below match those the names returned by
# cdio_get_driver_name()

=pod

=head1 METHODS

=head2 new

  new(source, iso_mask)->$iso9660_object

Create a new ISO 9660 object. Source or iso_mask is optional. 

If source is given, open() is called using that and the optional iso_mask
parameter; iso_mask is used only if source is specified.
If source is given but opening fails, undef is returned.
If source is not given, an object is always returned.

=cut

sub new {

  my($class,@p) = @_;

  my($source, $iso_mask, @args) = 
      _rearrange(['SOURCE', 'ISO_MASK'], @p);

  return undef if _extra_args(@args);
  $iso_mask = $perliso9660::EXTENSION_NONE if !defined($iso_mask);

  my $self = {};
  $self->{iso9660} = undef;

  bless ($self, $class);

  if (defined($source)) {
      return undef if !$self->open($source, $iso_mask);
  }

  return $self;
}

	
=pod

=head2 close

  close()->bool

Close previously opened ISO 9660 image and free resources associated
with ISO9660.  Call this when done using using an ISO 9660 image.

=cut

sub close {
    my($self,@p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    if (defined($self->{iso9660})) {
	return perliso9660::close($self->{iso9660});
    } else {
	print "***No object to close\n";
        $self->{iso9660} = undef;
	return 0;
    }
}

=pod 

=head2 find_lsn

  find_lsn(lsn)->$stat_href

Find the filesystem entry that contains LSN and return file stat
information about it. C<undef> is returned on error.

=cut

sub find_lsn {
    my($self,@p) = @_;
    my($lsn, @args) = _rearrange(['LSN'], @p);
    return undef if _extra_args(@args);

    if (!defined($lsn)) {
      print "*** An LSN paramater must be given\n";
      return undef;
    }

    if ($perlcdio::VERSION_NUM <= 76) {
	print "*** Routine available only in libcdio versions >= 0.76\n";
	return undef;
    }
    my @values = perliso9660::ifs_find_lsn($self->{iso9660}, $lsn);
    return Device::Cdio::ISO9660::stat_array_to_href(@values);
}

=pod

=head2 get_application_id

  get_application_id()->$id

Get the application ID stored in the Primary Volume Descriptor.
undef is returned if there is some problem.

=cut

sub get_application_id {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);

    return perliso9660::ifs_get_application_id($self->{iso9660});
}

=pod

=head2 get_preparer_id

  get_preparer_id()->$id

Get the preparer ID stored in the Primary Volume Descriptor.
undef is returned if there is some problem.

=cut

sub get_preparer_id {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);

    return perliso9660::ifs_get_preparer_id($self->{iso9660});
}

=pod

=head2 get_publisher_id

  get_publisher_id()->$id

Get the publisher ID stored in the Primary Volume Descriptor.
undef is returned if there is some problem.

=cut

sub get_publisher_id {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);

    return perliso9660::ifs_get_publisher_id($self->{iso9660});
}

=pod

=head2 get_root_lsn

  get_root_lsn()->$lsn

Get the Root LSN stored in the Primary Volume Descriptor.
undef is returned if there is some problem.

=cut

sub get_root_lsn {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);

    return perliso9660::ifs_get_root_lsn($self->{iso9660});
}

=pod

=head2 get_system_id

  get_system_id()->$id

Get the Volume ID stored in the Primary Volume Descriptor.
undef is returned if there is some problem.

=cut

sub get_system_id {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);

    return perliso9660::ifs_get_system_id($self->{iso9660});
}

=pod

=head2 get_volume_id

  get_volume_id()->$id

Get the Volume ID stored in the Primary Volume Descriptor.
undef is returned if there is some problem.

=cut

sub get_volume_id {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);

    return perliso9660::ifs_get_volume_id($self->{iso9660});
}

=pod

=head2 get_volumeset_id

  get_volume_id()->$id

Get the Volume ID stored in the Primary Volume Descriptor.
undef is returned if there is some problem.

=cut

sub get_volumeset_id {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);

    return perliso9660::ifs_get_volumeset_id($self->{iso9660});
}

=pod

=head2 open

  open(source, iso_mask=$perliso9660::EXTENSION_NONE)->bool

Open an ISO 9660 image for reading. Subsequent operations will read
from this ISO 9660 image.

This should be called before using any other routine except possibly
new. It is implicitly called when a new is done specifying a source.

If device object was previously opened it is closed first.

See also open_fuzzy.

=cut

sub open {
    my($self,@p) = @_;
    my($source, $iso_mask) = 
	_rearrange(['SOURCE', 'ISO_MASK'], @p);
    
    $self->close() if defined($self->{iso9660});
    $iso_mask = $perliso9660::EXTENSION_NONE if !defined($iso_mask);
    if (!defined($source)) {
      print "*** An ISO-9660 file image must be given\n";
      return 0;
    }
    $self->{iso9660} = perliso9660::open_ext($source, $iso_mask);
    return defined($self->{iso9660});
}

=pod

=head2 open_fuzzy

open_fuzzy(source, iso_mask=$perliso9660::EXTENSION_NONE, fuzz=20)->bool

Open an ISO 9660 image for reading. Subsequent operations will read
from this ISO 9660 image. Some tolerence allowed for positioning the
ISO9660 image. We scan for $perliso9660::STANDARD_ID and use that to
set the eventual offset to adjust by (as long as that is <= $fuzz).

This should be called before using any other routine except possibly
new (which must be called first. It is implicitly called when a new is
done specifying a source.

See also open.

=cut

sub open_fuzzy {
    my($self,@p) = @_;
    my($source, $iso_mask, $fuzz) = 
	_rearrange(['SOURCE', 'ISO_MASK', 'FUZZ'], @p);
    
    $self->close() if defined($self->{iso9660});
    $iso_mask = $perliso9660::EXTENSION_NONE if !defined($iso_mask);

    if (!defined($fuzz)) {
	$fuzz = 20;
    } elsif ($fuzz !~ m{\A\d+\Z}) {
	print "*** Expecting fuzz to be an integer; got '$fuzz'\n";
	return 0;
    }

    $self->{iso9660} = perliso9660::open_fuzzy_ext($source, $iso_mask, $fuzz);
    return defined($self->{iso9660});
}

=pod

=head2 read_fuzzy_superblock

read_fuzzy_superblock(iso_mask=$perliso9660::EXTENSION_NONE, fuzz=20)->bool

Read the Super block of an ISO 9660 image but determine framesize
and datastart and a possible additional offset. Generally here we are
not reading an ISO 9660 image but a CD-Image which contains an ISO 9660
filesystem.

=cut

sub read_fuzzy_superblock {
    my($self,@p) = @_;
    my($iso_mask, $fuzz) = 
	_rearrange(['ISO_MASK', 'FUZZ'], @p);
    
    $iso_mask = $perliso9660::EXTENSION_NONE if !defined($iso_mask);

    if (!defined($fuzz)) {
	$fuzz = 20;
    } elsif ($fuzz !~ m{\A\d+\Z}) {
	print "*** Expecting fuzz to be an integer; got '$fuzz'\n";
	return 0;
    }

    return perliso9660::ifs_fuzzy_read_superblock($self->{iso9660},
						  $iso_mask, $fuzz);
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

    my @values = perliso9660::ifs_readdir($self->{iso9660}, $dirname);

    # Remove the two input parameters
    splice(@values, 0, 2) if @values > 2;

    my @result = ();
    while (@values) {
	push @result, Device::Cdio::ISO9660::stat_array_to_href(@values);
	splice(@values, 0, 5);
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
    return perliso9660::ifs_read_pvd($self->{iso9660});
}

=pod

=head2 read_superblock

  read_superblock(iso_mask=$perliso9660::EXTENSION_NONE)->bool

Read the Super block of an ISO 9660 image. This is the Primary Volume
Descriptor (PVD) and perhaps a Supplemental Volume Descriptor if
(Joliet) extensions are acceptable.

=cut

sub read_superblock {
    my($self,@p) = @_;
    my($iso_mask) = _rearrange(['ISO_MASK'], @p);
    
    $iso_mask = $perliso9660::EXTENSION_NONE if !defined($iso_mask);

    return perliso9660::ifs_read_superblock($self->{iso9660}, $iso_mask);
}

=pod 

=head2 seek_read

seek_read(start, size=1)->(size, str)

Seek to a position and then read n bytes. Size read is returned.

=cut

sub seek_read {
    my($self,@p) = @_;
    my($start, $size, @args) = _rearrange(['START', 'SIZE'], @p);
    return undef if _extra_args(@args);

    $size = 1 if !defined($size);
    
    (my $data, $size) = perliso9660::seek_read($self->{iso9660}, $start, 
					       $size);
    return wantarray ? ($data, $size) : $data;
}

=pod

=head2 stat

stat(path, translate=0)->\%stat

Return file status for path name psz_path. C<undef> is returned on error.

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

1 if a directory; 0 if a not.

=back

=cut

sub stat {
    my($self, @p) = @_;
    my($path, $translate, @args) = _rearrange(['PATH', 'TRANSLATE'], @p);
    
    return undef if _extra_args(@args);
    $translate = 0 if !defined($translate);

    if (!defined($path)) {
      print "*** An ISO-9660 file path must be given\n";
      return undef;
    }

    my @values;
    if ($translate) {
	@values = perliso9660::ifs_stat_translate($self->{iso9660}, $path);
    } else {
	@values = perliso9660::ifs_stat($self->{iso9660}, $path);
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

See also L<Device::Cdio> for module information, L<Device::Cdio::ISO9660::FS>
and L<Device::Cdio::Device> for device objects and
L<Device::Cdio::Track> for track objects.

L<perliso9660> is the lower-level interface to C<libiso9660>, 
the ISO 9660 library of L<http://www.gnu.org/software/libcdio>.

L<http://www.gnu.org/software/libcdio/doxygen/iso9660_8h.html> is 
documentation via doxygen of C<libiso9660>.
doxygen.

=head1 AUTHORS

Rocky Bernstein C<< <rocky at cpan.org> >>.

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2008 Rocky Bernstein <rocky@cpan.org>

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
