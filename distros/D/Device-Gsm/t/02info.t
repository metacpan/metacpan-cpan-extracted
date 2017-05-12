# test connection with a gsm device on serial port
#
use Test;
BEGIN { plan tests => 10 };
use Device::Gsm; 
ok(1);

# Configure some useful parameters via environment 
my $port = $ENV{'DEV_GSM_PORT'} || '';
my $baud = $ENV{'DEV_GSM_BAUD'} || 9600;
my $pin  = $ENV{'DEV_GSM_PIN'}  || '';

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

	#` ?vim
	skip( 'Serial port not set up!', 1 ) for 2..10;
#	print "skip $_\n" for (2..10);

	exit;

}


my $gsm = new Device::Gsm( port => $port );

# Object instance is ok?
ok( $gsm );

exit unless $gsm;

#
# Serial port connection ok?
#
my %options = ( baudrate => $baud );
$options{'pin'} = $pin if defined($pin) && $pin ne '';
ok( $gsm->connect(%options) );

#
# Informational messages/commands
#
my @info = (
	$gsm->manufacturer()||'',
	$gsm->model()||'',
	$gsm->software_version()||'',
	$gsm->imei()||''               # no spy-ware installed here :-)
);

print 'manufacturer is [', $info[0], ']', "\n";
print 'device model is [', $info[1], ']', "\n";
print 'software ver is [', $info[2], ']', "\n";
print 'imei code    is [', $info[3], ']', "\n";

ok( $info[0] ne 'ERROR' );
ok( $info[1] ne 'ERROR' );
ok( $info[2] ne 'ERROR' );
ok( $info[3] ne 'ERROR' );
ok( $info[3] eq $gsm->serial_number );


#
# Service-center
#
ok( $gsm->service_center() );

#
# GSM network registration
#
if( $pin ne '' ) {
	ok( $gsm->register() );
} else {
	skip( 'Set your SIM PIN as "DEV_GSM_PIN" environment variable to enable!', 10); 
}


