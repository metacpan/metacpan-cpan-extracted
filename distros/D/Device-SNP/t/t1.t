# t1.t
#
# Test Device::SNP slave with a mock serial device
use Test;
use strict;
BEGIN { plan tests => 14 };

package MockSerial;
# Fake Device::Serial to supply read() and check the results of write()

# read() data, expected write() data pairs
# These were generated using the test4 database
my @testmessages =
    (
     # Attach
     [pack('H*', '1b58ffffffffffffffff0000000000000000170000000079'),
      pack('H*', '1b5800000000000000008000000000000000170000000069')],

     # Read %R2 bit
     [pack('H*', '1b58000000000000000001080100010000001700000000d3'),
      pack('H*', '1b5881000000000300010000170000000041')],

     # Read %R5 text
     [pack('H*', '1b58000000000000000001080400040000001700000000f1'),
      pack('H*', '1b588100000000090061626364656667680017000000004b')],

     # Read #R10 floating point
     [pack('H*', '1b5800000000000000000108090002000000170000000095'),
      pack('H*', '1b5881000000000500000000c1001700000000e8')],

     # Read %R3 dword
     [pack('H*', '1b58000000000000000001080200020000001700000000cd'),
      pack('H*', '1b58810000000005000000010061170000000051')],

     # Read %R word
     [pack('H*', '1b58000000000000000001080000010000001700000000db'),
      pack('H*', '1b5881000000000300000101170000000080')],

     # Read %I1
     [pack('H*', '1b580000000000000000014600000100000017000000003f'),
      pack('H*', '1b588100000000020000001700000000b1')],

     # write %I1
     [pack('H*', '1b58000000000000000002460000010001001700000000df'),
      pack('H*', '1b5882000000000000170000000007')],
     
     # Read changed %I1
     [pack('H*', '1b580000000000000000014600000100000017000000003f'),
      pack('H*', '1b58810000000002000100170000000031')],

     # write then deferred write of %R3 as dword
     [pack('H*', '1b580000000000000000020802000200000017540c000088'),
      pack('H*', '1b5882000000000000170000000007')],
     [pack('H*', '1b5401000000170000000069'),
      pack('H*', '1b5482000000000000170000000086')],

     # Read changed %R3 dword
     [pack('H*', '1b58000000000000000001080200020000001700000000cd'),
      pack('H*', '1b58810000000005000100000061170000000054')],

     );
my $testindex = 0;
my $curreadbuf = $testmessages[0][0];

sub new
{
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub read
{
    my ($self, $askfor) = @_;

    # Supply the requested chars and strip them from the front of the supply
    return ($askfor, substr($curreadbuf, 0, $askfor, ''));
}

sub write
{
    my ($self, $data) = @_;

    main::ok($data eq $testmessages[$testindex][1]);

    # Get ready to read the next message
    $testindex++;
    $curreadbuf = $testmessages[$testindex][0];
    if ($testindex >= $#testmessages)
    {
	# Finished all the test cases
	exit;
    }
    return length($data);
}

# Dummy fillers:
sub dtr_active {}
sub write_drain {}

package main;
use Device::SNP;
ok(1); # If we made it this far, we're ok.

# Some initialised registers for testing with database test4
$Device::SNP::segment{R} = [0x00, 0x01,          # %R1
		0x01, 0x00,          # %R2
		0x00, 0x00,          # %R3
		0x01, 0x00,          # %R4
		ord('a'), ord('b'),  # %R5
		ord('c'), ord('d'),  # %R6
		ord('e'), ord('f'),  # %R7
		ord('g'), ord('h'),  # %R8
		0x00, 0x00,          # %R9
		0x00, 0x00,          # %R10
		0x00, 0xc1,          # %R11
		0x00, 0x00,          # %R12
		0x00, 0x00,          # %R13
		0x00, 0x00,          # %R14
		0x00, 0x00,          # %R15
		];
$Device::SNP::segment{I}  = [0x00, 0x00];

my $s = new Device::SNP::Slave(Portname => '/dev/ttyUSB0',
		       Debug => 0);
ok($s);

$s->{port} = new MockSerial();
ok($s->{port});
$s->main_loop();
