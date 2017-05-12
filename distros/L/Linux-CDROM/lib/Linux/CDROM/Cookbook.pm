package Linux::CDROM::Cookbook;
1;

=pod

=head1 NAME

Linux::CDROM cookbook - common recipes featuring your CDROM drive as its main ingredient

=head1 DESCRIPTION

There's a gazillion ways of reading the disc inside your CDROM drive. The most
high-level ones would be mounting your CD and using it as a normal directory or
- in case of an Audio-CD - using a player to play tracks. This is boring stuff
and you don't need C<Linux::CDROM> for any of that.

But when you want to write your own CD-player or -grabber, this is more like
it. You can even get at a lower level than that.

=head1 PLAYING AUDIO

C<Linux::CDROM> offers a couple of methods dealing with that. For starting
playback, you will use either C<Linux::CDROM::play_ti> (ti == B<t>rack
B<i>ndex) or C<Linux::CDROM::play_msf> (msf == B<m>inute, B<s>econd and
B<f>rame).

All playing operations happen non-blockingly. That means, you start playback
and your program does not wait till the playback is done. Instead if will
proceed with the next line.

=over 4

=item * B<Recipe 1>: I<Playing all tracks on a CD one after the other>

    use Linux::CDROM;
    
    my $cd = Linux::CDROM->new("/dev/cdrom")
        or die $Linux::CDROM::error;

    $cd->play_msf( Linux::CDROM::Addr->new(CDROM_LBA, 0),
                   Linux::CDROM::Addr->new(CDROM_LBA, $cd->num_frames) );

Since we want to play from the beginning to the end, we don't care about any
minute, second or frame and so it's most convenient to start with frame 0 and
end with the last one (as returned by C<$cd-E<gt>num_frames>.

Z<>

=item * B<Recipe 2>: I<Playing particular tracks>

    use Linux::CDROM:
    
    my $cd = Linux::CDROM->new("/dev/cdrom")
        or die $Linux::CDROM::error;

    $cd->play_ti( -from => 2, -to => 4 );

As you can see, C<$cd-E<gt>play_ti> is the right tool when you want to access
the data track-wise. For playing back just one track, make sure that the value
of I<-from> and I<-to> are the same.

Z<>

=item * B<Recipe 3>: I<Playing a range on the CD>

    use Linux::CDROM:
    
    my $cd = Linux::CDROM->new("/dev/cdrom")
        or die $Linux::CDROM::error;

    my $start = Linux::CDROM::Addr->new( CDROM_MSF, 0, 1, 0 );
    my $end   = Linux::CDROM::Addr->new( CDROM_MSF, 10, 10, 0);

    $cd->play_msf( $start, $end );

The above will play the first 10 minutes and 10 seconds of the audio. Note that
the numbering of minutes begins with 0 whereas seconds always start at 1.

Z<>

=item * B<Recipe 4>: I<Ask the drive where it is currently playing>

You will want to do something similar to that when you want to write your own
CD-player. Everyone loves process-counters and -bars:

    use Linux::CDROM;
    
    my $cd = Linux::CDROM->new("/dev/cdrom")
        or die $Linux::CDROM::error;

    $| = 1;
    
    # play whole CD again
    $cd->play_msf( Linux::CDROM::Addr->new(CDROM_LBA, 0),
                   Linux::CDROM::Addr->new(CDROM_LBA, $cd->num_frames) );

    my $frames = $cd->num_frames;
    while () {
        my $poll    = $cd->poll;
        
        break if $poll->status != CDROM_AUDIO_PLAY;
        
        my $track   = $poll->track;
        my $absaddr = $poll->abs_addr;
        my $reladdr = $poll->rel_addr;
        
        printf "\r%02i:%02i:%02i of track %02i |", $reladdr->as_msf, $track;
        my $offset = int($absaddr->addr->as_lba / $frames * 30);
        print "-" x $offset, ">", " " x (30 - $offset), "|";
    }

The above will produce an output similar to 

    03:12 of track 02 |-------------->                      |

and will update it constantly. The progress-bar indicates the total amount of
audio played of the whole CD whereas the time-counter shows the position in the
current track.

=item * B<Recipe 5>: I<Pausing, resuming etc. of playback>

Since both C<Linux::CDROM::play_msf> and C<Linux::CDROM::play_ti> work
non-blockingly, you can easily defer playback with the C<Linux::CDROM::pause>,
C<Linux::CDROM::stop> and continue it with C<Linux::CDROM::resume>:
    
    use Linux::CDROM;
    use Term::ReadKey;
    
    my $cd = Linux::CDROM->new("/dev/cdrom")
        or die $Linux::CDROM::error;
    
    ReadMode 'raw';
    
    $cd->play_ti( -from => 1, -to => 8 );
    
    {
        while (not defined (my $key = ReadKey(-1))) {
            print "\r", get_status();
            select undef, undef, undef, 0.2;
        }
        $cd->pause          if $key eq 'p';
        $cd->resume         if $key eq 'r';
        $cd->stop and last  if $key eq 's';
        last                if $key eq 'q';
        
        redo;
    }
    
    ReadMode 'restore';

    sub get_status {
        my $poll            = $cd->poll;
        my $track           = $poll->track;
        my ($min, $secs)    = $poll->rel_addr->as_msf;
        return sprintf "Track %02i at [%02i:%02i]", $track, $min, $secs;
    }

The above is actually already a useable little CD-player. It updates its status
and can be controlled through single key-strokes 'p', 'r', 's' and 'q'. When
hitting 'q' the CD will keep playing.

All events are processed in two nested infinite loops.

=item * B<Recipe 6>: I<A forking player>

The program in B<Recipe 5> can also be written using C<fork>. In the case of
C<Linux::CDROM> this is actually quite an attractive approach since you may
create an object in both your parent and your child process and access them in
both. That means that your two processes do not need to be connected through
pipes or so.

    use Linux::CDROM;
    use Term::ReadKey;

    my $cd = Linux::CDROM->new( "/dev/cdrom" )
        or die $Linux::CDROM::error;

    my $child = fork;
    if (! defined $child) {
        die "Oups, couldn't fork: $!";
    } elsif ($child) {
        parent();
    } else {
        child();
    }

    sub parent {
        $cd->play_ti( -from => 1, -to => 8 );
        ReadMode 'raw';
        {
            my $key;
            while (not defined ($key = ReadKey(-1))) {
                # do nothing this time: child handles status display
                select undef, undef, undef, 0.2;
            }
            $cd->pause              if $key eq 'p';
            $cd->resume             if $key eq 'r';
            $cd->stop               if $key eq 's';
            if ($key eq 'q') {
                kill HUP => $child;     # tell our child that we quit 
                wait;                   # wait for it
                ReadMode 'restore';
                exit;
            }
            redo;
        }
    }
        
    sub child {
        $SIG{ HUP } = sub { exit };
        $| = 1;
        my $cd = Linux::CDROM->new("/dev/cdrom");
        while () {
            my $poll            = $cd->poll;
            my $track           = $poll->track;
            my ($min, $secs)    = $poll->rel_addr->as_msf;
            printf "\rTrack %02i at [%02i:%02i]", $track, $min, $secs;
            select undef, undef, undef, 0.2;
        }
    }

The only message that can be exchanged between parent process and child is
I<sighup> which the parent process will send when it quits. The child has
installed a handler for this signal in C<$SIG{ HUP }>.

=item * B<Recipe 7>: I<Length of the last track>

For calculating the length of a given track I<i>, you'd usually substract the
address of track of track I<i> from the address of track I<i+1>. However, you
cannot do this for the last track since there is no such I<i+1> in this case.

Every CD (even non-Audio CDs) have a special track called I<Leadout> which is
always the last physical track on a CD. It has the index C<CDROM_LEADOUT> which
is usually defined to be C<0xAA>. That means that you have to substract the
address of the last track from the address of the Leadout track:

    use Linux::CDROM:
    
    my $cd = Linux::CDROM->new("/dev/cdrom") 
        or die $Linux::CDROM::error;

    my ($first, $last) = $cd->toc;
    $last = $last - $first + 1;

    my $length = $cd->toc_entry(CDROM_LEADOUT)->addr - 
                 $cd->toc_entry($last)->addr;

    printf "Length of track $track: %i frames", $length->as_lba;

=back

=head1 GRABBING AUDIO

Grabbing audio data happens through C<Linux::CDROM::read_audio>. It returns a
string of I<CD_FRAMESIZE_RAW> bytes. These data are simply PCM-encoded samples
as you find them in WAV files.

However, simply dumping these data to a file wont give you a playable WAV file.
The file is lacking an appropriate WAV header that would tell your player how
to interpret the PCM-data (as for number of channels, bitrate,
sampling-frequency). C<Linux::CDROM> contains the static method
C<Linux::CDROM::Format-E<gt>wav_header> to write a header suitable for these
PCM data.

=over 4

=item * B<Recipe 8>: I<Making a WAV file from an Audio track>

The WAV header is the first thing in a WAV file, but in this recipe we will
write it after grabbing the data to get the byte-count of the data right. We'll
leave a hole at the beginning of the file large enough to hold the header:

    use Linux::CDROM:
    use Fcntl qw/:seek/;

    my $cd = Linux::CDROM->new( "/dev/cdrom" ) 
        or die $Linux::CDROM::error;

    my $entry1 = $cd->toc_entry(1);
    my $entry2 = $cd->toc_entry(2);

    open WAV, ">track1.wav" or die $!;
    binmode WAV;
    # leave room for WAV header (44 bytes)
    seek WAV, 44, SEEK_SET;
   
    $cd->reset_datasize:
    
    for ($entry1->addr->as_lba .. $entry2->addr->as_lba-1) {
        print WAV $cd->read_audio( Linux::CDROM::Addr->new(CDROM_LBA, $_), 1);
    }

    # insert WAV header suitable for this track
    seek WAV, 0, SEEK_SET;
    print WAV Linux::CDROM::Format->wav_header( $cd->get_datasize );

Note the preliminary call to C<$cd-E<gt>reset_datasize> which resets the
internal byte-counter. When grabbing is done (or at any point you wish), the
amount of bytes read can be retrieved with C<$cd-E<gt>get_datasize>.

After the above you have a valid WAV file with 16bit, 44.1kHz and two channels
(stereo).

=back

=head1 GRABBING DATA

The most common scenario is making an ISO-image from a CD. The first thing to
understand is that one iso-image doesn't necessarily represent the whole CD.
An ISO-image represent always one session on a CD so that only a single-session
data CD fits into one image. If you have a multisession CD, you'd create an
image for each session.

=over 4

=item * B<Recipe 9>: I<Making ISO images from a CD>

This one collects all data-tracks on the CD and makes an ISO-image out of each:

    use Linux::CDROM;

    my $cd = Linux::CDROM->new("/dev/cdrom") 
        or die $Linux::CDROM::error;

    # collect all data-tracks
    my @data_tracks;
    my ($first, $last) = $cd->toc; 
    if ($cd->is_multisession) {
        foreach ($first .. $last) {
            push @data_tracks, $_ if $cd->toc_entry($_)->is_data;
        }
    }

    if (! @data_tracks) {
        die "No grabbable data tracks found";
    }
    
    grab_track($_) foreach @data_tracks;

    sub grab_track {
        my $track = shift;
        my $start = $cd->toc_entry($track);
        my $end   = $cd->toc_entry($track == $last ? CDROM_LEADOUT : $track + 1);
        
        open ISO, ">/tmp/track$track.iso" or die $!;
        binmode ISO;

        for ($start->as_lba .. $end->as_lba - 1) {
            print ISO $cd->read1( Linux::CDROM::Addr->new(CDROM_LBA, $_) );
        }
        close ISO;
    }

You can see that this is very similar to grabbing Audio tracks. In both cases
you need the start and the end of the track. The result is a file that can be
burned onto a CD-R. On a Linux system (and maybe on others as well), you can
mount the ISO-image as a regular medium:

    mount track1.iso /mnt/mountpoint -t iso9660 -o ro,loop=/dev/loop0

=back

=head1 DOING EVEN MORE

C<Linux::CDROM> offers a fairly generous subset of what your kernel permits.
There are however a few things not (yet) implemented. For instance,
DVD-handling and some of the more obscure things.

=over 4

=item * B<Recipe 10>: I<Hand-rolling ioctls>

This needs a little bit of explanation maybe. This whole module is essentially
just a huge pile of ioctl-calls. Everything about a CD is controlled that way.
This means that you can achieve the very same functionality this module offers
with Perl's C<ioctl>. C<Linux::CDROM> comes with its own C<ioctl> and you should
use this instead because it does not require you to create a filehandle. Instead
it uses its own.

Suppose you don't like C<Linux::CDROM::toc> a lot and instead want to do it by
hand. First have a look at your local F<cdrom.h> file. The ioctl you will need is

    #define CDROMREADTOCHDR		0x5305 /* Read TOC header 
                                                  (struct cdrom_tochdr) */

This also tells you that C<struct cdrom_tochdr> is somewhat involved here.
This one might look like this:

    /* This struct is used by the CDROMREADTOCHDR ioctl */
    struct cdrom_tochdr 	
    {
        __u8	cdth_trk0;	/* start track */
        __u8	cdth_trk1;	/* end track */
    };

What you don't know (you have to guess) is that B<CDROMREADTOCHDR> takes no
argument but only returns one...through the above C<struct cdrom_tochdr>.
Here's the complete code:

    use Linux::CDROM qw(:all);

    my $cd = Linux::CDROM->new("/dev/cdrom")
        or die $Linux::CDROM::error;

    $cd->ioctl(CDROMREADTOCHDR, my $buf);

    # result now stored in $buf
    # need to unpack it accordingly to the C-structure

    my ($first, $last) = unpack "C C", $buf;

The C<unpack> pattern C<"C C"> tells perl to treat the string in C<$buf> as two
unsigned char values because C<struct cdrom_tochdr> is a structure of two
C<__u8> values.
   
The next one is a little more tricky since we also have to pack some arguments 
into a string. Suppose we want to duplicate

    my $track = $cd->toc_entry(1);

Again the needed parts from C<cdrom.h>:

    #define CDROMREADTOCENTRY	0x5306 /* Read TOC entry 
                                          (struct cdrom_tocentry) */
    ...

    /* Address in MSF format */
    struct cdrom_msf0		
    {
        __u8	minute;
        __u8	second;
        __u8	frame;
    };

    /* Address in either MSF or logical format */
    union cdrom_addr		
    {
        struct cdrom_msf0	msf;
        int			lba;
    };
    
    /* This struct is used by the CDROMREADTOCENTRY ioctl */
    struct cdrom_tocentry 
    {
        __u8	cdte_track;
        __u8	cdte_adr	:4;
        __u8	cdte_ctrl	:4;
        __u8	cdte_format;
        union cdrom_addr cdte_addr;
        __u8	cdte_datamode;
    };

The tricky part is C<union cdrom_addr cdte_addr>. Since it is a union, it can
hold two different values. The two possible types are to be found in C<union
cdrom_addr>: It's either a C<struct cdrom_msf0> or an integer.

You need to tell your kernel which of these two alternatives you want by setting
C<cdrom_tocentry.cdte_format> to either I<CDROM_LBA> or I<CDROM_MSF>.

The other real problem with C<struct cdrom_tocentry> is the fact that it
contains two bit-fields (two 4-bit wide fields require 1 byte) and that you must
consider padding. On most machines, padding happens on 4-byte boundaries. If
that is the case, the structure will have these byte offsets if we assume that
your integers are 4 bytes wide and that the two bit-fields immediatly follow
C<cdte_track> (which is not necessarily the case):

    byte 0      cdte_track      
                cdte_adr        # these two need 
                cdte_ctrl       # one byte together
                cdte_format     
                <padding byte>
    byte 4      cdte_addr       
    byte 8      cdte_datamode   

Now that we have figured out a hopefully sane memory layout, we can pack the buffer so that
the ioctl hopefully returns the information belonging to track 2 in LBA format. Note that only
C<cdte_track> and C<cdte_format> need to be set. All other slots are only used for the return
values:

    my $buf = pack "C       # cdte_track
                    C       # cdte_adr + cdte_ctrl
                    C       # cdte_format
                    x       # <padding byte>
                    i       # cdte_addr
                    C       # cdte_datamode
                   ", 2, 0, CDROM_LBA;
    $cd->ioctl(CDROMREADTOCENTRY, $buf);
    my ($track, $adr_ctrl, $format, $lba, $mode) = 
        unpack "CCCxiC", $buf;
    
    print "Track $track starts at frame $lba";

The same in MSF would look like this:

    my $buf = pack "CCCxCCCxC", 2, 0, CDROM_MSF;
    $cd->ioctl(CDROMREADTOCENTRY, $buf);
    my ($track, $adr_ctrl, $format, $min, $sec, $frame, $mode) =
        unpack "CCCxCCCxC", $buf;

The C<"i"> from the LBA example had to be turned into C<"CCCx"> because our union C<cdte_addr>
    
    union cdrom_addr		
    {
        struct cdrom_msf0	msf;
        int			lba;
    };
    
now stores the address in the C<msf> slot which looks like this:

    struct cdrom_msf0		
    {
        __u8	minute;
        __u8	second;
        __u8	frame;
    };

It is three bytes wide, therefore we have another padding byte.

=back

=head1 SEE ALSO

L<Device::CDROM> for a reference to all methods and classes.

=head1 AUTHOR 

Tassilo von Parseval, E<lt>tassilo.von.parseval@rwth-aachen.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Tassilo von Parseval

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
