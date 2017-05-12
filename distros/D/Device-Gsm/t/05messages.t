# test sim card message reading functions
#
use Test::More;
BEGIN { plan tests => 3 };
use Device::Gsm; 
ok(1);

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

        skip( 'Serial port not set up!', 2 );
#        print "skip $_\n" for (2..3);

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


my @msg = $gsm->messages();
foreach my $msg ( @msg ) {
	print 'MSG ', $msg->{'index'}, "\n";
	print '  ty', $msg->type(), "\n";
	print 'PDU(', $msg->{'pdu'}, ")\n";
	print 'DEC(', ($msg->{'decoded'}||''), ")\n";
	print "-" x 72, "\n";
}

$gsm->disconnect();

}

