#!/usr/bin/perl
#
# tekcreendump.pl
#
# Gets a screendump from a Tek TDS-220 and similar, and emits the BMP
# on stdout

use Device::GPIB::Prologix;
use Getopt::Long;
my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'address=n',           # GPIB Address of the scope
     'debug',               # Show debugging info like bytes in and out
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;

my $port = '/dev/ttyUSB0';
my $address = 1;

$port = $main::opt_port if defined $main::opt_port;
$address = $main::opt_address if defined $main::opt_address;
$Device::GPIB::Prologix::debug = 1 if $main::opt_debug;

my $d = Device::GPIB::Prologix->new($port);

exit unless $d;

$d->addr($address);

# Make sure there is a Tek scope there
$d->send('id?');
my $id = $d->read();
die "No GPIB device at address $address"
    unless $id;
die "Not a Tek scope at $address: $id"
    unless $id =~ /TEK\/TDS/;

# Stop any previous hardcopy and flush the buffers
$d->send('HARDC ABO');
$d->read_binary();

# Set up destination and format we like
$d->send('HARDC:PORT GPIB');
$d->send('HARDC:LAY PORTR');
$d->send('HARDC:FORM BMP');

# Start the hardcopy to GPIB
$d->send('HARDC STAR');
sleep(3); # Need this for scope buffer to fill?
my $bmp = $d->read_binary();

# Emit to stdout
print $bmp;
$d->close();

sub usage
{
    print "usage: $0 [-h] [-port port[:baud:databits:parity:stopbits:handshake]] [-address n]\n";
    exit;
}
