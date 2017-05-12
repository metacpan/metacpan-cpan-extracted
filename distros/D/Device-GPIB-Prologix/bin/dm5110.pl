#!/usr/bin/perl
#
# dm5110.pl
#
# Gets DC voltage values (or other values, see -measure) from a Tek DM5110
# Prints on stdout
# Caution: for fast response to reads, expects the DM5110 to be configured for LF not EOI
# Reads as fast as it can unless a -delay is specified.

use Device::GPIB::Prologix;
use Getopt::Long;
my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
     'delay=n',             # Delay n seconds between reads
     'timestamp',           # Print timestamp at beginning of each line
     'measure=s',           # Unit to measure. Defaults to DCV. Can be ACA,ACV,DBM,DBV,DCA,DCV,OHM,TEMP
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;

my $port = '/dev/ttyUSB0';
my $address = 1;
my $measure = 'DCV';

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Prologix::debug = 1 if $main::opt_debug;
$measure =  uc($main::opt_measure) if defined $main::opt_measure;

my $d = Device::GPIB::Prologix->new($port);

exit unless $d;

$d->addr($address);

# Make sure there is a Tek pligin there
$d->send('id?');
my $id = $d->read();
die "No GPIB device at address $address"
    unless $id;
die "Not a Tek DM5110 at $address: $id"
    unless $id =~ /TEK\/DM5110/;

$d->send($measure);
while (1)
{
    my $v = $d->read(1);
    print scalar localtime() . ': '
	if $main::opt_timestamp;

    # Remove the trailing ';'
    chop($v);
    print "$v\n";
    sleep($main::opt_delay)
	if $main::opt_delay;
}

$d->close();

sub usage
{
    print "usage: $0 [-h] [-port port[:baud:databits:parity:stopbits:handshake]] [-address n]
         [-delay n] [-timestamp]
         [-measure ACA|ACV|DBM|DBV|DCA|DCV|OHM|TEMP [range]]\n";
    exit;
}
