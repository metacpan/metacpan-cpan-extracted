package Linux::CDROM;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

use constant LINUX_CDROM_NO_ERROR          => 0;
use constant LINUX_CDROM_NO_OPEN           => 1;
use constant LINUX_CDROM_NO_CDROM          => 2;
use constant LINUX_CDROM_NO_TOCHDR         => 3;
use constant LINUX_CDROM_NO_AUDIO          => 4;
use constant LINUX_CDROM_NO_DISC_STATUS    => 5;
use constant LINUX_CDROM_IDX_OUT_OF_BOUNDS => 6;
use constant LINUX_CDROM_IOCTL_ERROR       => 7;

our %EXPORT_TAGS = ( 'all' => [ qw(
    LINUX_CDROM_NO_ERROR
    LINUX_CDROM_NO_OPEN
    LINUX_CDROM_NO_CDROM
    LINUX_CDROM_NO_TOCHDR
    LINUX_CDROM_NO_AUDIO
    LINUX_CDROM_NO_DISC_STATUS
    LINUX_CDROM_IDX_OUT_OF_BOUNDS
    LINUX_CDROM_IOCTL_ERROR
    CDC_CD_R
    CDC_CD_RW
    CDC_CLOSE_TRAY
    CDC_DRIVE_STATUS
    CDC_DVD
    CDC_DVD_R
    CDC_DVD_RAM
    CDC_GENERIC_PACKET
    CDC_IOCTLS
    CDC_LOCK
    CDC_MCN
    CDC_MEDIA_CHANGED
    CDC_MULTI_SESSION
    CDC_OPEN_TRAY
    CDC_PLAY_AUDIO
    CDC_RESET
    CDC_SELECT_DISC
    CDC_SELECT_SPEED
    CDO_AUTO_CLOSE
    CDO_AUTO_EJECT
    CDO_CHECK_TYPE
    CDO_LOCK
    CDO_USE_FFLAGS
    CDROMAUDIOBUFSIZ
    CDROMCLOSETRAY
    CDROMEJECT
    CDROMEJECT_SW
    CDROMGETSPINDOWN
    CDROMMULTISESSION
    CDROMPAUSE
    CDROMPLAYBLK
    CDROMPLAYMSF
    CDROMPLAYTRKIND
    CDROMREADALL
    CDROMREADAUDIO
    CDROMREADCOOKED
    CDROMREADMODE1
    CDROMREADMODE2
    CDROMREADRAW
    CDROMREADTOCENTRY
    CDROMREADTOCHDR
    CDROMRESET
    CDROMRESUME
    CDROMSEEK
    CDROMSETSPINDOWN
    CDROMSTART
    CDROMSTOP
    CDROMSUBCHNL
    CDROMVOLCTRL
    CDROMVOLREAD
    CDROM_AUDIO_COMPLETED
    CDROM_AUDIO_ERROR
    CDROM_AUDIO_INVALID
    CDROM_AUDIO_NO_STATUS
    CDROM_AUDIO_PAUSED
    CDROM_AUDIO_PLAY
    CDROM_CHANGER_NSLOTS
    CDROM_CLEAR_OPTIONS
    CDROM_DATA_TRACK
    CDROM_DEBUG
    CDROM_DISC_STATUS
    CDROM_DRIVE_STATUS
    CDROM_GET_CAPABILITY
    CDROM_GET_MCN
    CDROM_GET_UPC
    CDROM_LAST_WRITTEN
    CDROM_LBA
    CDROM_LEADOUT
    CDROM_LOCKDOOR
    CDROM_MAX_SLOTS
    CDROM_MEDIA_CHANGED
    CDROM_MSF
    CDROM_NEXT_WRITABLE
    CDROM_PACKET_SIZE
    CDROM_SELECT_DISC
    CDROM_SELECT_SPEED
    CDROM_SEND_PACKET
    CDROM_SET_OPTIONS
    CDSL_CURRENT
    CDSL_NONE
    CDS_AUDIO
    CDS_DATA_1
    CDS_DATA_2
    CDS_DISC_OK
    CDS_DRIVE_NOT_READY
    CDS_MIXED
    CDS_NO_DISC
    CDS_NO_INFO
    CDS_TRAY_OPEN
    CDS_XA_2_1
    CDS_XA_2_2
    CD_CHUNK_SIZE
    CD_ECC_SIZE
    CD_EDC_SIZE
    CD_FRAMES
    CD_FRAMESIZE
    CD_FRAMESIZE_RAW
    CD_FRAMESIZE_RAW0
    CD_FRAMESIZE_RAW1
    CD_FRAMESIZE_RAWER
    CD_FRAMESIZE_SUB
    CD_HEAD_SIZE
    CD_MINS
    CD_MSF_OFFSET
    CD_NUM_OF_CHUNKS
    CD_PART_MASK
    CD_PART_MAX
    CD_SECS
    CD_SUBHEAD_SIZE
    CD_SYNC_SIZE
    CD_XA_HEAD
    CD_XA_SYNC_HEAD
    CD_XA_TAIL
    CD_ZERO_SIZE
    CGC_DATA_NONE
    CGC_DATA_READ
    CGC_DATA_UNKNOWN
    CGC_DATA_WRITE
    DVD_AUTH
    DVD_AUTH_ESTABLISHED
    DVD_AUTH_FAILURE
    DVD_CGMS_RESTRICTED
    DVD_CGMS_SINGLE
    DVD_CGMS_UNRESTRICTED
    DVD_CPM_COPYRIGHTED
    DVD_CPM_NO_COPYRIGHT
    DVD_CP_SEC_EXIST
    DVD_CP_SEC_NONE
    DVD_HOST_SEND_CHALLENGE
    DVD_HOST_SEND_KEY2
    DVD_HOST_SEND_RPC_STATE
    DVD_INVALIDATE_AGID
    DVD_LAYERS
    DVD_LU_SEND_AGID
    DVD_LU_SEND_ASF
    DVD_LU_SEND_CHALLENGE
    DVD_LU_SEND_KEY1
    DVD_LU_SEND_RPC_STATE
    DVD_LU_SEND_TITLE_KEY
    DVD_READ_STRUCT
    DVD_STRUCT_BCA
    DVD_STRUCT_COPYRIGHT
    DVD_STRUCT_DISCKEY
    DVD_STRUCT_MANUFACT
    DVD_STRUCT_PHYSICAL
    DVD_WRITE_STRUCT
    EDRIVE_CANT_DO_THIS
    GPCMD_BLANK
    GPCMD_CLOSE_TRACK
    GPCMD_FLUSH_CACHE
    GPCMD_FORMAT_UNIT
    GPCMD_GET_CONFIGURATION
    GPCMD_GET_EVENT_STATUS_NOTIFICATION
    GPCMD_GET_MEDIA_STATUS
    GPCMD_GET_PERFORMANCE
    GPCMD_INQUIRY
    GPCMD_LOAD_UNLOAD
    GPCMD_MECHANISM_STATUS
    GPCMD_MODE_SELECT_10
    GPCMD_MODE_SENSE_10
    GPCMD_PAUSE_RESUME
    GPCMD_PLAYAUDIO_TI
    GPCMD_PLAY_AUDIO_10
    GPCMD_PLAY_AUDIO_MSF
    GPCMD_PLAY_AUDIO_TI
    GPCMD_PLAY_CD
    GPCMD_PREVENT_ALLOW_MEDIUM_REMOVAL
    GPCMD_READ_10
    GPCMD_READ_12
    GPCMD_READ_CD
    GPCMD_READ_CDVD_CAPACITY
    GPCMD_READ_CD_MSF
    GPCMD_READ_DISC_INFO
    GPCMD_READ_DVD_STRUCTURE
    GPCMD_READ_FORMAT_CAPACITIES
    GPCMD_READ_HEADER
    GPCMD_READ_SUBCHANNEL
    GPCMD_READ_TOC_PMA_ATIP
    GPCMD_READ_TRACK_RZONE_INFO
    GPCMD_REPAIR_RZONE_TRACK
    GPCMD_REPORT_KEY
    GPCMD_REQUEST_SENSE
    GPCMD_RESERVE_RZONE_TRACK
    GPCMD_SCAN
    GPCMD_SEEK
    GPCMD_SEND_DVD_STRUCTURE
    GPCMD_SEND_EVENT
    GPCMD_SEND_KEY
    GPCMD_SEND_OPC
    GPCMD_SET_READ_AHEAD
    GPCMD_SET_SPEED
    GPCMD_SET_STREAMING
    GPCMD_START_STOP_UNIT
    GPCMD_STOP_PLAY_SCAN
    GPCMD_TEST_UNIT_READY
    GPCMD_VERIFY_10
    GPCMD_WRITE_10
    GPCMD_WRITE_AND_VERIFY_10
    GPMODE_ALL_PAGES
    GPMODE_AUDIO_CTL_PAGE
    GPMODE_CAPABILITIES_PAGE
    GPMODE_CDROM_PAGE
    GPMODE_FAULT_FAIL_PAGE
    GPMODE_POWER_PAGE
    GPMODE_R_W_ERROR_PAGE
    GPMODE_TO_PROTECT_PAGE
    GPMODE_WRITE_PARMS_PAGE
    mechtype_caddy
    mechtype_cartridge_changer
    mechtype_individual_changer
    mechtype_popup
    mechtype_tray
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    DEVICE_CDROM_NO_ERROR
    DEVICE_CDROM_NO_OPEN
    DEVICE_CDROM_NO_CDROM
    DEVICE_CDROM_NO_TOCHDR
    DEVICE_CDROM_NO_AUDIO
    DEVICE_CDROM_NO_DISC_STATUS
    DEVICE_CDROM_IDX_OUT_OF_BOUNDS
    DEVICE_CDROM_IOCTL_ERROR
    CDC_CD_R
    CDC_CD_RW
    CDC_CLOSE_TRAY
    CDC_DRIVE_STATUS
    CDC_DVD
    CDC_DVD_R
    CDC_DVD_RAM
    CDC_GENERIC_PACKET
    CDC_IOCTLS
    CDC_LOCK
    CDC_MCN
    CDC_MEDIA_CHANGED
    CDC_MULTI_SESSION
    CDC_OPEN_TRAY
    CDC_PLAY_AUDIO
    CDC_RESET
    CDC_SELECT_DISC
    CDC_SELECT_SPEED
    CDROM_AUDIO_COMPLETED
    CDROM_AUDIO_ERROR
    CDROM_AUDIO_INVALID
    CDROM_AUDIO_NO_STATUS
    CDROM_AUDIO_PAUSED
    CDROM_AUDIO_PLAY
    CDROM_DATA_TRACK
    CDROM_LBA
    CDROM_LEADOUT
    CDROM_MAX_SLOTS
    CDROM_MSF
    CDROM_PACKET_SIZE
    CDSL_CURRENT
    CDSL_NONE
    CDS_AUDIO
    CDS_DATA_1
    CDS_DATA_2
    CDS_DISC_OK
    CDS_DRIVE_NOT_READY
    CDS_MIXED
    CDS_NO_DISC
    CDS_NO_INFO
    CDS_TRAY_OPEN
    CDS_XA_2_1
    CDS_XA_2_2
    CD_CHUNK_SIZE
    CD_ECC_SIZE
    CD_EDC_SIZE
    CD_FRAMES
    CD_FRAMESIZE
    CD_FRAMESIZE_RAW
    CD_FRAMESIZE_RAW0
    CD_FRAMESIZE_RAW1
    CD_FRAMESIZE_RAWER
    CD_FRAMESIZE_SUB
    CD_HEAD_SIZE
    CD_MINS
    CD_MSF_OFFSET
    CD_NUM_OF_CHUNKS
    CD_PART_MASK
    CD_PART_MAX
    CD_SECS
    CD_SUBHEAD_SIZE
    CD_SYNC_SIZE
    CD_XA_HEAD
    CD_XA_SYNC_HEAD
    CD_XA_TAIL
    CD_ZERO_SIZE
    CGC_DATA_NONE
    CGC_DATA_READ
    CGC_DATA_UNKNOWN
    CGC_DATA_WRITE
    EDRIVE_CANT_DO_THIS
);

our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Linux::CDROM::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Linux::CDROM', $VERSION);

1;
__END__

=head1 NAME

Linux::CDROM - Perl extension for accessing the CDROM-drive on Linux

=head1 SYNOPSIS

    use Linux::CDROM;

    my $cd = Linux::CDROM->new("/dev/cdrom") or die $Linux::CDROM::error;
    
    $cd->play_ti( -from => 1, -to => 3 );
    
    while ((my $p = $cd->poll)->status == CDROM_AUDIO_PLAY) {
        my $track = $p->track;
        my ($min, $sec) = $p->rel_addr;
        print "Playing track $track at $min:$sec\n";
    }

=head1 DESCRIPTION

This module gives you access to your CDROM drive as granted by your kernel. You
can use it for playing audio, grabbing the content off the CD in various
formats etc.

Unless otherwise stated, all methods return an undefined value to indicate an
error. You can then check the content of C<$!> to see what went wrong. Please
also see L<ERROR REPORTING> that explains how to work with
C<$Linux::CDROM::error>.

Each method states which ioctl it implements. This should help people familiar
with the various ioctls of the CDROM-drive to find their way around.

You should probably start with reading L<Linux::CDROM::Cookbook>. It explains and 
exemplifies the concepts behind this module. After that you can return to this
document as a reference for the countless methods and objects it provides.

=head1 METHODS FOR Linux::CDROM

The top-level object is always a C<Linux::CDROM>. The object is created
per-drive so you can have as many of these objects at the same time as you have
CDROM-drives.

=over 4

=item * B<new(device)>

Creates a new C<Linux::CDROM> instance. I<device> is the string pointing to
your drive, such as "/dev/cdrom" or "/dev/hdd".  This method does a
non-blocking read-only open of the device. If opening the device was
successfull, it ultimately does a B<CDROM_GET_CAPABILITY> ioctl to check
whether the device is in fact a CDROM drive.

Returns undef and sets C<$!> if something goes wrong. You should check
C<$Linux::CDROM::error> in such a case to distinguish between the above two
cases (device couldn't be opened at all or device could be opened but is not a
CDROM drive):

    my $cd = Linux::CDROM->new("/dev/hdc") or die $Linux::CDROM::error;

Please note that the constructor opens your CDROM-drive and B<not> the disc
inside it. That means that you do not really need a disc inside your drive to
open it. You only need one when you intend to carry out operations relating to
a disc, such as playing audio, grabbing data, etc.

Sets C<$Linux::CDROM::error> to one of C<LINUX_CDROM_NO_ERROR>,
C<LINUX_CDROM_NO_OPEN> or C<LINUX_CDROM_NO_CDROM>.

=item * B<close>

Shuts down the link from your program to the CDROM-drive by doing a
C<close(2)>. This does not destroy your object but quite naturally any
subsequent operation on it will fail.

You can use this to temporarily release your drive and at some other point
reopen it using C<reopen>.

Returns a true value on success, C<undef> otherwise.

=item * B<reopen>

Reopens your drive after it has been shut-down using C<close>:

    $cd->close;
    # now your CDROM is released and now interference with any
    # other application accessing the drive can happen
    ...
    $cd->reopen;
    # continue with normal operation
    
Sets C<$Linux::CDROM::error> to one of C<LINUX_CDROM_NO_ERROR> or
C<LINUX_CDROM_NO_OPEN>.

=item * B<capabilities>

Returns the capabilities of this drive as an integer by issuing the
B<CDROM_GET_CAPABILITY> ioctl. This integer is the bit-wise ORing of the
various capability-flags:

    # checks whether drive can play audio and has programmable speed
    if ($cd->capabilities & (CDC_PLAY_AUDIO | CDC_SELECT_SPEED)) {
        ...
    }

The available flags:

=over 8

=item C<CDC_CLOSE_TRAY>

Drive can close tray.

=item C<CDC_OPEN_TRAY>

Drive can open tray.

=item C<CDC_LOCK>

Drive is locked.

=item C<CDC_SELECT_SPEED>

Drive has programmable speed.

=item C<CDC_SELECT_DISC>

Drive is a juke-box.

=item C<CDC_MULTI_SESSIONS>

Drive can read multi-session discs.

=item C<CDC_MCN>

Drive can read medium-catalog-number.

=item C<CDC_MEDIA_CHANGED>

Drive reports on changed media.

=item C<CDC_PLAY_AUDIO>

Drive can play audio.

=item C<CDC_RESET>

Drive can be reset.

=item C<CDC_IOCTLS>

Drive has non-standard ioctls.

=item C<CDC_DRIVE_STATUS>

Drive can report its status.

=item C<CDC_GENERIC_PACKET>

Drive can be further controlled through generic packet commands.

=item C<CDC_CD_R>

Drive can write CD-Rs.

=item C<CDC_CD_RW>

Drive can write CD-RWs.

=item C<CDC_DVD>

Drive can read DVDs.

=item C<CDC_DVD_R>

Drive can write DVD-Rs.

=item C<CDC_DVD_RW>

Drive can write DVD_RWs.

=back

=item * B<drive_status>

Returns the current drive-status as an integer by issuing the
B<CDROM_DRIVE_STATUS> ioctl. This integer is the bit-wise ORing of the various
status-flags:

    if ($cd->drive_status & CDS_TRAY_OPEN) {
        print "Please close the tray of your drive.";
    }

The available flags:

=over 8

=item C<CDS_NO_INFO>

Drive doesn't return any info.

=item C<CDS_NO_DISC>

There is no disc in the drive.

=item C<CDS_TRAY_OPEN>

=item C<CDS_DRIVE_NOT_READY>

=item C<CDS_DISC_OK>

=back

Z<>

=item * B<disc_status>

Returns the current disc-status as an integer by issuing the
B<CDROM_DISC_STATUS> ioctl. Quite naturally, you need to have a disc inside
your drive:

    if ($cd->disc_status == CDS_AUDIO) {
        print "Disc is an audio CD";
    }

The possible return-values:

=over 8

=item C<CDS_AUDIO>

Audio CD (red book).

=item C<CDS_DATA_1>

Yellow book form 1.

=item C<CDS_DATA_2>

Yellow book form 2.

=item C<CDS_XA_2_1>

Green book form 1.

=item C<CDS_XA_2_2>

Green book form 2.

=item C<CDS_MIXED>

Often used for CDs of games. One track is data, and some other tracks are Audio.

=back

=item * B<num_frames>

Returns the total number of frames on the CD (B<CDROM_LAST_WRITTEN> ioctl).

=item * B<next_writable>

Returns the index of the next writable frame of the CD (B<CDROM_NEXT_WRITABLE> ioctl).

=item * B<get_spindown>

Returns the spindown time of your CDROM drive (B<CDROMGETSPINDOWN> ioctl).

=item * B<set_spindown(val)>

Sets the spindown time of your drive to I<val> which should be between 0 and 255. Your drive
may not support this.

=item * B<reset>

Tries to hard-reset the drive by issuing the B<CDROMRESET> ioctl:

    if ($cd->reset) {
        print "reset ok";
    } else {
        print "reset failed: $!;
    }

=item * B<eject>

Eject the CD from the drive (B<CDROMEJECT> ioctl).

=item * B<auto_eject(0|1)>

Turns on/off auto-ejecting of your drive (B<CDROMEJECT_SW> ioctl). Auto-eject
means the disc is ejected when the drive is shut down.

Auto-ejecting can be disabled again with C<$cd-E<gt>auto_eject(0)>.

=item * B<close_tray>

Closes the tray of the drive if possible (B<CDROMCLOSETRAY> ioctl).

=item * B<lock_door(0|1)>

Locks (1) or unlocks (0) the door of the drive (B<CDROM_LOCKDOOR> ioctl). 

Be aware that you can no longer open the tray of your drive when you locked
your drive and your program ends before you've done a C<< $cd->lock_door(0) >>. 

Of course, this might be what you want if you want to prevent your kid from 
accessing the CDs with your downloaded porn-collection.

=item * B<media_changed>

Returns a true value if the disc inside the drive has been changed ever since
you opened the drive. False otherwise, C<undef> on errors
(B<CDROM_MEDIA_CHANGED> ioctl).

=item * B<mcn>

Returns the medium catalog number of the CD. (B<CDROM_GET_MCN> ioctl, formerly
B<CDROM_GET_UPC>).

=item * B<get_vol>

Returns a list with four items being the volume of channel 0 throughout channel
3 (B<CDROMVOLREAD> ioctl).

=item * B<set_vol(ch0, ch1, ch2, ch3)>

Sets the volume of the four channels to the respective values of I<ch0> to
I<ch3> (B<CDROMVOLCTRL> ioctl). The values must be between 0 and 255.

As always, returns a true value on success, C<undef> otherwise (check C<$!> in
this case).

=item * B<play_msf(addr1, addr2)>

Plays the audio on the CD starting at I<addr1> and ending with I<addr2> by
issuing the B<CDROMPLAYMSF> ioctl. Both parameters must be instances of
C<Linux::CDROM::Addr>:

    # start with frame 1
    my $addr1 = Linux::CDROM::Addr->new(CDROM_LBA, 1);
    # end at 2 minutes, 2 seconds, first frame 
    my $addr2 = Linux::CDROM::Addr->new(CDROM_MSF, 2, 2, 1);

    if ( $cd->play_msf($addr1, $addr2) ) {
        print "ok, will play";
    } else {
        print "Can't play: $!";
    }

Note that any flavour (either C<CDROM_LBA> or C<CDROM_MSF>) of a
C<Linux::CDROM::Addr> object will do. See C<METHODS FOR Linux::CDROM::Addr>.

Sets C<$Linux::CDROM::error> to one of C<LINUX_CDROM_NO_ERROR>,
C<LINUX_CDROM_NO_DISC_STATUS>, C<LINUX_CDROM_NO_AUDIO> or
C<LINUX_CDROM_IOCTL_ERROR>.

=item * B<play_ti(-from =E<gt> start, -to =E<gt> end, [ -fromidx =E<gt> startidx, -toidx =E<gt> endidx ])>

Plays the audio on a CD starting with track I<start> up to (and including)
I<end>. The arguments I<startidx> and I<endidx> are optional and refer to an
offset in the start and end track respectively. It must be a value between 0
and 255.

If called with no arguments at all, it plays the whole CD.

Sets C<$Linux::CDROM::error> to one of C<LINUX_CDROM_NO_ERROR>,
C<LINUX_CDROM_NO_DISC_STATUS>, C<LINUX_CDROM_NO_AUDIO>,
C<LINUX_CDROM_NO_TOCHDR> or C<LINUX_CDROM_IOCTL_ERROR>.

=item * B<pause>

Pauses playback of your CD (B<CDROMPAUSE> ioctl).

=item * B<resume>

Resumes playback of your CD (B<CDROMRESUME> ioctl).

=item * B<start>

Starts the CDROM drive (B<CDROMSTART> ioctl).

=item * B<stop>

Stops the CDROM drive (B<CDROMSTOP> ioctl). This can be used to stop audio playback.

=item * B<read1(addr)>

Reads the frame at address I<addr> which must be a C<Linux::CDROM::Addr>
object and returns the data as one string (B<CDROMREADMODE1> ioctl). 

The returned string is always 2048 bytes long or C<undef> in case of errors.

See also L<Linux::CDROM::Cookbook>, I<Recipe 9> to find out how to make ISOs
from your CD.

=item * B<read2(addr)>

Reads the frame at address I<addr> which must be a C<Linux::CDROM::Addr>
object and returns the data as one string (B<CDROMREADMODE2> ioctl). This
assumes that the CD in the drive is in the Yellow Book Form 2 format.

The returned string is always 2336 bytes long or C<undef> in case of errors.

=item * B<read_audio(addr, nframes)>

Treats the CD as an Audio-CD (Red Book) and reads I<nframes> beginning at the
address I<addr> (B<CDROMREADAUDIO> ioctl). I<addr> must be a
C<Linux::CDROM::Addr> object.

It returns the data as one string or C<undef> in case of errors.

This can be used to grab an Audio-CD. See I<Recipe 8> in
L<Linux::CDROM::Cookbook> on how to do it the right way.

This method partially implements the upper bound checking not yet done by the
kernel (as of 2.4.21). The case that the start-address I<addr> is bigger than
the number of frames on the CD is detected. If I<addr> is smaller but
I<nframes> would cause reading beyond the last frame, no error is returned.
Instead, the method will read the data up to the last frame and return it.

Sets C<$Linux::CDROM::error> to one of C<LINUX_CDROM_NO_ERROR> or
C<DEVICE_IDX_OUT_OF_BOUNDS>.

See also L<Linux::CDROM::Cookbook> and the entries on C<get_datasize> and
C<reset_datasize>.

=item * B<read_raw(addr)>

Reads the frame at address I<addr> in raw mode. I<addr> must be a
<Linux::CDROM::Addr> object.

=item * B<reset_datasize>

Resets the internal counter of bytes read managed by a C<Linux::CDROM> drive.
This counter only counts bytes produced by C<read_audio>.

=item * B<get_datasize>

Returns the value of the internal counter of bytes read.

The existance of C<reset_datasize> and C<get_datasize> is purely for
convenience reason. It will save you from counting the number of bytes
yourself. Also, it is more efficient doing it this way.

Usage is simple:

    $cd->reset_datasize;

    # now read some audio 
    $data = $cd->read_audio(...);
    ...

    my $bytes = $cd->get_datasize;

=item * B<poll>

This queries the current state of the CDROM-drive by issuing the
B<CDROMSUBCHNL> ioctl. It returns an C<Linux::CDROM::Subchannel> object.

You will need this method if you want to write a CD-player that updates its
output accordingly to what it currently does. For instance, you can use it to
find out at which minute/second/frame the drive currently is at:

    $| = 1; # turn on auto-flush
    
    my $cd = Linux::CDROM->new("/dev/cdrom") or die $Linux::CDROM::error;
    $cd->play_ti( -from => 1, -to => 3 );

    while (my $poll = $cd->poll) {
        last if $poll->status != CDROM_AUDIO_PLAY;
        printf "\r%02i:%02i:%02i [min:sec:frame]", $poll->abs_addr->as_msf;
        select undef, undef, undef, 0.2; # sleep around 0.2 secs
    }

This method only makes sense for Audio-CD.

=item * B<toc>

Reads the TOC-header of the inserted CD (B<CDROMREADTOCHDR> ioctl). It returns
a list with two items. The first element being the start-track (most often this
will be 1) and the second item being the index of the last track.

This is the ultra-correct way of finding the number of tracks on a CD:

    my ($first, $last) = $cd->toc;
    my $num_tracks = $last - $first + 1;

=item * B<toc_entry(track)>

Reads the TOC-entry of track I<track> and returns it as a
C<Linux::CDROM::TocEntry> object by issuing the B<CDROMREADTOCENTRY> ioctl.

You will need this method when you want to find out the offset of a particular
track on a disc or when trying to figure out whether a track is data or audio:

    my $entry = $cd->toc_entry(2);
    print "Track 2 is ", $entry->is_data ? "data\n" : "audio\n";
    printf "Offset: %02i:%02i:%02i\n", $entry->addr->as_msf;

Sets C<$Linux::CDROM::error> to one of C<LINUX_CDROM_NO_ERROR>,
C<LINUX_CDROM_NO_TOCHDR>, C<LINUX_CDROM_IDX_OUT_OF_BOUNDS> or
C<LINUX_CDROM_IOCTL_ERROR>.

=item * B<is_multisession>

Returns a true value if the inserted CD is a multisession CD. False if not or C<undef> when some
error occured (B<CDROMMULTISESSION> ioctl).

=back

=head1 METHODS FOR Linux::CDROM::Addr

Specifying positions on a CD always happens through C<Linux::CDROM::Addr>
objects. There are two addressing modes that can be easily transformed into
each other so you can use whichever mode of addressing you prefer:

=over 4

=item * B<MSF>

This stands for I<M>inute/I<S>econd/I<F>rame and you specify a position on the
CD by providing these three values. This is probably the more natural addressing
for Audio-CDs. One second consists of B<CD_FRAMES> frames. This value is
currently 75.

=item * B<LBA>

This stands for I<L>ogical I<B>lock I<A>ddressing. You specify a position by
providing the frame number which starts at 0. Next frame is 1 etc. This is what
makes it so logical.

=back

This class overloads '+' and '-' so you may simply add or substract addresses. Here's how to
figure out the length of a track on a CD in number of frames:

    my $entry1 = $cd->toc_entry(2);
    my $entry2 = $cd->toc_entry(3);
    
    my $length  = ($entry2->addr - $entry1->addr)->lba;

=over 4

=item * B<new(CDROM_MSF, minute, second, frame)>

=item * B<new(CDROM_LBA, frame)>

Creates a new C<Linux::CDROM::Addr> instance in one of the two addressings.
Note that internally addressing always happens through LBA. 

Note how MSF can be transformed into LBA easily:

    my $lba = ($minute * CD_SECS + $seconds) * CD_FRAMES + $frames;

But you don't have to do that manually. This class provides the appropriate
conversion routines.

=item * B<frame>

Returns the frame of this address. This is B<not> the absolute frame but the
frame in the range of 0 and 74 according to MSF addressing.

=item * B<second>

Returns the second of this address. This is B<not> the absolute second but the second according
to MSF addressing (in the range 0 and 59).

=item * B<minute>

Returns the minute of this address.

=item * B<as_lba>

Returns the absolete frame number.

=item * B<as_msf>

Returns the address broken into minute, second and frame as a list of three values.

=back

=head1 METHODS FOR Linux::CDROM::TocEntry

This kind of object is returned by C<Linux::CDROM::toc_entry(num)>. It
represents one track on the CD. There is no separate constructor for these
objects.

=over 4

=item * B<addr>

Returns the position of this track on the disc as a C<Linux::CDROM::Addr> object.

=item * B<is_data>

Returns a true value if this track is a data track.

=item * B<is_audio>

Returns a true value if this track is an audio track.

=back

=head1 METHODS FOR Linux::CDROM::Subchannel

These objects represent the state of your drive in the moment you call C<<
$cd->poll >>.  Some operations (most notably playing Audio) on the drive are
non-blocking and your program therefore continues with the execution while your
drive is busy carrying out the desired operation. You can now ask the drive
what it is currently doing in a tight loop. The information your drives returns
to you are C<Linux::CDROM::Subchannel> objects.

=over 4

=item * B<status>

The basic status of your drive. It returns one of the following values:

=over 8

=item * B<CDROM_AUDIO_INVALID>

Audio status not supported.

=item * B<CDROM_AUDIO_PLAY>

Your drive is right now busy playing back an Audio track.

=item * B<CDROM_AUDIO_PAUSED>

Audio playback is paused. You can use C<< $cd->resume >> to continue it.

=item * B<CDROM_AUDIO_COMPLETED>

Audio playback successfully completed.

=item * B<CDROM_AUDIO_ERROR>

Audio playback stopped due to an error.

=item * B<CDROM_AUDIO_NO_STATUS>

No current audio status to return.

=back

=item * B<abs_addr>

Returns a C<Linux::CDROM::Addr> object representing the absolute position
where your drive is currently playing audio.

=item * B<rel_addr>

Returns a C<Linux::CDROM::Addr> object representing the relative position
(relative to the current track) where your drive is playing audio.

=item * B<track>

The current track your drive is playing back.

=item * B<index>

Yet another positional information. Returns an offset within the currently
playing track, probably in the range of 0 and 255.

=back

=head1 METHODS FOR Linux::CDROM::Format

This class offers some utility methods that are useful when working with CDROMs on a low level.
All methods are class-methods so there is no object here.

=over 4

=item * B<wav_header(bytes)>

This returns a WAV header suitable for I<bytes> audio data. If you put this at
the end of a file and stuff the data as returned by
C<Linux::CDROM::read_audio> behind it, you'll get a valid WAV file that can be
played back by any sane wave-player:

    # create a header for 30 million bytes of data
    my $header = Linux::CDROM::Format->wav_header( 30_000_000 );
    print WAVFILE $header;
    print WAVFILE $data;

The header specifies that the data will have a sample-rate of 44100Hz, 16 bit
resolution and two channels (which is the format of a Red Book Audio-CD).

=item * B<raw2yellow1(data)>

When I<data> was produced by a call to C<Linux::CDROM::read_raw>, this method
can be used to break down the chunk into its components according to Yellow
Book Form 1 layout. It returns them as a list six values:

    my ($sync, $head, $data, $edc, $zero, $ecc) = 
        Linux::CDROM::Format->raw2yellow1($raw_data);

=item * B<raw2yellow2(data)>

Breaks down I<data> into its components according to Yellow Book Form 2 layout.
It returns a list of three values:

    my ($sync, $head, $data) =
        Linux::CDROM::Format->raw2yellow2($raw_data);

=item * B<raw2green1(data)>

Breaks down I<data> into its components according to Green Book Form 1 layout.
It returns a list of six values:

    my ($sync, $head, $sub, $data, $edc, $ecc) =
        Linux::CDROM::Format->raw2green1($raw_data);

=item * B<raw2green2(data)>

Breaks down I<data> into its components according to Green Book Form 2 layout.
It returns a list of five values:

    my ($sync, $head, $sub, $data, $edc) =
        Linux::CDROM::Format->raw2green2($raw_data);

=back

=head1 ERROR REPORTING

All methods return C<undef> when an error occured. Furthermore,
C<Linux::CDROM> uses a simple package variable C<$Linux::CDROM::error> to
give you details on the errors that occured.

This variable is a double-typed value so it returns a string with the error
description in string context. This is useful when you want to immediately let
your script die on errors:

    my $cd = Linux::CDROM->new("/dev/hdd") 
        or die $Linux::CDROM::error;
        
However, you can also use symbolic constants to check which error occured in
order to roll your own error-handling:

    my $cd = Linux::CDROM->new("/dev/hdd");
    
    if ($Linux::CDROM::error == LINUX_CDROM_NO_ERROR) {
        print "operation successful";
    }
    elsif ($Linux::CDROM::error == LINUX_CDROM_NO_OPEN) {
        print "open failed: $!";
        # custom error handling follows
        ...
    }
    elsif ($Linux::CDROM::error == LINUX_CDROM_NO_CDROM) {
        print "device is no CDROM drive";
        # custom error handling follows
        ...
    }

C<$Linux::CDROM::error> is guaranteed to have a false value when no error
occured. So you could also write:

    my $cd = Linux::CDROM->new("/dev/hdd");
    if (! $Linux::CDROM::error) {
        print "No error occured";
    } else {
        die $!;
    }

There is a connection between this variable and C<$!> in that in case of
errors, the string stored in C<$Linux::CDROM::error> has the format
C<"error-description: $!">. 

The reason why this module doesn't only rely on C<$!> is because the errors in
C<$!> are usually those returned from the ioctl system-call. This is very often
"Input/Output error" so the content of C<$!> maybe of limited help.

See the description for each method to find out whether it sets C<$Linux::CDROM::error>.

The possible numerical values of C<$Linux::CDROM::error> are those:

=over 4

=item C<LINUX_CDROM_NO_ERROR>

No error occured.

=item C<LINUX_CDROM_NO_OPEN>

Opening the drive (not the tray!) failed.

=item C<LINUX_CDROM_NO_CDROM>

Drive is no CDROM drive.

=item C<LINUX_CDROM_NO_TOCHDR>

Couldn't read the TOC header of the CD.

=item C<LINUX_CDROM_NO_AUDIO>

CD is not an Audio-CD.

=item C<LINUX_CDROM_NO_DISC_STATUS>

Couldn't retrieve the disc-status of the CD.

=item C<LINUX_CDROM_IDX_OUT_OF_BOUNDS>

The index was out of bounds. Can for instance happen when you request
to look at a non-existent TOC-entry.

=item C<LINUX_CDROM_IOCTL_ERROR>

This is a generic error. It means that although the circumstances for the
desired operation were ok (for instance: an Audio-CD was in the drive when you
wanted to play the audio) the ioctl failed (which can happen when you request
to play beginning with minute 60 but the CD only has 40 minutes of audio).

=back

=head1 EXPORT

=head2 Constants exported by default

    CDC_CD_R
    CDC_CD_RW
    CDC_CLOSE_TRAY
    CDC_DRIVE_STATUS
    CDC_DVD
    CDC_DVD_R
    CDC_DVD_RAM
    CDC_GENERIC_PACKET
    CDC_IOCTLS
    CDC_LOCK
    CDC_MCN
    CDC_MEDIA_CHANGED
    CDC_MULTI_SESSION
    CDC_OPEN_TRAY
    CDC_PLAY_AUDIO
    CDC_RESET
    CDC_SELECT_DISC
    CDC_SELECT_SPEED
    CDROM_AUDIO_COMPLETED
    CDROM_AUDIO_ERROR
    CDROM_AUDIO_INVALID
    CDROM_AUDIO_NO_STATUS
    CDROM_AUDIO_PAUSED
    CDROM_AUDIO_PLAY
    CDROM_DATA_TRACK
    CDROM_LBA
    CDROM_LEADOUT
    CDROM_MAX_SLOTS
    CDROM_MSF
    CDROM_PACKET_SIZE
    CDSL_CURRENT
    CDSL_NONE
    CDS_AUDIO
    CDS_DATA_1
    CDS_DATA_2
    CDS_DISC_OK
    CDS_DRIVE_NOT_READY
    CDS_MIXED
    CDS_NO_DISC
    CDS_NO_INFO
    CDS_TRAY_OPEN
    CDS_XA_2_1
    CDS_XA_2_2
    CD_CHUNK_SIZE
    CD_ECC_SIZE
    CD_EDC_SIZE
    CD_FRAMES
    CD_FRAMESIZE
    CD_FRAMESIZE_RAW
    CD_FRAMESIZE_RAW0
    CD_FRAMESIZE_RAW1
    CD_FRAMESIZE_RAWER
    CD_FRAMESIZE_SUB
    CD_HEAD_SIZE
    CD_MINS
    CD_MSF_OFFSET
    CD_NUM_OF_CHUNKS
    CD_PART_MASK
    CD_PART_MAX
    CD_SECS
    CD_SUBHEAD_SIZE
    CD_SYNC_SIZE
    CD_XA_HEAD
    CD_XA_SYNC_HEAD
    CD_XA_TAIL
    CD_ZERO_SIZE
    CGC_DATA_NONE
    CGC_DATA_READ
    CGC_DATA_UNKNOWN
    CGC_DATA_WRITE
    EDRIVE_CANT_DO_THIS

=head2 Additional constants

Those (plus the default constants) can be imported on request by doing a

    use Linux::CDROM qw(:all);

I strongly doubt you will need them.

    CDROMAUDIOBUFSIZ
    CDROMCLOSETRAY
    CDROMEJECT
    CDROMEJECT_SW
    CDROMGETSPINDOWN
    CDROMMULTISESSION
    CDROMPAUSE
    CDROMPLAYBLK
    CDROMPLAYMSF
    CDROMPLAYTRKIND
    CDROMREADALL
    CDROMREADAUDIO
    CDROMREADCOOKED
    CDROMREADMODE1
    CDROMREADMODE2
    CDROMREADRAW
    CDROMREADTOCENTRY
    CDROMREADTOCHDR
    CDROMRESET
    CDROMRESUME
    CDROMSEEK
    CDROMSETSPINDOWN
    CDROMSTART
    CDROMSTOP
    CDROMSUBCHNL
    CDROMVOLCTRL
    CDROMVOLREAD
    CDROM_CHANGER_NSLOTS
    CDROM_CLEAR_OPTIONS
    CDROM_DEBUG
    CDROM_DISC_STATUS
    CDROM_DRIVE_STATUS
    CDROM_GET_CAPABILITY
    CDROM_GET_UPC
    CDROM_LAST_WRITTEN
    CDROM_LOCKDOOR
    CDROM_MEDIA_CHANGED
    CDROM_NEXT_WRITABLE
    CDROM_SELECT_DISC
    CDROM_SELECT_SPEED
    CDROM_SEND_PACKET
    CDROM_SET_OPTIONS
    DVD_AUTH
    DVD_AUTH_ESTABLISHED
    DVD_AUTH_FAILURE
    DVD_CGMS_RESTRICTED
    DVD_CGMS_SINGLE
    DVD_CGMS_UNRESTRICTED
    DVD_CPM_COPYRIGHTED
    DVD_CPM_NO_COPYRIGHT
    DVD_CP_SEC_EXIST
    DVD_CP_SEC_NONE
    DVD_HOST_SEND_CHALLENGE
    DVD_HOST_SEND_KEY2
    DVD_HOST_SEND_RPC_STATE
    DVD_INVALIDATE_AGID
    DVD_LAYERS
    DVD_LU_SEND_AGID
    DVD_LU_SEND_ASF
    DVD_LU_SEND_CHALLENGE
    DVD_LU_SEND_KEY1
    DVD_LU_SEND_RPC_STATE
    DVD_LU_SEND_TITLE_KEY
    DVD_READ_STRUCT
    DVD_STRUCT_BCA
    DVD_STRUCT_COPYRIGHT
    DVD_STRUCT_DISCKEY
    DVD_STRUCT_MANUFACT
    DVD_STRUCT_PHYSICAL
    DVD_WRITE_STRUCT
    GPCMD_BLANK
    GPCMD_CLOSE_TRACK
    GPCMD_FLUSH_CACHE
    GPCMD_FORMAT_UNIT
    GPCMD_GET_CONFIGURATION
    GPCMD_GET_EVENT_STATUS_NOTIFICATION
    GPCMD_GET_MEDIA_STATUS
    GPCMD_GET_PERFORMANCE
    GPCMD_INQUIRY
    GPCMD_LOAD_UNLOAD
    GPCMD_MECHANISM_STATUS
    GPCMD_MODE_SELECT_10
    GPCMD_MODE_SENSE_10
    GPCMD_PAUSE_RESUME
    GPCMD_PLAYAUDIO_TI
    GPCMD_PLAY_AUDIO_10
    GPCMD_PLAY_AUDIO_MSF
    GPCMD_PLAY_AUDIO_TI
    GPCMD_PLAY_CD
    GPCMD_PREVENT_ALLOW_MEDIUM_REMOVAL
    GPCMD_READ_10
    GPCMD_READ_12
    GPCMD_READ_CD
    GPCMD_READ_CDVD_CAPACITY
    GPCMD_READ_CD_MSF
    GPCMD_READ_DISC_INFO
    GPCMD_READ_DVD_STRUCTURE
    GPCMD_READ_FORMAT_CAPACITIES
    GPCMD_READ_HEADER
    GPCMD_READ_SUBCHANNEL
    GPCMD_READ_TOC_PMA_ATIP
    GPCMD_READ_TRACK_RZONE_INFO
    GPCMD_REPAIR_RZONE_TRACK
    GPCMD_REPORT_KEY
    GPCMD_REQUEST_SENSE
    GPCMD_RESERVE_RZONE_TRACK
    GPCMD_SCAN
    GPCMD_SEEK
    GPCMD_SEND_DVD_STRUCTURE
    GPCMD_SEND_EVENT
    GPCMD_SEND_KEY
    GPCMD_SEND_OPC
    GPCMD_SET_READ_AHEAD
    GPCMD_SET_SPEED
    GPCMD_SET_STREAMING
    GPCMD_START_STOP_UNIT
    GPCMD_STOP_PLAY_SCAN
    GPCMD_TEST_UNIT_READY
    GPCMD_VERIFY_10
    GPCMD_WRITE_10
    GPCMD_WRITE_AND_VERIFY_10
    GPMODE_ALL_PAGES
    GPMODE_AUDIO_CTL_PAGE
    GPMODE_CAPABILITIES_PAGE
    GPMODE_CDROM_PAGE
    GPMODE_FAULT_FAIL_PAGE
    GPMODE_POWER_PAGE
    GPMODE_R_W_ERROR_PAGE
    GPMODE_TO_PROTECT_PAGE
    GPMODE_WRITE_PARMS_PAGE
    mechtype_caddy
    mechtype_cartridge_changer
    mechtype_individual_changer
    mechtype_popup
    mechtype_tray

=head1 LIMITATIONS

This one most definitely only works for Linux so far.

All the DVD-related controls are unimplemented.

Other unimplemented ioctls are:

    CDROMREADCOOKED
    CDROMSEEK
    CDROMPLAYBLK
    CDROMREADALL
    CDROM_SET_OPTIONS
    CDROM_CLEAR_OPTIONS
    CDROM_DEBUG
    CDROM_SEND_PACKET

See L<Linux::CDROM::Cookbook>, B<Recipe 10> on how to circumvent this
limitation.

=head1 BUGS

Possibly. One problem is that there's no sensible way to equip the module with
tests and so there are none when you install it.

=head1 SEE ALSO

For a more practical approach to, see L<Linux::CDROM::Cookbook>.

Since this module allows you to access your drive on a very low-level (as low
as the kernel permits it), it may help to google a bit for general issues, such
as track layout on a CDROM etc.

=head1 AUTHOR

Tassilo von Parseval, E<lt>tassilo.von.parseval@rwth-aachen.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Tassilo von Parseval

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
