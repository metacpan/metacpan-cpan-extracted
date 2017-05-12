#!/usr/bin/perl -I ./blib/lib

use ExtUtils::MakeMaker;
use Hardware::PortScanner;

sub is_true(;$) {
    if ( $_[0] =~ /^\s*(true|t|yes|y|si|1)\s*$/i ) {
        return 1;
    }

    return 0;

}

$serial = Hardware::PortScanner->new();

@available_ports = $serial->available_com_ports();

undef $serial;

%wildcard = (
    qr/\\t/ => "\t",
    qr/\\r/ => "\r",
    qr/\\n/ => "\n",
    qr/\\f/ => "\f",
    qr/\\e/ => "\e",
);

print <<'EOT';

Manual ScanPort Test
====================

EOT

if ( scalar(@available_ports) == 0 ) {
    print <<'EOT';
   A quick scan for available ports found none available.  Some
	may exist but just be "in use".  Please check and try again.

	Manual Scan Aborted....

EOT
    exit(0);

}

print <<'EOT';
   Please Hook up a device with a known response to a request. Then
   type the request in below.  The following escaped character
   can be used to assist you.  hitting return by itself will
   cancel this test.

      \t  tab
      \n  Match newline
      \r  Match return
      \f  Match formfeed
      \a  Match alarm (bell, beep, etc)
      \e  Match escape

EOT

$request = prompt("   Request String: ");

exit(0) if $request =~ /^$/;

$orig_request = $request;

foreach $re ( keys %wildcard ) {
    $request =~ s/$re/$wildcard{$re}/g;
}

print <<'EOT';

   Now enter a reqular expression that the device will respond with
   when the above request is sent to it.

EOT

$response = prompt("   Response RE: ");

print <<'EOT';

   What ports do you want me to scan?  You can say "1, 2,3,4". The
   default is to search the available port (e.g. those that exist
   and are not in use.

EOT

@options = ();

@a = ();
COM:
while (1) {
    $ports = prompt( "   Com Ports: ", join( ",", @available_ports ) );
    if ( $ports != "ALL" ) {
        foreach $port ( split( /[\s,]+/, $ports ) ) {
            if ( $port !~ /^\d+$/ ) {
                print "\n   Whoops: Ports must be a integer (\"$port\" is invalid)\n\n";
                next COM;
            }
            push( @a, $port );
        }
        push( @options, COM => \@a );
    }
    last COM;
}

print <<'EOT';

   What baud rates do you want me to scan for?

EOT

@b = ();
BAUD:
while (1) {
    $bauds = prompt( "   Bauds: ", join( ",", ( 115200, 9600, 2400, 1200 ) ) );
    if ( $bauds != "ALL" ) {
        foreach $baud ( split( /[\s,]+/, $bauds ) ) {
            if ( $baud !~ /^\d+$/ ) {
                print "\n   Whoops: Baud must be a integer (\"$baud\" is invalid)\n\n";
                next BAUD;
            }
            push( @b, $baud );
        }
        push( @options, BAUD => \@b );
    }
    last BAUD;
}

print <<'EOT';

   What settings do you want me to use when scanning?  
	Format is [5678] [NEO] [12] then optionally [NRX]
	Example: 8N1 7E1 7o2x

EOT

SETTING:
while (1) {
    @s = ();
    $settings = uc prompt( "   Settings: ", "8N1" );
    foreach $setting ( split( /[\s,]+/, $settings ) ) {
        if ( $setting !~ /^[5678][NEO][12]([NRX])?$/i ) {
            print "\n   Whoops: Settings must be in the proper format (\"$setting\" is invalid)\n\n";
            next SETTING;
        }
        push( @s, $setting );
    }
    push( @options, SETTING => \@s );
    last SETTING;
}

print "\nScanning Hardware . . . \n";

$serial = Hardware::PortScanner->new();

$serial->scan_ports(
    @options,
    TEST_STRING    => $request,
    VALID_REPLY_RE => $response,
    MAX_WAIT       => 0.3
);
print "\n\n";

foreach $device ( $serial->found_devices ) {
    print "Device Found\n";
    print "============\n";
    print "   Com Port:  " . $device->com_port() . "\n";
    print "   Port Name: " . $device->port_name() . "\n";
    print "   BaudRate:  " . $device->baudrate() . "\n";
    print "   Setting:   " . $device->setting() . "\n";
    print "\n";
}

if ( $serial->num_found_devices == 0 ) {
    print "No Devices Found!!\n";
    print "\n";
    $serial->scan_report();
}
