package Device::Cdio::Device;
require 5.8.6;
#
#  See end for copyright and license.

=pod

=head1 NAME

Device::Cdio::Device - Class for disc and device aspects of Cdio.

=head1 SYNOPSIS

    use Device::Cdio::Device;
    $d = Device::Cdio::Device->new(-driver_id=>$perlcdio::DRIVER_DEVICE);
    $drive_name = $d->get_device();
    ($i_read_cap, $i_write_cap, $i_misc_cap) =  $d->get_drive_cap();

    $start_lsn = $d->get_first_track()->get_lsn();
    $end_lsn=$d->get_disc_last_lsn();
    $drc = $d->audio_play_lsn($start_lsn, $end_lsn);
    ($vendor, $model, $release, $drc) = $d->get_hwinfo();

=cut

use warnings;
use strict;
use Exporter;
use perlcdio;
use Device::Cdio::Util qw( _check_arg_count _extra_args _rearrange );
use Device::Cdio qw(convert_drive_cap_read convert_drive_cap_write
		    convert_drive_cap_misc );
use Device::Cdio::Track;

$Device::Cdio::Device::VERSION   = $Device::Cdio::VERSION;
@Device::Cdio::Device::EXPORT    = qw( new );
@Device::Cdio::Device::EXPORT_OK = qw( close open );

%Device::Cdio::CDTEXT_FIELD = (
    'TITLE'      => $perlcdio::CDTEXT_FIELD_TITLE,
    'PERFORMER'  => $perlcdio::CDTEXT_FIELD_PERFORMER,
    'SONGWRITER' => $perlcdio::CDTEXT_FIELD_SONGWRITER,
    'COMPOSER'   => $perlcdio::CDTEXT_FIELD_COMPOSER,
    'MESSAGE'    => $perlcdio::CDTEXT_FIELD_MESSAGE,
    'ARRANGER'   => $perlcdio::CDTEXT_FIELD_ARRANGER,
    'ISRC'       => $perlcdio::CDTEXT_FIELD_ISRC,
    'UPC_EAN'    => $perlcdio::CDTEXT_FIELD_UPC_EAN,
    'GENRE'      => $perlcdio::CDTEXT_FIELD_GENRE,
    'DISCID'     => $perlcdio::CDTEXT_FIELD_DISCID,
    'INVALID'    => $perlcdio::CDTEXT_FIELD_INVALID,
    );

$Device::Cdio::CDTEXT_MIN_CDTEXT_FIELD  = $perlcdio::MIN_CDTEXT_FIELD;
$Device::Cdio::CDTEXT_MAX_CDTEXT_FIELDS = $perlcdio::MAX_CDTEXT_FIELDS;

%Device::Cdio::CDTEXT_FIELD_by_id = reverse %Device::Cdio::CDTEXT_FIELD;


%Device::Cdio::CDTEXT_GENRE = (
    'UNUSED'         => $perlcdio::CDTEXT_GENRE_UNUSED,
    'UNDEFINED'      => $perlcdio::CDTEXT_GENRE_UNDEFINED,
    'ADULT_CONTEMP'  => $perlcdio::CDTEXT_GENRE_ADULT_CONTEMP,
    'ALT_ROCK'       => $perlcdio::CDTEXT_GENRE_ALT_ROCK,
    'CHILDRENS'      => $perlcdio::CDTEXT_GENRE_CHILDRENS,
    'CLASSIC'        => $perlcdio::CDTEXT_GENRE_CLASSIC,
    'CHRIST_CONTEMP' => $perlcdio::CDTEXT_GENRE_CHRIST_CONTEMP,
    'COUNTRY'        => $perlcdio::CDTEXT_GENRE_COUNTRY,
    'DANCE'          => $perlcdio::CDTEXT_GENRE_DANCE,
    'EASY_LISTENING' => $perlcdio::CDTEXT_GENRE_EASY_LISTENING,
    'EROTIC'         => $perlcdio::CDTEXT_GENRE_EROTIC,
    'FOLK'           => $perlcdio::CDTEXT_GENRE_FOLK,
    'GOSPEL'         => $perlcdio::CDTEXT_GENRE_GOSPEL,
    'HIPHOP'         => $perlcdio::CDTEXT_GENRE_HIPHOP,
    'JAZZ'           => $perlcdio::CDTEXT_GENRE_JAZZ,
    'LATIN'          => $perlcdio::CDTEXT_GENRE_LATIN,
    'MUSICAL'        => $perlcdio::CDTEXT_GENRE_MUSICAL,
    'NEWAGE'         => $perlcdio::CDTEXT_GENRE_NEWAGE,
    'OPERA'          => $perlcdio::CDTEXT_GENRE_OPERA,
    'OPERETTA'       => $perlcdio::CDTEXT_GENRE_OPERETTA,
    'POP'            => $perlcdio::CDTEXT_GENRE_POP,
    'RAP'            => $perlcdio::CDTEXT_GENRE_RAP,
    'REGGAE'         => $perlcdio::CDTEXT_GENRE_REGGAE,
    'ROCK'           => $perlcdio::CDTEXT_GENRE_ROCK,
    'RYTHMANDBLUES'  => $perlcdio::CDTEXT_GENRE_RYTHMANDBLUES,
    'SOUNDEFFECTS'   => $perlcdio::CDTEXT_GENRE_SOUNDEFFECTS,
    'SOUNDTRACK'     => $perlcdio::CDTEXT_GENRE_SOUNDTRACK,
    'SPOKEN_WORD'    => $perlcdio::CDTEXT_GENRE_SPOKEN_WORD,
    'WORLD_MUSIC'    => $perlcdio::CDTEXT_GENRE_WORLD_MUSIC,
    );


%Device::Cdio::CDTEXT_GENRE_by_id = reverse %Device::Cdio::CDTEXT_GENRE;

%Device::Cdio::CDTEXT_LANGUAGE = (
    'UNKNOWN'       => $perlcdio::CDTEXT_LANGUAGE_UNKNOWN,
    'ALBANIAN'      => $perlcdio::CDTEXT_LANGUAGE_ALBANIAN,
    'BRETON'        => $perlcdio::CDTEXT_LANGUAGE_BRETON,
    'CATALAN'       => $perlcdio::CDTEXT_LANGUAGE_CATALAN,
    'CROATIAN'      => $perlcdio::CDTEXT_LANGUAGE_CROATIAN,
    'WELSH'         => $perlcdio::CDTEXT_LANGUAGE_WELSH,
    'CZECH'         => $perlcdio::CDTEXT_LANGUAGE_CZECH,
    'DANISH'        => $perlcdio::CDTEXT_LANGUAGE_DANISH,
    'GERMAN'        => $perlcdio::CDTEXT_LANGUAGE_GERMAN,
    'ENGLISH'       => $perlcdio::CDTEXT_LANGUAGE_ENGLISH,
    'SPANISH'       => $perlcdio::CDTEXT_LANGUAGE_SPANISH,
    'ESPERANTO'     => $perlcdio::CDTEXT_LANGUAGE_ESPERANTO,
    'ESTONIAN'      => $perlcdio::CDTEXT_LANGUAGE_ESTONIAN,
    'BASQUE'        => $perlcdio::CDTEXT_LANGUAGE_BASQUE,
    'FAROESE'       => $perlcdio::CDTEXT_LANGUAGE_FAROESE,
    'FRENCH'        => $perlcdio::CDTEXT_LANGUAGE_FRENCH,
    'FRISIAN'       => $perlcdio::CDTEXT_LANGUAGE_FRISIAN,
    'IRISH'         => $perlcdio::CDTEXT_LANGUAGE_IRISH,
    'GAELIC'        => $perlcdio::CDTEXT_LANGUAGE_GAELIC,
    'GALICIAN'      => $perlcdio::CDTEXT_LANGUAGE_GALICIAN,
    'ICELANDIC'     => $perlcdio::CDTEXT_LANGUAGE_ICELANDIC,
    'ITALIAN'       => $perlcdio::CDTEXT_LANGUAGE_ITALIAN,
    'LAPPISH'       => $perlcdio::CDTEXT_LANGUAGE_LAPPISH,
    'LATIN'         => $perlcdio::CDTEXT_LANGUAGE_LATIN,
    'LATVIAN'       => $perlcdio::CDTEXT_LANGUAGE_LATVIAN,
    'LUXEMBOURGIAN' => $perlcdio::CDTEXT_LANGUAGE_LITHUANIAN,
    'HUNGARIAN'     => $perlcdio::CDTEXT_LANGUAGE_HUNGARIAN,
    'MALTESE'       => $perlcdio::CDTEXT_LANGUAGE_MALTESE,
    'DUTCH'         => $perlcdio::CDTEXT_LANGUAGE_DUTCH,
    'NORWEGIAN'     => $perlcdio::CDTEXT_LANGUAGE_NORWEGIAN,
    'OCCITAN'       => $perlcdio::CDTEXT_LANGUAGE_OCCITAN,
    'POLISH'        => $perlcdio::CDTEXT_LANGUAGE_POLISH,
    'PORTUGUESE'    => $perlcdio::CDTEXT_LANGUAGE_PORTUGUESE,
    'ROMANIAN'      => $perlcdio::CDTEXT_LANGUAGE_ROMANIAN,
    'ROMANSH'       => $perlcdio::CDTEXT_LANGUAGE_ROMANSH,
    'SERBIAN'       => $perlcdio::CDTEXT_LANGUAGE_SERBIAN,
    'SLOVAK'        => $perlcdio::CDTEXT_LANGUAGE_SLOVAK,
    'SLOVENIAN'     => $perlcdio::CDTEXT_LANGUAGE_SLOVENIAN,
    'FINNISH'       => $perlcdio::CDTEXT_LANGUAGE_FINNISH,
    'SWEDISH'       => $perlcdio::CDTEXT_LANGUAGE_SWEDISH,
    'TURKISH'       => $perlcdio::CDTEXT_LANGUAGE_TURKISH,
    'FLEMISH'       => $perlcdio::CDTEXT_LANGUAGE_FLEMISH,
    'WALLON'        => $perlcdio::CDTEXT_LANGUAGE_WALLON,
    'ZULU'          => $perlcdio::CDTEXT_LANGUAGE_ZULU,
    'VIETNAMESE'    => $perlcdio::CDTEXT_LANGUAGE_VIETNAMESE,
    'UZBEK'         => $perlcdio::CDTEXT_LANGUAGE_UZBEK,
    'URDU'          => $perlcdio::CDTEXT_LANGUAGE_URDU,
    'UKRAINIAN'     => $perlcdio::CDTEXT_LANGUAGE_UKRAINIAN,
    'THAI'          => $perlcdio::CDTEXT_LANGUAGE_THAI,
    'TELUGU'        => $perlcdio::CDTEXT_LANGUAGE_TELUGU,
    'TATAR'         => $perlcdio::CDTEXT_LANGUAGE_TATAR,
    'TAMIL'         => $perlcdio::CDTEXT_LANGUAGE_TAMIL,
    'TADZHIK'       => $perlcdio::CDTEXT_LANGUAGE_TADZHIK,
    'SWAHILI'       => $perlcdio::CDTEXT_LANGUAGE_SWAHILI,
    'SRANANTONGO'   => $perlcdio::CDTEXT_LANGUAGE_SRANANTONGO,
    'SOMALI'        => $perlcdio::CDTEXT_LANGUAGE_SOMALI,
    'SINHALESE'     => $perlcdio::CDTEXT_LANGUAGE_SINHALESE,
    'SHONA'         => $perlcdio::CDTEXT_LANGUAGE_SHONA,
    'SERBO_CROAT'   => $perlcdio::CDTEXT_LANGUAGE_SERBO_CROAT,
    'RUTHENIAN'     => $perlcdio::CDTEXT_LANGUAGE_RUTHENIAN,
    'RUSSIAN'       => $perlcdio::CDTEXT_LANGUAGE_RUSSIAN,
    'QUECHUA'       => $perlcdio::CDTEXT_LANGUAGE_QUECHUA,
    'PUSHTU'        => $perlcdio::CDTEXT_LANGUAGE_PUSHTU,
    'PUNJABI'       => $perlcdio::CDTEXT_LANGUAGE_PUNJABI,
    'PERSIAN'       => $perlcdio::CDTEXT_LANGUAGE_PERSIAN,
    'PAPAMIENTO'    => $perlcdio::CDTEXT_LANGUAGE_PAPAMIENTO,
    'ORIYA'         => $perlcdio::CDTEXT_LANGUAGE_ORIYA,
    'NEPALI'        => $perlcdio::CDTEXT_LANGUAGE_NEPALI,
    'NDEBELE'       => $perlcdio::CDTEXT_LANGUAGE_NDEBELE,
    'MARATHI'       => $perlcdio::CDTEXT_LANGUAGE_MARATHI,
    'MOLDAVIAN'     => $perlcdio::CDTEXT_LANGUAGE_MOLDAVIAN,
    'MALAYSIAN'     => $perlcdio::CDTEXT_LANGUAGE_MALAYSIAN,
    'MALAGASAY'     => $perlcdio::CDTEXT_LANGUAGE_MALAGASAY,
    'MACEDONIAN'    => $perlcdio::CDTEXT_LANGUAGE_MACEDONIAN,
    'LAOTIAN'       => $perlcdio::CDTEXT_LANGUAGE_LAOTIAN,
    'KOREAN'        => $perlcdio::CDTEXT_LANGUAGE_KOREAN,
    'KHMER'         => $perlcdio::CDTEXT_LANGUAGE_KHMER,
    'KAZAKH'        => $perlcdio::CDTEXT_LANGUAGE_KAZAKH,
    'KANNADA'       => $perlcdio::CDTEXT_LANGUAGE_KANNADA,
    'JAPANESE'      => $perlcdio::CDTEXT_LANGUAGE_JAPANESE,
    'INDONESIAN'    => $perlcdio::CDTEXT_LANGUAGE_INDONESIAN,
    'HINDI'         => $perlcdio::CDTEXT_LANGUAGE_HINDI,
    'HEBREW'        => $perlcdio::CDTEXT_LANGUAGE_HEBREW,
    'HAUSA'         => $perlcdio::CDTEXT_LANGUAGE_HAUSA,
    'GURANI'        => $perlcdio::CDTEXT_LANGUAGE_GURANI,
    'GUJURATI'      => $perlcdio::CDTEXT_LANGUAGE_GUJURATI,
    'GREEK'         => $perlcdio::CDTEXT_LANGUAGE_GREEK,
    'GEORGIAN'      => $perlcdio::CDTEXT_LANGUAGE_GEORGIAN,
    'FULANI'        => $perlcdio::CDTEXT_LANGUAGE_FULANI,
    'DARI'          => $perlcdio::CDTEXT_LANGUAGE_DARI,
    'CHURASH'       => $perlcdio::CDTEXT_LANGUAGE_CHURASH,
    'CHINESE'       => $perlcdio::CDTEXT_LANGUAGE_CHINESE,
    'BURMESE'       => $perlcdio::CDTEXT_LANGUAGE_BURMESE,
    'BULGARIAN'     => $perlcdio::CDTEXT_LANGUAGE_BULGARIAN,
    'BENGALI'       => $perlcdio::CDTEXT_LANGUAGE_BENGALI,
    'BIELORUSSIAN'  => $perlcdio::CDTEXT_LANGUAGE_BAMBORA,
    'AZERBAIJANI'   => $perlcdio::CDTEXT_LANGUAGE_AZERBAIJANI,
    'ASSAMESE'      => $perlcdio::CDTEXT_LANGUAGE_ASSAMESE,
    'ARMENIAN'      => $perlcdio::CDTEXT_LANGUAGE_ARMENIAN,
    'ARABIC'        => $perlcdio::CDTEXT_LANGUAGE_ARABIC,
    'AMHARIC'       => $perlcdio::CDTEXT_LANGUAGE_AMHARIC,
    );

%Device::Cdio::CDTEXT_LANGUAGE_by_id = reverse %Device::Cdio::CDTEXT_LANGUAGE;


=pod

=head1 METHODS

=cut

=pod

=head2 new

  new(source, driver_id, access_mode)->$device_object

Create a new Device object. Either parameter C<source>, C<driver_id>
or C<access_mode> can be C<undef>. In fact it is probably best to not
to give an C<access_mode> unless you know what you are doing.

=cut
sub new {

  my($class,@p) = @_;

  my($source, $driver_id, $access_mode, @args) =
      _rearrange(['SOURCE', 'DRIVER_ID', 'ACCESS_MODE'], @p);

  return undef if _extra_args(@args);

  my $self = {};
  $self->{cd} = undef;

  bless ($self, $class);

  $self->open($source, $driver_id,  $access_mode)
      if defined($source) || defined($driver_id);

  return $self;
}

=pod

=head2 audio_pause

  audio_pause()-> $status

Pause playing CD through analog output.
The device status is returned.

=cut

sub audio_pause {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::audio_pause($self->{cd});
}

=pod

=head2 audio_play_lsn

  audio_play_lsn(start_lsn, end_lsn)-> $status

Playing CD through analog output at the given lsn to the ending lsn
The device status is returned.

=cut

sub audio_play_lsn {
    my($self,@p) = @_;
    my($start_lsn, $end_lsn, @args) =
	_rearrange(['START_LSN', 'END_LSN'], @p);
    return $perlcdio::BAD_PARAMETER if _extra_args(@args);
    return perlcdio::audio_play_lsn($self->{cd}, $start_lsn, $end_lsn);
}

=pod

=head2 audio_resume

  audio_resume()-> $status

Resume playing an audio CD through the analog interface.
The device status is returned.

=cut

sub audio_resume {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::audio_resume($self->{cd});
}

=pod

=head2 audio_stop

  audio_stop()-> $status

Stop playing an audio CD through the analog interface.  The device
status is returned.

=cut

sub audio_stop {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::audio_stop($self->{cd});
}

=pod

=head2 close

  close()->bool

Free resources associated with cdio.  Call this when done using using
CD reading/control operations for the current device.

=cut

sub close {
    my($self,@p) = @_;
    return 0 if !_check_arg_count($#_, 0);
    if (defined($self->{cd})) {
	perlcdio::close($self->{cd});
    } else {
	print "***No object to close\n";
        $self->{cd} = undef;
	return 0;
    }
    return 1;
}

=pod

=head2 eject_media

  eject_media()->drc

Eject media in CD drive if there is a routine to do so.
status is returned.

=cut

sub eject_media {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    my $drc = perlcdio::eject_media($self->{cd});
    $self->{cd} = undef;
    return $drc;
}

=pod

=head2 get_arg

  get_arg(key)->string

=cut

sub  get_arg {
    my($self,@p) = @_;
    my($key, @args) = 	_rearrange(['KEY'], @p);
    return undef if _extra_args(@args);
    return perlcdio::get_arg($self->{cd}, $key);
}

=pod

=head2 get_device

  get_device()->str

Get the default CD device.

If the CD object has an opened CD, return the name of the device used.
(In fact this is the same thing as issuing C<d-E<gt>get_arg("source")>).

If we haven't initialized a specific device driver, then find a
suitable one and return the default device for that.

In some situations of drivers or OS's we can't find a CD device if
there is no media in it and it is possible for this routine to return
undef even though there may be a hardware CD-ROM.

=cut

sub get_device {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);
    return perlcdio::get_arg($self->{cd}, "source")
	if ($self->{cd});
    return perlcdio::get_device($self->{cd});
}

=pod

=head2 get_disc_last_lsn

  get_disc_last_lsn(self)->int

Get the LSN of the end of the CD. C<$perlcdio::INVALID_LSN> is
returned if there was an error.

=cut

sub get_disc_last_lsn {
    my($self,@p) = @_;
    return undef if !_check_arg_count($#_, 0);
    return perlcdio::get_disc_last_lsn($self->{cd});
}

=pod

=head2 get_disc_mode

  get_disc_mode() -> str

Get disc mode - the kind of CD: CD-DA, CD-ROM mode 1, CD-MIXED, etc.
that we've got. The notion of 'CD' is extended a little to include
DVD's.

=cut

sub get_disc_mode {
    my($self,@p) = @_;
    return perlcdio::get_disc_mode($self->{cd});
}

=pod

=head2 get_drive_cap

  get_drive_cap()->(read_cap, write_cap, misc_cap)

Get drive capabilities of device.

In some situations of drivers or OS's we can't find a CD
device if there is no media in it. In this situation
capabilities will show up as empty even though there is a
hardware CD-ROM.

=cut

sub get_drive_cap {
    my($self,@p) = @_;
    return (undef, undef, undef) if !_check_arg_count($#_, 0);
    my ($b_read_cap, $b_write_cap, $b_misc_cap) =
	perlcdio::get_drive_cap($self->{cd});
    return (convert_drive_cap_read($b_read_cap),
	    convert_drive_cap_write($b_write_cap),
	    convert_drive_cap_misc($b_misc_cap));
}

=pod

=head2 get_drive_cap_dev

  get_drive_cap_dev(device=undef)->(read_cap, write_cap, misc_cap)

Get drive capabilities of device.

In some situations of drivers or OS's we can't find a CD
device if there is no media in it. In this situation
capabilities will show up as empty even though there is a
hardware CD-ROM.

=cut

### FIXME: combine into above by testing on the type of device.
sub get_drive_cap_dev {
    my($self,@p) = @_;
    my($device, @args) = _rearrange(['DEVICE'], @p);
    return (undef, undef, undef) if _extra_args(@args);

    my ($b_read_cap, $b_write_cap, $b_misc_cap) =
	perlcdio::get_drive_cap_dev($device);
    return (convert_drive_cap_read($b_read_cap),
	    convert_drive_cap_write($b_write_cap),
	    convert_drive_cap_misc($b_misc_cap));
}

=pod

=head2 get_driver_name

  get_driver_name()-> string

return a string containing the name of the driver in use.
C<undef> is returned if there's an error.

=cut

sub get_driver_name {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_driver_name($self->{cd});
}

=pod

=head2 get_driver_id

  get_driver_id()-> int

=cut

sub get_driver_id {
    my($self, @p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_driver_id($self->{cd});
}

=pod

=head2 get_first_track

  get_first_track()->Track

return a Track object of the first track. C<$perlcdio::INVALID_TRACK>
or C<$perlcdio::BAD_PARAMETER> is returned if there was a problem.

Return the driver id of the driver in use.
if object has not been initialized or is None,
return C<$perlcdio::DRIVER_UNKNOWN>.

=cut

sub get_first_track {
    my($self, @p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return Device::Cdio::Track->new(-device=>$self->{cd},
				    -track=>perlcdio::get_first_track_num($self->{cd}));
}

=pod

=head2 get_hwinfo

  get_hwinfo()->(vendor, model, release, drc)

Get the CD-ROM hardware info via a SCSI MMC INQUIRY command.
An exception is raised if we had an error.

=cut

sub get_hwinfo {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    my ($hwinfo, $drc) = perlcdio::get_hwinfo($self->{cd});
    return (@$hwinfo, $drc);
}

=pod

=head2 audio_get_volume

    my($arr, $rc) = $dev->audio_get_volume;

Returns the volume settings of device's 4 channels and the device return code.
In scalar environmet only the device return code!
See C<perlcdio::driver_errmsg($rc)> for return-values meanings when C<$rc != 0>.

=cut

sub audio_get_volume {
    my($self,@p) = @_;
    my ($vol,$drc) = perlcdio::audio_get_volume_levels($self->{cd});
    return wantarray ? ($vol,$drc) : $drc;
}

=pod

=head2 audio_play_track_index

    $drc = $dev->audio_play_track_index($start_track, $start_index, $end_track, $end_track);

Playing CD through analog output at the desired start track and index,
to the end track and index. Tracks should be in the valid CD track range 0..99.

Just as a track number is burned into the CD, so is a an index for a track.

See C<perlcdio::driver_errmsg($drc)> for return-values meanings when C<$drc != 0>.

=cut

sub audio_play_track_index {
    my($self, $start_track, $start_index, $end_track, $end_index) = @_;
    return perlcdio::audio_play_track_index($self->{cd},
					    $start_track, $start_index,
					    $end_track, $end_index);
}

=head2 audio_set_volume

    $drc = $dev->audio_set_volume($channel1_volume, $channel2_volume,
                                  $channel3_volume, $channel4_volume);

Set the volume levels of the channels 1-4. Values from 0-255 are possible.
Stereo CDROM devices (which is most of them) use only channels 1 and 2.

Use -1 when the existing value should be kept.
See C<perlcdio::driver_errmsg($drc)> for return-values meanings when C<$drc != 0>.

=cut

sub audio_set_volume {
    my($self,@p) = @_;
    my ($vol, $drc) = perlcdio::audio_get_volume_levels($self->{cd});
    for(my $i =0;$i<4;$i++) {
        if(defined $p[$i]) {
            @$vol[$i] = $p[$i] if $p[$i] > -1;
            @$vol[$i] = 255 if $p[$i] > 255;
        }
    }
    return perlcdio::audio_set_volume_levels($self->{cd}, @$vol[0], @$vol[1],
        @$vol[2], @$vol[3]);
}

=pod

=head2 get_disk_cdtext, get_track_cdtext

    $hash = $dev->get_disk_cdtext;
    $hash = $dev->get_cdtext_for_track(track, field);
    $hash = $dev->get_cdtext_field_for_track(track, field);
    $hash = $dev->get_cdtext_field_for_track(track, field);

Returns a hash reference hash->{cdtext_field}="text"
if found any cdtext on disk;

=cut

sub cdtext_init {
    my($self,@p) = @_;
    $self->{cdtext} =  perlcdio::cdio_get_cdtext($self->{cd});
    return $self->{cdtext};
}

sub cdtext_data_init {
    my($cdt, $cdt_data, $cdt_size, @p) = @_;
    return perlcdio::cdtext_data_init($cdt, $cdt_data, $cdt_size);
}

=head2 get_disk_cdtext_field_for_track

    $str = $dev->get_cdtext_field_for_track($field, $track=0, $cdtext=$self->{cdtext});

Returns the text associated with field $field of track $track of $cdtext if there
is any.

=cut
sub cdtext_field_for_track {
    my($self,$f, $t, @p) = @_;
    $t = 0 if !defined $t;
    my $cdtext = defined $p[0] ? $p[0] : $self->{cdtext};
    return perlcdio::cdtext_get_const($cdtext, $f, $t);
}

sub cdtext_field_for_disc {
    my($self,$f, @p) = @_;
    my $cdtext = defined $p[0] ? $p[0] : $self->{cdtext};
    return perlcdio::cdtext_get_const($cdtext, $f, 0);
}

sub cdtext_list_languages {
    my($self, @p) = @_;
    my $cdtext = defined $p[0] ? $p[0] : $self->{cdtext};
    if (!$cdtext) {
	$cdtext = $self->cdtext_init();
    }
    return perlcdio::cdtext_list_languages($cdtext);
}

sub cdtext_select_language {
    my($self, $lang, @p) = @_;
    my $cdtext = defined $p[0] ? $p[0] : $self->{cdtext};
    return if !exists $Device::Cdio::CDTEXT_LANGUAGE{$lang};
    my $l = $Device::Cdio::CDTEXT_LANGUAGE{$lang};
    if (!$cdtext) {
	$cdtext = $self->cdtext_init();
    }
    return perlcdio::cdtext_select_language($cdtext, $l);
}

sub get_track_cdtext {
    my($self, $t, @p) = @_;
    $t = 0 if !defined $t;
    my $cdtext_fields = {};
    my $cdtext = defined $p[0] ? $p[0] : $self->{cdtext};
    for (my $field=$perlcdio::MIN_CDTEXT_FIELD;
	 $field <= $perlcdio::MAX_CDTEXT_FIELDS; $field++) {
	$cdtext_fields->{$field} = perlcdio::cdtext_get_const($cdtext, $field, $t);
    }
    return $cdtext_fields;
}

sub get_disc_cdtext {
    my($self, @p) = @_;
    return get_track_cdtext($self, 0, @p);
}


=head2 cdtext_destroy

$dev->cdtext_destroy()

Removes CD-TEXT memor resources associated a disc and sets
$dev->{cdtext} to undef.

Use this when you are done accessing with CD-TEXT information.

Note: $def->close() runs this as part of its operation.

=cut

sub cdtext_destroy {
    my($self, @p) = @_;
    my $cdtext = defined $p[0] ? $p[0] : $self->{cdtext};
    perlcdio::cdtext_destory($cdtext);
    $self->{cdtext} = undef;
}

=pod

=head2 get_cddb_discid

    $discid = $dev->get_cddb_discid;

Returns the calculated cddb discid integer. Usually used as hexstring!

=cut

sub get_cddb_discid {
    my($self,@p) = @_;
    return perlcdio::get_cddb_discid($self->{cd});
}

=pod

=head2 audio_get_status

    my($hash, $drc) = $dev->audio_get_status;

Returns a hash reference with the audio-subchannel-mmc status values:

    audio_status : value
    status_text  : audio_status as text
                (INVALID,ERROR,NO_STATUS,UNKNOWN,playing,paused,completed)
    track : track number
    index : index in track
    msf time values as ints minutes, seconds,frames :
        abs_m,abs_s,abs_f  : total disc time played
        rel_m,rel_s,el_f   : track time played
    disk_s  : seconds disk played
    track_s : seconds track played
    address
    control

=cut

sub audio_get_status {
    my($self,@p) = @_;
    my ($ptr, $drc) = perlcdio::audio_get_status($self->{cd});
    return $ptr, $drc;
}

=pod

=head2 is_tray_open

    $dev->is_tray_open

returns true if tray seems open, 0 otherwise.

=cut

sub is_tray_open {
    my($self,@p) = @_;
    return perlcdio::get_tray_status($self->{cd});
}


=pod

=head2 get_joliet_level

  get_joliet_level()->int

Return the Joliet level recognized for cdio.
This only makes sense for something that has an ISO-9660
filesystem.

=cut

sub get_joliet_level {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_joliet_level($self->{cd});
}

=pod

=head2 get_last_session

  get_last_session(self) -> (track_lsn, drc)

Get the LSN of the first track of the last session of on the CD.

=cut

sub get_last_session {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_last_session($self->{cd});
}

=pod

=head2 get_last_track

  get_last_track()->Track

return a Track object of the last track. C<$perlcdio::INVALID_TRACK>
or C<$perlcdio::BAD_PARAMETER> is returned if there was a problem.

=cut

sub get_last_track {
    my($self, @p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return Device::Cdio::Track->new(-device=>$self->{cd},
				    -track=>perlcdio::get_last_track_num($self->{cd}));
}

=pod

=head2 get_mcn

get_mcn()->str

Get the media catalog number (MCN) from the CD.

=cut

sub get_mcn {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_mcn($self->{cd});
}

=pod

=head2 get_media_changed

  get_media_changed() -> int

Find out if media has changed since the last call.
Return 1 if media has changed since last call, 0 if not.
A negative number indicates the driver status error.

=cut

sub get_media_changed {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::get_media_changed($self->{cd});
}

=pod

=head2 guess_cd_type

$hash = $dev->guess_cd_type($lsn,$track);

Try to determine what kind of CD-image and/or filesystem we have at
track $track. First argument is the start lsn of track $track. Returns a
hash reference with following keys:

    cdio_fs_t     (enum cdio_fs_t from libcdio) FIXME: add text
    cdio_fs_cap_t (enum cdio_fs_cap_t from libcdio) FIXME: add text
    joliet_level  If has Joliet extensions, this is the associated level
                    number (i.e. 1, 2, or 3).
    iso_label      32 byte ISO fs label.
    isofs_size     size of ISO fs.
    UDFVerMajor    UDF fs version.
    UDFVerMinor    UDF fs version.

=cut

sub guess_cd_type {
    my($self, $session, $track, @p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 2);
    return perlcdio::guess_cd_type($self->{cd}, $session, $track);
}

=pod

=head2 get_num_tracks

  get_num_tracks()->int

Return the number of tracks on the CD.
C<$perlcdio::INVALID_TRACK> is raised on error.

=cut

sub get_num_tracks {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return  perlcdio::get_num_tracks($self->{cd});
}

=pod

=head2 get_track

  get_track(track_num)->track

Set a new track object of the current disc for the given track number.

=cut

sub get_track {
    my($self,@p) = @_;
    my($track_num, @args) = _rearrange(['TRACK'], @p);
    return undef if _extra_args(@args);
    return Device::Cdio::Track->new(-device=>$self->{cd}, -track=>$track_num);
}

=pod

=head2 get_track_for_lsn

  get_track_for_lsn(LSN)->Track

Find the track which contains LSN.  undef is returned if the lsn
outside of the CD or if there was some error.

If the LSN is before the pregap of the first track, A track object
with a 0 track is returned.  Otherwise we return the track that spans
the lsn.

=cut

sub get_track_for_lsn {
    my($self,@p) = @_;
    my($lsn_num, @args) = _rearrange(['LSN'], @p);
    return undef if _extra_args(@args);
    my $track = perlcdio::get_last_track_num($self->{cd});
    return undef if ($track == $perlcdio::INVALID_TRACK);
    return Device::Cdio::Track->new(-device=>$self->{cd}, -track=>$track);
}

=pod

=head2 have_ATAPI

  have_ATAPI()->bool

return 1 if CD-ROM understand ATAPI commands.

=cut

sub have_ATAPI {
    my($self,@p) = @_;
    return $perlcdio::BAD_PARAMETER if !_check_arg_count($#_, 0);
    return perlcdio::have_ATAPI($self->{cd});
}

=pod

=head2 lseek

  lseek(offset, whence)->int

Reposition read offset. Similar to (if not the same as) libc's fseek()

offset is the amount to seek and whence is like corresponding
parameter in libc's lseek, e.g.  it should be SEEK_SET or SEEK_END.

the offset is returned or -1 on error.

=cut

sub lseek {
    my($self,@p) = @_;
    my($offset, $whence, @args) = _rearrange(['OFFSET', 'WHENCE'], @p);
    return -1 if _extra_args(@args);
    return perlcdio::lseek($self->{cd}, $offset, $whence);
}

=pod

=head2 open

  open(source=undef, driver_id=$libcdio::DRIVER_UNKNOWN,
       access_mode=undef)->$cdio_obj

Sets up to read from place specified by source, driver_id and access
mode. This should be called before using any other routine except
those that act on a CD-ROM drive by name. It is implicitly called when
a new is done specifying a source or driver id.

If C<undef> is given as the source, we'll use the default driver device.
If C<undef> is given as the driver_id, we'll find a suitable device
driver.  Device is opened so that subsequent operations can be
performed.

=cut

sub open {
    my($self,@p) = @_;
    my($source, $driver_id, $access_mode) =
	_rearrange(['SOURCE', 'DRIVER_ID', 'ACCESS_MODE'], @p);

    $driver_id = $perlcdio::DRIVER_UNKNOWN
	if !defined($driver_id);

    $self->close() if defined($self->{cd});
    $self->{cd} = perlcdio::open_cd($source, $driver_id, $access_mode);
    $self->{cdtext} = undef;
}

=pod

=head2 read

  read(size)->(size, data)

Reads the next size bytes.
Similar to (if not the same as) libc's read()

The number of bytes read and the data is returned.

=cut

sub read {

    my($self,@p) = @_;
    my($size) = _rearrange(['SIZE'], @p);
    (my $data, $size) = perlcdio::read_cd($self->{cd}, $size);
    return wantarray ? ($data, $size) : $data;
}

=pod

=head2 read_data_blocks

  read_data_blocks(lsn, blocks=1)->($data, $size, $drc)

Reads a number of data sectors (AKA blocks).

lsn is sector to read, blocks is the number of bytes.

The size of the data will be a multiple of C<$perlcdio::ISO_BLOCKSIZE>.

The number of data, size of the data, and the return code status is
returned in an array context. In a scalar context just the data is
returned. C<undef> is returned as the data on error.

=cut

sub read_data_blocks {

    my($self,@p) = @_;
    my($lsn, $read_mode, $blocks) = _rearrange(['LSN', 'BLOCKS'], @p);

    $blocks = 1 if !defined($blocks);

    my $size = $perlcdio::ISO_BLOCKSIZE * $blocks;
    (my $data, $size, my $drc) =
	perlcdio::read_data_bytes($self->{cd}, $lsn,
				  $perlcdio::ISO_BLOCKSIZE,
				  $size);

    if ($perlcdio::DRIVER_OP_SUCCESS == $drc) {
	return wantarray ? ($data, $size, $drc) : $data;
    } else {
	return wantarray ? (undef, undef, $drc) : undef;
    }

}

=pod

=head2 read_sectors

  read_sectors($lsn, $read_mode, $blocks=1)->($data, $size, $drc)
  read_sectors($lsn, $read_mode, $blocks=1)->$data

Reads a number of sectors (AKA blocks).

lsn is sector to read, bytes is the number of bytes.

If read_mode is C<$perlcdio::MODE_AUDIO>, the return data size will be
a multiple of C<$perlcdio::CDIO_FRAMESIZE_RAW> i_blocks bytes.

If read_mode is C<$perlcdio::MODE_DATA>, data will be a multiple of
C<$perlcdio::ISO_BLOCKSIZE>, C<$perlcdio::M1RAW_SECTOR_SIZE> or
C<$perlcdio::M2F2_SECTOR_SIZE> bytes depending on what mode the data is
in.

If read_mode is C<$perlcdio::MODE_M2F1>, data will be a multiple of
C<$perlcdio::M2RAW_SECTOR_SIZE> bytes.

If read_mode is C<$perlcdio::MODE_M2F2>, the return data size will be a
multiple of C<$perlcdio::CD_FRAMESIZE> bytes.

The number of data, size of the data, and the return code status is
returned in an array context. In a scalar context just the data is
returned. undef is returned as the data on error.

=cut

sub read_sectors {

    my($self,@p) = @_;
    my($lsn, $read_mode, $blocks) =
	_rearrange(['LSN', 'READ_MODE', 'BLOCKS'], @p);

    $blocks = 1 if !defined($blocks);

    my $size;
    my $blocksize = $Device::Cdio::read_mode2blocksize{$read_mode};
    if (defined($blocksize)) {
	$size = $blocks * $blocksize;
    } else  {
	printf "Bad read mode %s\n", $read_mode;
	return undef;
    }
    (my $data, $size, my $drc) =
	perlcdio::read_sectors($self->{cd}, $lsn, $read_mode, $size);

    if ($perlcdio::DRIVER_OP_SUCCESS == $drc) {
	$blocks = $size / $blocksize;
	return wantarray ? ($data, $size, $drc) : $data;
    } else {
	return wantarray ? (undef, undef, $drc) : undef;
    }
}

=pod

=head2 set_blocksize

  set_blocksize(blocksize) -> $status

Set the blocksize for subsequent reads.  The operation status code is
returned.

=cut

sub set_blocksize {
    my($self,@p) = @_;
    my($blocksize, @args) = _rearrange(['BLOCKSIZE'], @p);
    return $perlcdio::BAD_PARAMETER if _extra_args(@args);
    return perlcdio::set_blocksize($self->{cd}, $blocksize);
}

=pod

=head2 set_speed

  set_speed(speed)->drc

The operation status code is returned.

=cut

sub set_speed {
    my($self,@p) = @_;
    my($speed, @args) =  _rearrange(['SPEED'], @p);
    return $perlcdio::BAD_PARAMETER if _extra_args(@args);
    return perlcdio::set_speed($self->{cd}, $speed);
}

=pod

=head2 read_pvd

$pvd = $dev->read_pvd;

Reads and returns the ISO-9660 Primary Volume Descriptor (PVD) from the disk.
You can use perliso9660::get_pvd_type($pvd) ... methods to get the values.

=cut


sub read_pvd {
    my($self,@p) = @_;
    return  perlcdio::cdio_read_pvd($self->{cd});
}


1; # Magic true value required at the end of a module

__END__

1; # Magic true value required at the end of a module

__END__

=pod

=head1 SEE ALSO

L<Device::Cdio> for the top-level module, L<Device::Cdio::Track> for
track objects, and L<Device::Cdio::ISO9660> for working with ISO9660
filesystems.

L<perlcdio> is the lower-level interface to libcdio.

L<http://www.gnu.org/software/libcdio> has documentation on
libcdio including the a manual and the API via doxygen.

=head1 AUTHORS

Rocky Bernstein

=head1 COPYRIGHT

Copyright (C) 2006, 2008, 2017 Rocky Bernstein <rocky@cpan.org>

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
