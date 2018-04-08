#!perl
use v5.14;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use AnyEvent;

use constant INPUT_PIN  => 2;

my $rpi = Device::WebIO::RaspberryPi->new;
my $webio = Device::WebIO->new;
$webio->register( 'rpi', $rpi );

my $input_cv = AnyEvent->condvar;
$input_cv->cb( sub {
    my ($cv) = @_;
    my ($pin, $setting) = $cv->recv;
    say "Pin $pin set to $setting";
});
$webio->set_anyevent_condvar( 'rpi', INPUT_PIN, $input_cv );

say "Waiting for input";
my $cv = AE::cv;
$cv->recv;
