
use strict;
use Test::More tests => 10;

BEGIN {use_ok('Device::WxM2');}

my $DEBUG = 0;
my $port;

print STDERR "\nIMPORTANT: Some of these tests will fail if your weather station is not\nconnected to the serial port and operating.  If it is not, we can skip\nthose tests.\nIs it? [no] ";
my $reply = <STDIN>;
chomp($reply);
printf STDERR "reply=%s...\n", $reply if $DEBUG > 0;

my $skipall = 0;
unless ($reply =~ /^\s*[Yy]/) {
    $skipall = 1;
}
print STDERR "\n";

SKIP: {
    skip('station is not online', 5) 
	if $skipall;

    print STDERR "What serial port is the weather station connected to? [/dev/ttyS0] ";
    $reply = <STDIN>;
    chomp($reply);
    
    $port = "/dev/ttyS0";
    unless ($reply eq "") {
	$port = $reply;
    }
    print STDERR "\n";

## Start the Tests

    my $wp;
    ok(defined ($wp = new Device::WxM2 ($port)), "Created an object");

  SKIP: {
      skip ('could not open the port', 4)
	  if (not(defined $wp));

      ok($wp->isa('Device::WxM2'), "it is the right class");

      my $results = $wp->getSerialPortReadTime();
      is($results, 5000, "read_const_time is 5000");

      my $outTemp = $wp->getOutsideTemp();
      ok(defined $outTemp, "outside temp is defined");
    SKIP: {
	skip ('outside temp not defined.', 1)
	    unless (defined $outTemp);

	ok((($outTemp > -100) and ($outTemp < 150)), "temp within normal range");
    }
  }
    undef $wp;
}

## Two tests that can run without the Weather station connected.
my $thi = Device::WxM2::calcTHI(undef, 75, 80);
is($thi, 77, "calcTHI test 1");
$thi = Device::WxM2::calcTHI(undef, 95.2, 86);
is($thi, 147.648, "calcTHI test 2: interpolation");

my $wc = Device::WxM2::windChill(undef, 25, 20);
my $wct = sprintf "%3.1f", $wc;
is($wct, 2.6, "windchill calculation");

$wc = Device::WxM2::windChill(undef, 25, 5);
$wct = sprintf "%3.1f", $wc;
is($wct, -17.4, "windchill calculation below zero");

