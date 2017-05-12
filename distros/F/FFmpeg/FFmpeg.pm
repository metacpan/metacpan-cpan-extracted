=head1 NAME

FFmpeg - Perl interface to FFmpeg, a video converter
written in C

=head1 SYNOPSIS

  use FFmpeg;

  my @media = qw(my.mpg my.avi my.mov my.mp2 my.mp3);

  #instantiate a new FFmpeg object.
  my $ff = FFmpeg->new();

  foreach my $media (@media){
    #load each media file
    $ff->input_file($media);

    #or from a URL.  note that input_url
    #enables use of other input_url_* args
    $ff->input_url('http://wherever.org/whatever.mpg');
    $ff->input_url_referrer('http://somewhere.org/overtherainbow');
    $ff->input_url_max_size('5000'); #in bytes

    #and create the stream info, accessible in a
    #FFmpeg::StreamGroup object.
    my $sg = $ff->create_streamgroup();

    #we're only interested in StreamGroups with
    #a visual component
    next unless $sg->has_video;

    #capture a frame at offset 30s into the video
    #stream in jpeg format, and get a filehandle on
    #the jpeg data stream.
    my $fh = $sg->capture_frame(
               image_format => $ff->image_format('jpeg'),
               start_time => '00:00:30'
             );

    #write the jpeg to a file.
    open(JPEG, ">$media.jpg");
    print JPEG $_ while <$fh>;
    close(JPEG);
  }

=head1 DESCRIPTION

FFmpeg (in this module, referred to here as B<FFmpeg-Perl>) is a
Perl interface to the base project FFmpeg (referred to here as
B<FFmpeg-C>).  From the B<FFmpeg-C> homepage:

B<FFmpeg-C> is a complete solution to record, convert and stream
audio and video. It includes libavcodec, the leading
audio/video codec library. B<FFmpeg-C> is developed under Linux,
but it can compiled under most OSes, including Windows.

The project is made of several components:

=over 4

=item I<ffmpeg>

a command line tool to convert one video file format to another.
It also supports grabbing and encoding in real time from a TV
card.


=item I<ffserver>

an HTTP (RTSP is being developped) multimedia
streaming server for live broadcasts. Time shifting of
live broadcast is also supported.

=item I<ffplay>

a simple media player based on SDL and on the ffmpeg libraries.

=item I<libavcodec>

a library containing all the ffmpeg audio/video encoders and
decoders. Most codecs were developed from scratch to ensure
best performances and high code reusability.

=item I<libavformat>

a library containing parsers and generators for all common
audio/video formats.

=back

B<FFmpeg-Perl> currently only supports the functionality of the
I<ffmpeg> and I<libavformat> components  of the B<FFmpeg-C>
suite.  That is, functions exist for extracting metadata from
media streams and transforming one media stream format to
another, but no effort is (yet) made to port HTTP
broadcasting or playback functionality (provided by the
I<ffserver> and I<ffplay> components, respectively).


=head1 FEEDBACK

=head2 Mailing Lists

Questions, feedback, and bug reports related to the B<FFmpeg-Perl>
interface to B<FFmpeg-C> should be sent to the Perl Video mailing
list.  Subscribe here:

L<http://sumo.genetics.ucla.edu/mailman/listinfo/perl-video/>

Questions, feedback, and bug reports related to the underlying
B<FFmpeg-C> code should be sent to the general ffmpeg user and
developer.  More information is available here:

L<http://ffmpeg.sourceforge.net/>

=head2 Reporting Bugs

See "Mailing Lists" above.

=head2 Patches

I'm very open to bug reports in the form of patches, as well as
patches that extend or add to the functionality of the library.
Please send a diff using "diff -up", along with a summary of the
purpose of the patch to the Perl Video mailing list (address
above, see "Mailing Lists").

=head1 AUTHOR

Allen Day E<lt>allenday@ucla.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2004 Allen Day

This library is released under GPL, the Gnu Public License

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a '_'.  Methods are
in alphabetical order for the most part.

=cut


# Let the code begin...


package FFmpeg;
use strict;
use vars qw($VERSION);

$VERSION = '6036';

use Data::Dumper;
use File::Temp qw(tempfile);
use HTTP::Request;
use LWP::UserAgent;
#use Time::Piece;

use FFmpeg::Codec;
use FFmpeg::Stream::Audio;
use FFmpeg::Stream::Data;
use FFmpeg::Stream::Unknown;
use FFmpeg::Stream::Video;
use FFmpeg::FileFormat;
use FFmpeg::ImageFormat;
use FFmpeg::StreamGroup;

BOOT_XS: {
	# If I inherit DynaLoader then I inherit AutoLoader
	require DynaLoader;

	# DynaLoader calls dl_load_flags as a static method.
	*dl_load_flags = DynaLoader->can('dl_load_flags');

	do {__PACKAGE__->can('bootstrap') || \&DynaLoader::bootstrap}->(__PACKAGE__,$VERSION);
}

=head2 new()

=over

=item Usage

my $obj = new FFmpeg();

=item Function

Builds a new FFmpeg object

=item Returns

an instance of FFmpeg

=item Arguments

=over

=item All optional.

all get/set methods can have their value initialized by new() if
new is called as:

  my $ff = FFmpeg->new(input_file => 'my.file', verbose => 10);

with as many/few get/set fields as you like.

=back

=back

=cut

sub new {
  my($class,%arg) = @_;

  my $self = bless {}, $class;
  $self->init(%arg);

  return $self;
}

=head2 init()

=over

=item Usage

$obj->init(%arg);

=item Function

Internal method to initialize a new FFmpeg object

=item Returns

true on success

=item Arguments

=over

=item Arguments passed to L</new()>

=back

=back

=cut

sub init {
  my($self,%arg) = @_;

  #this does some FFmpeg-internal setup.
  #loading codecs, etc.
  $self->_init_ffmpeg();

  #turn off verbosity
  $self->verbose(-1);

  #turn off overwrite prompting
  $self->_set_overwrite(1);

  foreach my $arg (keys %arg){
    $self->$arg($arg{$arg}) if $self->can($arg);
  }

  if($self->input_url && $self->input_file){
    warn "input_url and input_file both defined, using input_file"
  } elsif($self->input_url){
    my($fh,$file) = tempfile(CLEANUP=>1);
#warn $file;
    my $ua1 = LWP::UserAgent->new();
    $ua1->max_size($self->input_url_max_size);
    my $req = HTTP::Request->new('GET',$self->input_url);
    $req->header('Referer' => $self->input_url_referrer()) if $self->input_url_referrer();
    my $res = $ua1->request($req);
    if($res->is_success){
      print $fh $res->content();
      close($fh);
      $self->input_file($file);

      #now HEAD for true file size
      if($self->input_url_max_size){
        my $ua2 = LWP::UserAgent->new();
        my $req = HTTP::Request->new('HEAD',$self->input_url);
        $req->header('Referer' => $self->input_url_referrer()) if $self->input_url_referrer();
        my $res = $ua2->request($req);
        if($res->is_success){
          $self->{'input_url_content_length'} = $res->header('Content-Length');
        } else {
          warn "problem HEADing ".$self->input_url.', got error: '.$res->status_line;
        }
      }
    } else {
      warn "problem downloading ".$self->input_url.', got error: '.$res->status_line;
      $self->input_file('/dev/null');
    }
  }

  #initialize fileformat and imageformat objects
  $self->file_formats();
  $self->image_formats();

  return 1;
}

=head2 create_streamgroup()

=over

=item Usage

$sg = $obj->create_streamgroup();

=item Function

This factory method creates and returns a new
L<FFmpeg::StreamGroup|FFmpeg::StreamGroup> object for the file set by
a call to L</input_file()>.

=item Returns

A L<FFmpeg::StreamGroup|FFmpeg::StreamGroup> object, or undef on failure

=item Arguments

=over

=item None

=back

=back

=cut

sub create_streamgroup {
  my ($self) = @_;

  if(!$self->input_file){
    warn "no valid input_file, refusing to construct an FFmpeg::StreamGroup";
    return undef;
  }

  my $avfc = $self->_init_AVFormatContext;

  my $i = $self->_init_streamgroup($avfc,$self->input_file);

  my %init = ();
  if($i){
    %init = %{ $i }
  } else {
    warn "failed to initialize file ". $self->input_url || $self->input_file;
    return undef;
  }
#warn "D";

  warn "unknown initialization error: ".$init{'error'} and return undef if $init{'error'};

  my($width,$height);
  if(ref($init{stream}) eq 'HASH'){ #has streams
    foreach my $stream (keys %{ $init{stream} }){
      next unless ref($init{stream}{$stream}) eq 'HASH';

      $height ||= $init{stream}{$stream}{height};
      $width  ||= $init{stream}{$stream}{width};
      last if defined($width) and defined($height);
    }
  }

  my $video_rate;
  if(ref($init{stream}) eq 'HASH') {
    foreach my $stream (keys %{ $init{stream} }) {
      next unless ref($init{stream}{$stream}) eq 'HASH';
      my ($fr_base, $fr) = (0,0);
      $fr ||= $init{stream}{$stream}{real_frame_rate};
      #warn Dumper(\%init);
      $fr_base ||= $init{stream}{$stream}{real_frame_rate_base};

      if($fr_base > 0){
        $video_rate = $fr/$fr_base;
      }
      last if defined $video_rate;
    }
  }

  ###FIXME clean this up, i have no idea what it does anymore!
  my $nullsite = index($init{format},chr(0));
  if($nullsite != -1){
    warn "HACK WTF IS GOING ON HERE?";
    warn index($init{format},chr(0));
    warn $init{format};
    $init{format} = substr($init{format}, 0, $nullsite);
    warn $init{format};
  }

  my($duration,$h,$m,$s) = ($init{duration},0,0,0);
  $duration ||= 0;
  $init{AV_TIME_BASE} ||= 1_000_000; #1,000,000 from avcodec.h

  #time parsing is borked on max_size requests for some reason
  if($self->{input_url_max_size}){
    if($init{bit_rate}){ #we can infer duration
      $duration = int(10 * ( ($self->{input_url_content_length} || 0) / $init{bit_rate})); #FIXME is this right?

      $s = $duration ;#/ 100_000; #FIXME is this right?
      $m = int($duration / 60);
      $s %= 60;
      $h = int($m / 60);
      $m %= 60;
    }
  }

  #this special case uses the Content-Length header to set size.
  $init{file_size} = $self->{input_url_max_size} if $self->{input_url_max_size};

  #warn "\n".Data::Dumper::Dumper(\%init)."\n";
  #warn "A $duration $init{duration} $init{AV_TIME_BASE}";

  my $group = FFmpeg::StreamGroup->new(
                                       file_size   => $init{file_size},
                                       data_offset => $init{data_offset},
                                       bit_rate    => $init{bit_rate},
                                       track       => $init{track},
                                       copyright   => $init{copyright},
                                       author      => $init{author},
                                       duration    => ($duration / $init{AV_TIME_BASE}),
                                       genre       => $init{genre},
                                       album       => $init{album},
                                       comment     => $init{comment},
                                       format      => $self->file_format($init{format}),
                                       url         => $init{url},
                                       year        => $init{year},
                                       video_rate  => $video_rate,
                                       width       => $width,
                                       height      => $height,
                                       _ffmpeg     => $self,
                                      );

  foreach my $s (sort keys %{ $init{stream} }){

    # audio codecs are difficult to determine sometimes, see
    # libavcodec/dvdata.h, libavcodec/mpegaudiodectab.h, and
    # libavcodec/wmadata.h
    #
    # the best method i can see to handle this right now,
    # short of doing a lookup in these matrices (that i don't
    # understand anyway) is to leave the codec as undef.
    #
    # not the ideal solution :( FIXME

#    my $stream = FFmpeg::Stream->new(
#                                     fourcc => join('',map {chr($_)} (unpack('c*',pack('I',$init{stream}{$s}{codec_tag})))),
#                                     codec_tag => $init{stream}{$s}{codec_tag},
#                                     codec => $self->codec($init{stream}{$s}{codec_id}),
#                                    );

    my $video_rate = $init{stream}{$s}{video_rate};
    if($init{stream}{$s}{real_frame_rate_base} > 0 and defined $init{stream}{$s}{real_frame_rate}){
      #$frame_rate = $init{stream}{$s}{real_frame_rate} / $init{stream}{$s}{real_frame_rate_base};
      $video_rate = $init{stream}{$s}{real_frame_rate};
    }

    my $streamclass = 'FFmpeg::Stream::Unknown';

    my $codec_id = $init{stream}{$s}{codec_id};

    if(defined($self->codec($codec_id)) && $self->codec($codec_id)->is_video){
      $streamclass = 'FFmpeg::Stream::Video';
    } elsif(defined($self->codec($codec_id)) && $self->codec($codec_id)->is_audio){
       $streamclass = 'FFmpeg::Stream::Audio';
    }

    my $stream = $streamclass->new(
                                   bit_rate      => $init{stream}{$s}{bit_rate},
                                   channels      => $init{stream}{$s}{channels},
                                   codec         => $self->codec($init{stream}{$s}{codec_id}),
                                   codec_tag     => $init{stream}{$s}{codec_tag},
                                   duration      => ($init{stream}{$s}{duration} / $init{AV_TIME_BASE}), ###FIXME is this correct to divide?
                                   fourcc        => join('',map {chr($_)} (unpack('c*',pack('I',$init{stream}{$s}{codec_tag})))),
                                   video_rate    => $video_rate,
                                   height        => $init{stream}{$s}{height},
                                   quality       => $init{stream}{$s}{quality},
                                   sample_format => $init{stream}{$s}{sample_format},
                                   sample_rate   => $init{stream}{$s}{sample_rate},
                                   start_time    => ($init{stream}{$s}{start_time} / $init{AV_TIME_BASE}), ###FIXME is this correct to divide?
                                   width         => $init{stream}{$s}{width},
                                  );
    $group->_add_stream($stream);
  }

  #FIXME do we still need these?
  $self->_free_AVFormatContext($avfc);

  return $group;
}


=head2 codec()

=over

=item Usage

$obj->codec($codec_name);

=item Function

returns a codec by name or id.

=item Returns

A L<FFmpeg::Codec|FFmpeg::Codec> object, or undef if the codec specified could
not be found.

=item Arguments

=over

=item name (or id) of codec to retrieve

=back

=back

=cut

sub codec {
  my $self = shift;
  my $codec_name = shift;

  if($codec_name =~ /^\d+$/){
    #TODO: flip name/id hash keying if this is called more often
    foreach my $codec ($self->codecs){
      return $codec if $codec->id == $codec_name;
    }

    return undef;
  }

  return $self->{'_codecs'}{$codec_name};
}

=head2 codecs()

=over

=item Usage

@codecs = $obj->codecs();

=item Function

returns a list of all codecs B<FFmpeg-C> supports.

=item Returns

A list of L<FFmpeg::Codec|FFmpeg::Codec> objects

=item Arguments

=over

=item none, read-only

=back

=back

=cut

sub codecs {
  my ($self) = @_;

  if(! $self->{'_codecs'}){
    my %codecs = %{ $self->_codecs() };

    foreach my $cname (keys %codecs){
      my($id) = $codecs{$cname} =~ /^\[(.+)\]/;
      my $c = FFmpeg::Codec->new(
                                        id => hex($id),
                                        name => $cname,
                                        can_read  => ($codecs{$cname} =~ /D/ ? 1 : 0),
                                        can_write => ($codecs{$cname} =~ /E/ ? 1 : 0),
                                        is_audio  => ($codecs{$cname} =~ /A/ ? 1 : 0),
                                        is_video  => ($codecs{$cname} =~ /V/ ? 1 : 0),
                                       );

      $self->{'_codecs'}{$cname} = $c;
    }
  }


  return values %{ $self->{'_codecs'} };
}

=head2 format_duration_HMS()

FIXME document this

=cut

sub format_duration_HMS {
  my($self,$duration) = @_;
  #warn join "\n",caller();
  my($h,$m,$s) = (0,0,0);
  $s = $duration ;#/ 100_000; #FIXME is this right?
  $m = int($duration / 60);
  $s %= 60;
  $h = int($m / 60);
  $m %= 60;
  return sprintf('%02d:%02d:%02d',$h,$m,$s);
}

=head2 create_timepiece()

=over

=item Usage

$tp = $obj->create_timepiece("00:30:00"); #create a L<Time::Piece|Time::Piece> at 30 minutes.

=item Function

Factory method that creates a L<Time::Piece|Time::Piece> object from a string.  See
L<Time::Piece/strptime()> or details on the string format expected.  The
resolution on this object is unfortunately 1 second.  I am still looking for
a module to manipulate time in sub-second units as easily as L<Time::Piece|Time::Piece>.

=item Returns

A L<Time::Piece|Time::Piece> object on success.

=item Arguments

=over

=item time string

a string (see Usage) in HH:MM:SS format representing the time offset
of interest

=back

=back

=cut

sub create_timepiece {
  my ($self,$time) = @_;
warn join "\n",caller();
warn $time;
  if(ref($time) and $time->isa('Time::Piece')){
    return $time;
  } else {
    return Time::Piece->strptime($time, "%T");
  }
}

=head2 file_format()

=over

=item Usage

$obj->file_format($file_format_name);

=item Function

returns a file format by name.

=item Returns

A L<FFmpeg::FileFormat|FFmpeg::FileFormat> object, or undef if the file format specified could
not be found.

=item Arguments

=over

=item name of file format to retrieve

=back

=back

=cut

sub file_format {
  my $self = shift;
  my $file_formatname = shift;

  return $self->{'_file_formats'}{$file_formatname};
}

=head2 file_formats()

=over

=item Usage

@formats = $obj->file_formats();

=item Function

returns a list of all file formats B<FFmpeg-C> supports.

=item Returns

A list of L<FFmpeg::FileFormat|FFmpeg::FileFormat> objects

=item Arguments

=over

=item none, read-only

=back

=back

=cut

sub file_formats {
  my ($self) = @_;

  if(! $self->{'_file_formats'}){
    my %formats = %{ $self->_file_formats() };

    foreach my $fname (keys %formats){
      my $f = FFmpeg::FileFormat->new(
                                      name => $formats{$fname}{name},
                                      description => $formats{$fname}{description},
                                      mime_type => $formats{$fname}{mime_type},
                                      extensions => [ split(',', $formats{$fname}{extensions} || '') ],
                                      can_read  => ($formats{$fname}{capabilities} =~ /D/ ? 1 : 0),
                                      can_write => ($formats{$fname}{capabilities} =~ /E/ ? 1 : 0),
                                     );

      $self->{'_file_formats'}{$fname} = $f;
    }
  }

  return values %{ $self->{'_file_formats'} };
}

=head2 force_format()

=over

=item Usage

 $obj->force_format('mpeg');

=item Function

Force parsing of L</input_file()> or L</input_url()> as a file
of this format.  Useful for file fragments, or otherwise mangled
files

=item Returns

n/a

=item Arguments

=over

=item a format name.  FIXME should be an object.

=back

=back

=cut

sub force_format {
  my $self = shift;
  my $format = shift;
  $self->_set_format($format) if $format;

}

=head2 image_format()

=over

=item Usage

$obj->image_format($image_format_name);

=item Function

returns an image format by name.

=item Returns

A L<FFmpeg::ImageFormat|FFmpeg::ImageFormat> object, or undef if the image format specified could
not be found.

=item Arguments

=over

=item name of image format to retrieve

=back

=back

=cut

sub image_format {
  my $self = shift;
  my $image_format_name = shift;

  return $self->{'_image_formats'}{$image_format_name};
}


=head2 image_formats()

=over

=item Usage

@formats = $obj->image_formats();

=item Function

returns a list of all image formats B<FFmpeg-C> supports.

=item Returns

A list of L<FFmpeg::ImageFormat|FFmpeg::ImageFormat> objects

=item Arguments

=over

=item none, read-only

=back

=back

=cut

sub image_formats {
  my ($self) = @_;

  if(! $self->{'_image_formats'}){
    my %formats = %{ $self->_image_formats() };

    foreach my $fname (keys %formats){
      my $f = FFmpeg::ImageFormat->new(
                                              name => $fname,
                                              can_read  => ($formats{$fname} =~ /D/ ? 1 : 0),
                                              can_write => ($formats{$fname} =~ /E/ ? 1 : 0),
                                             );

      $self->{'_image_formats'}{$fname} = $f;
    }
  }

  return values %{ $self->{'_image_formats'} };
}

=head2 input_file()

=over

=item Usage

 $obj->input_file();        #get existing value

 $obj->input_file($newval); #set new value

=item Function

Holds path to file for input and processing.  This get/setter
additionally validates the existance of the file on set and
throws an exception if the file does not exist.

=item Returns

value of input_file (a scalar)

=item Arguments

=over

=item (optional) on set, a scalar

=back

=back

=cut

sub input_file {
  my $self = shift;
  my $file = shift;

  if(defined($file) and ! -f $file){
    warn qq(couldn't use file "$file": $!);
    return undef;
  }

  return $self->{'input_file'} = $file if defined($file);
  return $self->{'input_file'};
}

=head2 input_url()

=over

=item Usage

 $obj->input_url();        #get existing value

 $obj->input_url($newval); #set new value

=item Function

Holds URL of a file for input and processing.  This get/setter
is used in L</init()> to populate L</input_file()>.

=item Returns

value of input_url (a scalar)

=item Arguments

=over

=item (optional) on set, a scalar

=back

=back

=cut

sub input_url {
  my $self = shift;
  my $file = shift;

  return $self->{'input_url'} = $file if defined($file);
  return $self->{'input_url'};
}

=head2 input_url_max_size()

=over

=item Usage

 $obj->input_url_max_size();        #get existing value

 $obj->input_url_max_size($newval); #set new value

=item Function

Number of bytes to download from </input_url()>.  Note that a
second HEAD request is made to the server to determine the true
file size by inspecting the B<Content-Length> header.

=item Returns

value of input_url_max_size (a scalar)

=item Arguments

=over

=item (optional) on set, a scalar

=back

=back

=cut

sub input_url_max_size {
  my $self = shift;
  my $file = shift;

  return $self->{'input_url_max_size'} = $file if defined($file);
  return $self->{'input_url_max_size'};
}

=head2 input_url_referrer()

=over

=item Usage

 $obj->input_url_referrer();        #get existing value

 $obj->input_url_referrer($newval); #set new value

=item Function

URL to use as referrer when GETting L</input_url()>.

=item Returns

value of input_url_referrer (a scalar)

=item Arguments

=over

=item (optional) on set, a scalar

=back

=back

=cut

sub input_url_referrer {
  my $self = shift;
  my $file = shift;

  return $self->{'input_url_referrer'} = $file if defined($file);
  return $self->{'input_url_referrer'};
}

=head2 toggle_stderr()

=over

=item Usage

  $obj->toggle_stderr();

=item Function

temporarily remaps STDERR to /dev/null.  this prevents
FFmpeg-C internal writes to STDERR from making through
the FFmpeg-Perl call to the caller.

=item Returns

n/a

=item Arguments

a true value - silence STDERR
a false value - turn STDERR back on

=back

=cut

sub toggle_stderr {
  my ($self,$arg) = @_;

  if($arg){
    open(TERR,">&STDERR");
    close(STDERR);
    open(STDERR,'>/dev/null');
  } else {
    close(STDERR);
    open(STDERR,">&TERR");
    close(TERR);
  }
}

=head2 toggle_stdout()

=over

=item Usage

  $obj->toggle_stdout();

=item Function

temporarily remaps STDOUT to /dev/null.  this prevents
FFmpeg-C internal writes to STDOUT from making through
the FFmpeg-Perl call to the caller.

=item Returns

n/a

=item Arguments

a true value - silence STDOUT
a false value - turn STDOUT back on

=back

=cut

sub toggle_stdout {
  my ($self,$arg) = @_;

  if($arg){
    open(TOUT,">&STDOUT");
    close(STDOUT);
    open(STDOUT,'>/dev/null');
  } else {
    close(STDOUT);
    open(STDOUT,">&TOUT");
    close(TOUT);
  }
}

=head2 verbose()

=over

=item Usage

 $obj->verbose();        #get existing value

 $obj->verbose($newval); #set new value

=item Function

adjust the reporting of B<FFmpeg-C> to STDERR.  this is initialized
to -1, or near-silent, the lowest level of verbosity possible in
B<FFmpeg-C>.

=item Returns

value of verbose (a scalar)

=item Arguments

=over

=item (optional) on set, a scalar

=back

=back

=cut

sub verbose {
  my $self = shift;
  my $val  = shift;

  $self->{'verbose'} = $val if defined($val);
  $self->_set_verbose(int($self->{'verbose'}));
  return $self->{'verbose'};
}

=head2 _AVFormatContext()

=over

=item Usage

 $obj->_AVFormatContext();        #get existing value

 $obj->_AVFormatContext($newval); #set new value

=item Function

internal method, don't mess with this unless you know what
you're doing, and/or want to risk coredumping and/or crashing
your machine.  this holds an int-cast pointer to a B<FFmpeg-C>
AVFormatContext struct.  it is needed to manipulate the media
streams.

=item Returns

value of _AVFormatContext (a scalar)

=item Arguments

=over

=item (optional) on set, a scalar

=back

=back

=cut

sub _AVFormatContext {
  my $self = shift;

  return $self->{'_AVFormatContext'} = shift if @_;
  return $self->{'_AVFormatContext'};
}

1;
