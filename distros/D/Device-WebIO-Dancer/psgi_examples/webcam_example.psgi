use Dancer;
use Device::WebIO::Dancer;
use Device::WebIO;
use Device::WebIO::GStreamerVideo::V4l2;
use Plack::Builder;

use constant AUDIO_INPUT_DEVICE => 'hw:1,0';

my $webio = Device::WebIO->new;
$webio->register( 'webcam', build_video_webio() );
Device::WebIO::Dancer::init( $webio );

 
builder {
    do 'default_enable.pl';
    dance;
};



sub build_video_webio
{
    my $gstreamer = Device::WebIO::GStreamerVideo::V4l2->new({
        audio_device => AUDIO_INPUT_DEVICE,
    });
    return $gstreamer;
}
