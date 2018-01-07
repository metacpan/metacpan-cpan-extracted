package Device::Cdio::Track;
require 5.8.6;
#
#  See end for copyright and license.

### CD Input and control track class

=pod

=head1 NAME

Device::Cdio::Track - Class for track aspects of Device::Cdio.

=head1 SYNOPSIS

    use Device::Cdio::Device;
    use Device::Cdio::Track;

    $device = Device::Cdio::Device->new(-source=>'/dev/cdrom');
    $track  = $device->get_last_track();
    print "track: %d, last lsn: %d\n", $track->{track}, track->get_last_lsn();

    $track = $device->get_first_track();
    $format = $rackt->get_format();

=cut

use strict;
use Exporter;
use perlcdio;
use perlmmc;
use Device::Cdio::Util qw(_rearrange _check_arg_count _extra_args);
use Device::Cdio;
use Device::Cdio::Device;

$Device::Cdio::Device::VERSION = $Device::Cdio::VERSION;

=pod

=head1 METHODS

=cut

=pod

=head2 new

  new(device, track)->object

Creates a new track object.

=cut

sub new {

  my($class,@p) = @_;

  my($device, $track, @args) = _rearrange(['DEVICE', 'TRACK'], @p);

  return undef if _extra_args(@args);

  my $self = {};

  if ($track !~ m{\A\d+\Z}) {
      print "*** Expecting track to be an integer; got '$track'\n";
      return undef;
  } elsif ($track < 0 || $track > 200) {
      print "*** Track number should be within 0 and 200; got '$track'\n";
      return undef;
  }

  $self->{track}  = $track;

  # See if the device parameter is a reference (a device object) or
  # a device name of which we will turn into a device object.
  if (ref($device)) {
      $self->{device} = $device;
  } else {
      $self->{device} = Device::Cdio::Device->new(-source=>$device);
  }

  bless ($self, $class);


  return $self;
}

=pod

=head2 get_audio_channels

  get_audio_channels(cdio, track)->int

Return number of channels in track: 2 or 4.
Not meaningful if track is not an audio track.
-1 is returned on error and -2 if the driver doesn't support the
operation.

=cut

sub get_audio_channels {

    my($self,@p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    return perlcdio::get_track_channels($self->{device}, $self->{track});
}

=pod

=head2 get_copy_permit

  get_copy_permit(cdio, track)->int

Return copy protection status on a track. Is this meaningful
not an audio track?

=cut

sub get_copy_permit {
    my ($self, @p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    return perlcdio::get_track_copy_permit($self->{device}, $self->{track});
}

sub get_cdtext {
    my($self, @p) = @_;
    return perlcdio::get_cdtext($self->{cd},$self->{track});
}

=pod

=head2 get_format

  get_format()->$format

Get the format (e.g. 'audio', 'mode2', 'mode1') of track.

=cut

sub get_format {
    my ($self, @p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    return perlcdio::get_track_format($self->{device}, $self->{track});
}

=pod

=head2 get_last_lsn

  get_last_lsn()->lsn

Return the ending LSN for a track
C<$perlcdio::INVALID_LSN> is returned on error.

=cut

sub get_last_lsn {
    my ($self, @p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    return perlcdio::get_track_last_lsn($self->{device}, $self->{track});
}

=pod

=head2 get_lba

  get_lba()->lba

Return the starting LBA for a track
C<$perlcdio::INVALID_LBA> is returned on error.

=cut

sub get_lba {
    my ($self, @p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    return perlcdio::get_track_lba($self->{device}, $self->{track});
}

=pod

=head2 get_lsn

  get_lsn()->lsn

Return the starting LSN for a track
C<$perlcdio::INVALID_LSN> is returned on error.

=cut

sub get_lsn {
    my ($self, @p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    return perlcdio::get_track_lsn($self->{device}, $self->{track});
}

=pod

=head2 get_msf

  get_msf()

Return the starting MSF (minutes/secs/frames) for track number track.
Track numbers usually start at something greater than 0, usually 1.

Returns string of the form mm:ss:ff if all good, or string 'error' on
error.

=cut

sub get_msf {
    my ($self, @p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    return perlcdio::get_track_msf($self->{device}, $self->{track});
}

=pod

=head2 get_preemphasis

  get_preemphasis()->result

Get linear preemphasis status on an audio track.
This is not meaningful if not an audio track?

=cut

sub get_preemphasis {
    my ($self, @p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    my $rc = perlcdio::get_track_preemphasis($self->{device}, $self->{track});
    if ($rc == $perlcdio::CDIO_TRACK_FLAG_FALSE) {
	return 'no pre-emphasis';
    } elsif ($rc == $perlcdio::CDIO_TRACK_FLAG_TRUE) {
	return 'pre-emphasis';
    } elsif ($rc == $perlcdio::CDIO_TRACK_FLAG_UNKNOWN) {
	return 'unknown';
    } else {
	return 'invalid';
    }
}

=pod

=head2 get_track_sec_count

item get_track_sec_count()->int
Get the number of sectors between this track an the next.  This
includes any pregap sectors before the start of the next track.
Track numbers usually start at something
greater than 0, usually 1.

C<$perlcdio::INVALID_LSN> is returned on error.

=cut

sub get_track_sec_count {
    my ($self, @p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    return perlcdio::get_track_sec_count($self->{device}, $self->{track});
}

=pod

=head2 is_track_green

  is_track_green(cdio, track) -> bool

Return True if we have XA data (green, mode2 form1) or
XA data (green, mode2 form2). That is track begins:

  sync - header - subheader
  12     4      -  8

=cut

sub is_track_green {
    my ($self, @p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    return perlcdio::is_track_green($self->{device}, $self->{track});
}

=pod

=head2 get_track_isrc

$isrc = $track->get_track_isrc($insert_dashes=0);

Returns an empty string or the International Standard Recording Code.
Which is presented in 4 hyphen-separated substrings: "CC-XXX-YY-NNNNN"

"CC" two-character ISO 3166-1 alpha-2 country code
"XXX" is a three character alphanumeric registrant code
"YY" is the last two digits of the year of registration
     (NB not necessarily the date the recording was made)
"NNNNN" is a unique 5-digit number identifying the particular sound recording.

=cut

sub get_track_isrc {
    my ($self, @p) = @_;
    my $insert_dashes = defined $p[0] && $p[0];
    my $isrc =  perlcdioc::cdio_get_track_isrc($self->{device}, $self->{track});
    if(!$isrc) {
        $isrc =  perlmmcc::mmc_get_isrc($self->{device}, $self->{track});
    }
    if ($isrc && $insert_dashes) {
	$isrc =~ s/(\w\w)(\w\w\w)(\w\w)(\w+)/$1-$2-$3-$4/;    #"CC-XXX-YY-NNNNN"
    }
    return $isrc;
}
=pod

=head2 set_track

  set_track(track_num)

Set a new track number.

=cut

sub set_track {
    my($self,@p) = @_;
    my($track_num, @args) = _rearrange(['TRACK'], @p);
    return undef if _extra_args(@args);
    $self->{track} = $track_num;
    return $self;
}

1; # Magic true value required at the end of a module

__END__

=pod

=head1 SEE ALSO

L<Device::Cdio> is the top-level module, L<Device::Cdio::Device> is a
class device objects, and L<Device::Cdio::ISO9660> for working with
ISO9660 systems.

L<perlcdio> is the lower-level interface to libcdio.

L<http://www.gnu.org/software/libcdio/doxygen/track_8h.html> is
documentation via doxygen of C<libiso9660>.

=head1 AUTHORS

Rocky Bernstein

=head1 COPYRIGHT

Copyright (C) 2006, 2012, 2017 Rocky Bernstein <rocky@cpan.org>

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
