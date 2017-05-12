# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Device::WebIO::RaspberryPi;
$Device::WebIO::RaspberryPi::VERSION = '0.009';
# ABSTRACT: Device::WebIO implementation for the Rapsberry Pi
use v5.12;
use Moo;
use namespace::clean;
use HiPi::Wiring qw( :wiring );
use HiPi::Device::I2C;
use HiPi::BCM2835::I2C qw( :all );
use HiPi::Device::SPI qw( :spi );
use GStreamer1;
use Glib qw( TRUE FALSE );
use AnyEvent;

use constant {
    TYPE_REV1         => 0,
    TYPE_REV2         => 1,
    TYPE_MODEL_B_PLUS => 2,
};

use constant {
    # maps of Rpi Pin -> Wiring lib pin
    PIN_MAP_REV1 => {
        0  => 8,
        1  => 9,
        4  => 7,
        7  => 11,
        8  => 10,
        9  => 13,
        10 => 12,
        11 => 14,
        14 => 15,
        15 => 16,
        17 => 0,
        18 => 1,
        21 => 2,
        22 => 3,
        23 => 4,
        24 => 5,
        25 => 6,
    },
    PIN_MAP_REV2 => {
        2  => 8,
        3  => 9,
        4  => 7,
        7  => 11,
        8  => 10,
        9  => 13,
        10 => 12,
        11 => 14,
        14 => 15,
        15 => 16,
        17 => 0,
        18 => 1,
        27 => 2,
        28 => 17,
        22 => 3,
        23 => 4,
        24 => 5,
        25 => 6,
        30 => 19,
        29 => 18,
        31 => 20,
    },
    PIN_MAP_MODEL_B_PLUS => {
        2  => 8,
        3  => 9,
        4  => 7,
        7  => 11,
        8  => 10,
        9  => 13,
        10 => 12,
        11 => 14,
        14 => 15,
        15 => 16,
        17 => 0,
        18 => 1,
        27 => 2,
        28 => 17,
        22 => 3,
        23 => 4,
        24 => 5,
        25 => 6,
        30 => 19,
        29 => 18,
        31 => 20,
    },
};

my %ALLOWED_VIDEO_TYPES = (
    'video/H264'      => 1,
    'video/x-msvideo' => 1,

    # mp4mux doesn't seem to like the stream-format that comes out of rpicamsrc.
    # Converting might be too slow on the Rpi.  For reference, try to get this 
    # pipeline to work (which won't link up as written):
    #
    # gst-launch-1.0 -v rpicamsrc ! h264parse ! \
    #     'video/x-h264,width=800,height=600,fps=30,stream-format=avc' ! \
    #     mp4mux ! filesink location=/tmp/output.mp4
    #
#    'video/mp4'       => 1,
);


has 'pin_desc', is => 'ro';
has '_type',    is => 'ro';
has '_pin_mode' => (
    is => 'ro',
);
has '_pin_map' => (
    is => 'ro',
);
# Note that _output_pin_value should be mapped by the Wiring library's 
# pin number, *not* the Rpi's numbering
has '_output_pin_value' => (
    is => 'ro',
);

has '_is_gstreamer_inited' => (
    is      => 'rw',
    default => sub { 0 },
);


my $CALLED_WIRING_SETUP = 0;


sub BUILDARGS
{
    my ($class, $args) = @_;
    my $rpi_type = delete($args->{type}) // $class->TYPE_REV1;

    $args->{pwm_bit_resolution} = 10;
    $args->{pwm_max_int}        = 2 ** $args->{pwm_bit_resolution};

    if( TYPE_REV1 == $rpi_type ) {
        $args->{input_pin_count}  = 26;
        $args->{output_pin_count} = 26;
        $args->{pwm_pin_count}    = 0;
        $args->{pin_desc}         = $class->_pin_desc_rev1;
        $args->{'_pin_map'}       = $class->PIN_MAP_REV1;
    }
    elsif( TYPE_REV2 == $rpi_type ) {
        $args->{input_pin_count}  = 26;
        $args->{output_pin_count} = 26;
        $args->{pwm_pin_count}    = 1;
        $args->{pin_desc}         = $class->_pin_desc_rev2;
        $args->{'_pin_map'}       = $class->PIN_MAP_REV2;
    }
    elsif( TYPE_MODEL_B_PLUS == $rpi_type ) {
        $args->{input_pin_count}  = 26;
        $args->{output_pin_count} = 26;
        $args->{pwm_pin_count}    = 1;
        $args->{pin_desc}         = $class->_pin_desc_model_b_plus;
        $args->{'_pin_map'}       = $class->PIN_MAP_MODEL_B_PLUS;
    }
    else {
        die "Don't know what to do with Rpi type '$rpi_type'\n";
    }

    $args->{'_pin_mode'}         = [ ('IN') x $args->{input_pin_count}  ];
    $args->{'_output_pin_value'} = [ (0)    x $args->{output_pin_count} ];

    HiPi::Wiring::wiringPiSetup() unless $CALLED_WIRING_SETUP;
    $CALLED_WIRING_SETUP = 1;

    return $args;
}


has 'input_pin_count', is => 'ro';
with 'Device::WebIO::Device::DigitalInput';

sub set_as_input
{
    my ($self, $rpi_pin) = @_;
    my $pin = $self->_rpi_pin_to_wiring( $rpi_pin );
    return undef if $pin < 0;
    $self->{'_pin_mode'}[$pin] = 'IN';
    HiPi::Wiring::pinMode( $pin, WPI_INPUT );
    return 1;
}

sub input_pin
{
    my ($self, $rpi_pin) = @_;
    my $pin = $self->_rpi_pin_to_wiring( $rpi_pin );
    return undef if $pin < 0;
    my $in = HiPi::Wiring::digitalRead( $pin );
    return $in;
}

sub is_set_input
{
    my ($self, $rpi_pin) = @_;
    my $pin = $self->_rpi_pin_to_wiring( $rpi_pin );
    return undef if $pin < 0;
    return 1 if $self->_pin_mode->[$pin] eq 'IN';
    return 0;
}


has 'output_pin_count', is => 'ro';
with 'Device::WebIO::Device::DigitalOutput';

sub set_as_output
{
    my ($self, $rpi_pin) = @_;
    my $pin = $self->_rpi_pin_to_wiring( $rpi_pin );
    return undef if $pin < 0;
    $self->{'_pin_mode'}[$pin] = 'OUT';
    HiPi::Wiring::pinMode( $pin, WPI_OUTPUT );
    return 1;
}

sub output_pin
{
    my ($self, $rpi_pin, $value) = @_;
    my $pin = $self->_rpi_pin_to_wiring( $rpi_pin );
    return undef if $pin < 0;
    $self->_output_pin_value->[$rpi_pin] = $value;
    HiPi::Wiring::digitalWrite( $pin, $value ? WPI_HIGH : WPI_LOW );
    return 1;
}

sub is_set_output
{
    my ($self, $rpi_pin) = @_;
    my $pin = $self->_rpi_pin_to_wiring( $rpi_pin );
    return undef if $pin < 0;
    return 1 if $self->_pin_mode->[$pin] eq 'OUT';
    return 0;
}


has 'pwm_pin_count',      is => 'ro';
has 'pwm_bit_resolution', is => 'ro';
has 'pwm_max_int',        is => 'ro';
with 'Device::WebIO::Device::PWM';

{
    my %did_set_pwm;
    sub pwm_output_int
    {
        my ($self, $rpi_pin, $val) = @_;
        my $pin = $self->_rpi_pin_to_wiring( $rpi_pin );
        return undef if $pin < 0;
        HiPi::Wiring::pinMode( $pin, WPI_PWM_OUTPUT )
            if ! exists $did_set_pwm{$pin};
        $did_set_pwm{$pin} = 1;

        HiPi::Wiring::pwmWrite( $pin, $val );
        return 1;
    }
}

has '_img_width' => (
    is      => 'rw',
    default => sub {[
        1024
    ]},
);
has '_img_height' => (
    is      => 'rw',
    default => sub {[
        768
    ]},
);
has '_img_quality' => (
    is      => 'rw',
    default => sub {[
        100
    ]},
);
with 'Device::WebIO::Device::StillImageOutput';

my %IMG_CONTENT_TYPES = (
    'image/jpeg' => 'jpeg',
    'image/gif'  => 'gif',
    'image/png'  => 'png',
);

sub img_width
{
    my ($self, $channel) = @_;
    return $self->_img_width->[$channel];
}

sub img_height
{
    my ($self, $channel) = @_;
    return $self->_img_height->[$channel];
}

sub img_quality
{
    my ($self, $channel) = @_;
    return $self->_img_quality->[$channel];
}

sub img_set_width
{
    my ($self, $channel, $width) = @_;
    $self->_img_width->[$channel] = $width;
    return 1;
}

sub img_set_height
{
    my ($self, $channel, $height) = @_;
    $self->_img_height->[$channel] = $height;
    return 1;
}

sub img_set_quality
{
    my ($self, $channel, $quality) = @_;
    $self->_img_quality->[$channel] = $quality;
    return 1;
}

sub img_channels
{
    my ($self) = @_;
    return 1;
}

sub img_allowed_content_types
{
    my ($self) = @_;
    return [ keys %IMG_CONTENT_TYPES ];
}

sub img_stream
{
    my ($self, $channel, $mime_type) = @_;
    my $imager_type = $IMG_CONTENT_TYPES{$mime_type};

    my $width   = $self->img_width( $channel );
    my $height  = $self->img_height( $channel );
    my $quality = $self->img_quality( $channel );

    $self->_init_gstreamer;

    my $loop = Glib::MainLoop->new( undef, FALSE );
    my $pipeline = GStreamer1::Pipeline->new( 'pipeline' );

    my $rpi        = GStreamer1::ElementFactory::make( rpicamsrc => 'and_who' );
    my $h264parse  = GStreamer1::ElementFactory::make( h264parse => 'are_you' );
    my $capsfilter = GStreamer1::ElementFactory::make(
        capsfilter => 'the_proud_lord_said' );
    my $avdec_h264 = GStreamer1::ElementFactory::make(
        avdec_h264 => 'that_i_should_bow_so_low' );
    my $jpegenc    = GStreamer1::ElementFactory::make( jpegenc => 'only_a_cat' );
    my $appsink    = GStreamer1::ElementFactory::make(
        appsink => 'of_a_different_coat' );

    my $caps = GStreamer1::Caps::Simple->new( 'video/x-h264',
        width  => 'Glib::Int' => 800,
        height => 'Glib::Int' => 600,
    );
    $capsfilter->set( caps => $caps );

    $appsink->set( 'max-buffers'  => 20 );
    $appsink->set( 'emit-signals' => TRUE );
    $appsink->set( 'sync'         => FALSE );


    my @link = (
        $rpi, $h264parse, $capsfilter, $avdec_h264, $jpegenc, $appsink );
    $pipeline->add( $_ ) for @link;
    foreach my $i (0 .. ($#link - 1)) {
        my $this = $link[$i];
        my $next = $link[$i+1];
        $this->link( $next );
    }

    $pipeline->set_state( "playing" );
    my $jpeg_sample = $appsink->pull_sample;
    $pipeline->set_state( "null" );

    my $jpeg_buf = $jpeg_sample->get_buffer;
    my $size = $jpeg_buf->get_size;
    my $buf = $jpeg_buf->extract_dup( 0, $size, undef, $size );

    my $scalar_buf = pack 'C*', @$buf;
    open( my $jpeg_fh, '<', \$scalar_buf )
        or die "Could not open ref to scalar: $!\n";

    return $jpeg_fh;
}


with 'Device::WebIO::Device::I2CProvider';

sub i2c_channels { 2 }

sub i2c_read
{
    my ($self, $channel, $addr, $register, $len) = @_;
    my $dev = $self->_get_i2c_device( $channel, $addr );
    my @data = $dev->bus_read( $register, $len );
    return @data;
}

sub i2c_write
{
    my ($self, $channel, $addr, $register, @data) = @_;
    my $dev = $self->_get_i2c_device( $channel, $addr );
    $dev->bus_write( $register, @data );
    return 1;
}

{
    my @DEVS;
    sub _get_i2c_device
    {
        my ($self, $channel, $addr) = @_;
        return $DEVS[$channel]{$addr} if exists $DEVS[$channel]{$addr};

        my $peri = 
            $channel == 1 ? BB_I2C_PERI_1 :
            $channel == 0 ? BB_I2C_PERI_0 :
            undef;
        my $hipi = HiPi::BCM2835::I2C->new(
            peripheral => $peri,
            address    => $addr,
        );

        $DEVS[$channel]{$addr} = $hipi;
        return $hipi;
    }
}


has '_vid_width' => (
    is      => 'rw',
    default => sub {[
        1920
    ]},
);
has '_vid_height' => (
    is      => 'rw',
    default => sub {[
       1080 
    ]},
);
has '_vid_fps' => (
    is      => 'rw',
    default => sub {[
       30
    ]},
);
has '_vid_bitrate' => (
    is      => 'rw',
    default => sub {[
       8000
    ]},
);
has '_vid_stream_callbacks' => (
    is      => 'rw',
    default => sub {[]},
);
has '_vid_stream_callback_types' => (
    is      => 'rw',
    default => sub {[]},
);
has 'cv' => (
    is      => 'rw',
    default => sub { AnyEvent->condvar },
);
has 'vid_use_audio' => (
    is      => 'rw',
    default => sub { 0 },
);
has 'vid_audio_input_device' => (
    is      => 'rw',
    default => sub { 'hw:1,0' },
);
with 'Device::WebIO::Device::VideoOutputCallback';

sub vid_channels
{
    return 1;
}

sub vid_height
{
    my ($self, $pin) = @_;
    return $self->_vid_height->[$pin];
}

sub vid_width
{
    my ($self, $pin) = @_;
    return $self->_vid_width->[$pin];
}

sub vid_fps
{
    my ($self, $pin) = @_;
    return $self->_vid_fps->[$pin];
}

sub vid_kbps
{
    my ($self, $pin) = @_;
    return $self->_vid_bitrate->[$pin];
}

sub vid_set_width
{
    my ($self, $pin, $val) = @_;
    return $self->_vid_width->[$pin] = $val;
}

sub vid_set_height
{
    my ($self, $pin, $val) = @_;
    return $self->_vid_height->[$pin] = $val;
}

sub vid_set_fps
{
    my ($self, $pin, $val) = @_;
    return $self->_vid_fps->[$pin] = $val;
}

sub vid_set_kbps
{
    my ($self, $pin, $val) = @_;
    $val *= 1024;
    return $self->_vid_bitrate->[$pin] = $val;
}

sub vid_allowed_content_types
{
    return keys %ALLOWED_VIDEO_TYPES;
}

sub vid_stream
{
    my ($self, $pin, $type) = @_;
    die "Do not support type '$type'" unless exists $ALLOWED_VIDEO_TYPES{$type};
    $self->_init_gstreamer;
    return 1;
}

sub vid_stream_callback
{
    my ($self, $pin, $type, $callback) = @_;
    die "Do not support type '$type'" unless exists $ALLOWED_VIDEO_TYPES{$type};
    $self->_vid_stream_callbacks->[$pin] = $callback;
    $self->_vid_stream_callback_types->[$pin] = $type;
    return 1;
}

sub vid_stream_begin_loop
{
    my ($self, $channel) = @_;
    my $width    = $self->vid_width( $channel );
    my $height   = $self->vid_height( $channel );
    my $fps      = $self->vid_fps( $channel );
    my $bitrate  = $self->vid_kbps( $channel );
    my $callback = $self->_vid_stream_callbacks->[$channel];
    my $type     = $self->_vid_stream_callback_types->[$channel];
    my $use_audio = $self->vid_use_audio;
    my $audio_dev = $self->vid_audio_input_device;


    $self->_init_gstreamer;
    my $cv = $self->cv;
    my $pipeline = GStreamer1::Pipeline->new( 'pipeline' );

    my $rpi        = GStreamer1::ElementFactory::make( rpicamsrc => 'and_who' );
    my $h264parse  = GStreamer1::ElementFactory::make( h264parse => 'are_you' );
    my $capsfilter = GStreamer1::ElementFactory::make(
        capsfilter => 'the_proud_lord_said' );
    my $sink    = GStreamer1::ElementFactory::make(
        fakesink => 'that_i_should_bow_so_low' );
    my $vid_queue = GStreamer1::ElementFactory::make( 'queue' => 'only_a_cat' );

    my $muxer = ($type ne 'video/H264')
        ? $self->_get_vid_mux_by_type( $type )
        : undef;

    $rpi->set( bitrate => $bitrate );

    my $caps = GStreamer1::Caps::Simple->new( 'video/x-h264',
        width  => 'Glib::Int' => $width,
        height => 'Glib::Int' => $height,
        fps    => 'Glib::Int' => $fps,
    );
    $capsfilter->set( caps => $caps );

    $sink->set( 'signal-handoffs' => TRUE );
    $sink->signal_connect(
        'handoff' => $self->_get_vid_stream_callback( $pipeline, $cv, $callback )
    );

    $pipeline->add( $muxer ) if defined $muxer;

    if( $use_audio && defined $muxer ) {
        my $audio_src = GStreamer1::ElementFactory::make(
            'alsasrc' => 'of_a_different_coat' );
        my $audio_caps = GStreamer1::ElementFactory::make(
            capsfilter => 'the_only_truth_i_know' );
        my $mp3enc = GStreamer1::ElementFactory::make(
            lamemp3enc => 'in_a_coat_of_red' );
        my $audio_queue = GStreamer1::ElementFactory::make(
            queue => 'or_a_coat_of_gold' );

        $audio_src->set( 'device' => $audio_dev );
        $mp3enc->set( 'bitrate' => 256 );

        my $caps = GStreamer1::Caps::Simple->new( 'audio/x-raw',
            rate     => 'Glib::Int'    => 44100,
            channels => 'Glib::Int'    => 1,
            format   => 'Glib::String' => 'S16LE',
        );
        $audio_caps->set( caps => $caps );

        $pipeline->add( $_ ) for $audio_src, $audio_caps, $mp3enc, $audio_queue;
        $audio_src->link(   $audio_caps  );
        $audio_caps->link(  $mp3enc      );
        $mp3enc->link(      $audio_queue );
        $audio_queue->link( $muxer       );
    }

    $pipeline->add( $_ ) for $rpi, $h264parse, $capsfilter, $sink, $vid_queue;
    $rpi->link( $h264parse );
    $h264parse->link( $capsfilter );
    $capsfilter->link( $vid_queue );
    $vid_queue->link( $muxer );
    $muxer->link( $sink );

    $pipeline->set_state( "playing" );
    $cv->recv;
    $pipeline->set_state( "null" );

    return 1;
}


sub _get_vid_stream_callback
{
    my ($self, $pipeline, $cv, $callback) = @_;

    my $full_callback = sub {
        my ($sink, $data_buf, $pad) = @_;
        my $size = $data_buf->get_size;
        my $buf  = $data_buf->extract_dup( 0, $size, undef, $size );

        $callback->( $buf );

        return 1;
    };

    return $full_callback;
}

my %MUXER_BY_TYPE = (
    'video/x-msvideo' => [
        'avimux', {},
    ],
#    'video/mp4'       => [
#        'mp4mux', {
#            streamable => TRUE,
#        },
#    ],
);
sub _get_vid_mux_by_type
{
    my ($self, $type) = @_;
    my ($muxer_name, $properties) = @{ $MUXER_BY_TYPE{$type} };
    my $muxer = GStreamer1::ElementFactory::make( $muxer_name => 'muxer' );

    for (keys %$properties) {
        $muxer->set( $_ => $properties->{$_} );
    }

    return $muxer;
}

sub _pin_desc_rev1
{
    return [qw{
        V33 V50 2 V50 3 GND 4 14 GND 15 17 18 27 GND 22 23 V33 24 10 GND 9 25
        11 8 GND 7
    }];
}

sub _pin_desc_rev2
{
    return [qw{
        V33 V50 2 V50 3 GND 4 14 GND 15 17 18 27 GND 22 23 V33 24 10 GND 9 25
        11 8 GND 7
    }];
}

sub _pin_desc_model_b_plus
{
    return [qw{
        V33 V50 2 V50 3 GND 4 14 GND 15 17 18 27 GND 22 23 V33 24 10 GND 9 25
        11 8 GND 7 GND GND 5 GND 6 12 13 GND 19 16 26 20 GND 21
    }];
}


sub _rpi_pin_to_wiring
{
    my ($self, $rpi_pin) = @_;
    my $pin = $self->_pin_map->{$rpi_pin} // -1;
    return $pin;
}


sub all_desc
{
    my ($self) = @_;
    my $pin_count = $self->input_pin_count;

    my %data = (
        UART    => 0,
        SPI     => 0,
        I2C     => 0,
        ONEWIRE => 0,
        GPIO => {
            map {
                my $function = $self->is_set_input( $_ ) ? 'IN'
                    : $self->is_set_output( $_ )         ? 'OUT'
                    : 'UNSET';
                my $value = $function eq 'IN'
                    ? $self->input_pin( $_ ) 
                    : $self->_output_pin_value->[$_];
                (defined $value)
                    ? (
                        $_ => {
                            function => $function,
                            value    => $value,
                        }
                    )
                    : ();
            } 0 .. ($pin_count - 1)
        },
    );

    return \%data;
}


sub _init_gstreamer
{
    my ($self) = @_;
    return 1 if $self->_is_gstreamer_inited;
    GStreamer1::init([ $0, @ARGV ]);
    $self->_is_gstreamer_inited( 1 );
    return 1;
}


with 'Device::WebIO::Device::SPI';

my @CHANNEL_NAMES = sort HiPi::Device::SPI->get_device_list;
has '_spi_channel_devs' => (
    is      => 'ro',
    default => sub {{}},
);


sub spi_channels { scalar @CHANNEL_NAMES }

sub spi_set_speed
{
    my ($self, $channel, $speed) = @_;
    my $dev = $self->_spi_get_dev( $channel, $speed );
    $dev->set_bus_maxspeed( $speed );
    return 1;
}

sub spi_read
{
    my ($self, $channel, $len) = @_;
    my $dev  = $self->_spi_get_dev( $channel );
    my $buf  = pack 'C*', ((0x00) x $len);
    my $recv = $dev->transfer( $buf );
    return [ unpack 'C*', $recv ];
}

sub spi_write
{
    my ($self, $channel, $data) = @_;
    my $dev  = $self->_spi_get_dev( $channel );
    $dev->transfer( $data );
    return 1;
}

sub _spi_get_dev
{
    my $self    = shift;
    my $channel = shift;
    my $channel_name = $CHANNEL_NAMES[$channel];
    return $self->_spi_channel_devs->{$channel_name}
        if exists $self->_spi_channel_devs->{$channel_name};

    my $speed = @_
        ? shift
        : SPI_SPEED_KHZ_500;

    my $dev = HiPi::Device::SPI->new(
        devicename => $channel_name,
        speed      => $speed,
    );
    $self->_spi_channel_devs->{$channel_name} = $dev;
    return $dev;
}


# TODO
#with 'Device::WebIO::Device::Serial';

1;
__END__


=head1 NAME

  Device::WebIO::RaspberyPi - Access RaspberryPi pins via Device::WebIO

=head1 SYNOPSIS

    use Device::WebIO;
    use Device::WebIO::RaspberryPi;
    
    my $webio = Device::WebIO->new;
    my $rpi = Device::WebIO::RaspberryPi->new({
    });
    $webio->register( 'foo', $rpi );
    
    my $value = $webio->digital_input( 'foo', 0 );

=head1 DESCRIPTION

Access the Raspberry Pi's pins using Device::WebIO.

=head1 CAMERA PREREQUISITES

If you intended to use the camera-related methods (e.g. C<img_stream()>), 
you will need to install the C<rpicamsrc> plugin for GStreamer.  You can 
download and compile this from:

https://github.com/thaytan/gst-rpicamsrc

=head1 VIDEO WITH AUDIO

As of version 0.009, C<Device::WebIO::RaspberryPi> has jumped into the Talkies 
era of movies by allowing audio input on video streams. You'll need a USB 
sound device that's compatible with the Raspberry Pi which can also take a 
microphone input. The attribute C<vid_audio_input_device> can be used to 
set the ALSA device for recording.

=head1 IMPLEMENTED ROLES

=over 4

=item * DigitalOutput

=item * DigitalInput

=item * PWM

=item * StillImageOutput

=item * I2CProvider

=item * VideoOutputCallback

=item * SPI

=back

=head1 ADDITONAL METHODS

=head2 cv

Returns the condvar from C<AnyEvent>, which is used for video processing.  If 
there's any events you would like to handle in between video frames, get this 
condvar and use it with C<AnyEvent>. You may also use this method as a 
setter before calling C<vid_stream_begin_loop()>.

=head2 vid_use_audio

When getting the video stream, set this flag to true to get put audio on it.  
Note that this only applies to outputs that are container formats, like AVI, 
not raw video outputs, like h.264.

Default if false.

=head2 vid_audio_input_device

If putting an audio stream on the video, this specifies the ALSA device to 
use for input. Default is 'hw:1,0'.

=head1 LICENSE

Copyright (c) 2015  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of 
      conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of
      conditions and the following disclaimer in the documentation and/or other materials 
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
