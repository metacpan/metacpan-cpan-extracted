# test new token engine for decoding/encoding sms messages 
#
use Test::More;
BEGIN { plan tests => 7 };
use lib '../lib';
use_ok('Device::Gsm');
use_ok('Device::Gsm::Sms');

# Configure some useful parameters via environment 
my $port = $ENV{'DEV_GSM_PORT'} || '';
my $baud = $ENV{'DEV_GSM_BAUD'} || 9600;
my $pin  = $ENV{'DEV_GSM_PIN'}  || '';

SKIP: {

if( $port eq '' ) {

	print STDERR <<NOTICE;

    No serial port set up, so *NO* tests will be executed...
    To enable full testing, you can set these environment vars:

        DEV_GSM_PORT=[your serial port]    (Ex.: 'COM1', '/dev/ttyS1', ...)
        DEV_GSM_BAUD=[serial link speed]   (default is `9600')
        DEV_GSM_PIN=[nnnn]                 (your SIM PIN code, *only* if needs it)

    On most unix environments, this can be done running:

        export DEV_GSM_PORT=/dev/modem
    	export DEV_GSM_BAUD=9600
    	export DEV_GSM_PIN=1234
    	make test

    On Win32 systems, you can do:

        set DEV_GSM_PORT=COM1
        set DEV_GSM_BAUD=9600
    	set DEV_GSM_PIN=1234
        nmake test (or make test)

NOTICE

	skip( 'Serial port not set up!', 5 );

}

}

# Uh...
exit if $port eq '';

my $gsm = new Device::Gsm(port=>$port, log=>'file,storage.log', loglevel=>'debug');

# Object instance is ok?
ok( $gsm );

exit unless $gsm;

#
# Serial port connection ok?
#
my %options = ( baudrate => $baud );
$options{'pin'} = $pin if defined($pin) && $pin ne '';
ok( $gsm->connect(%options) );

my $storage = $gsm->storage();
is(undef, $storage, 'storage when starting is undefined');

my $has_cpms = $gsm->test_command('+CPMS');

$storage = $gsm->storage('SM');

if($has_cpms)
{
    is($storage, 'SM', 'storage changed to SM');
}
else
{
    is($storage, undef, 'storage not changed because phone does not support it');
}

$storage = $gsm->storage('ME');

if($has_cpms)
{
    is($storage, 'ME', 'storage changed to ME');
}
else
{
    is($storage, undef, 'storage not changed because phone does not support it');
}

