use Test::More tests => 8;
use lib 't/lib';
use strict;
use warnings;
use v5.10;

BEGIN {
    use_ok 'Device::Modbus::RTU::Server';
}

# Logging prints directly to STDOUT.
close STDOUT;
my $out = '';
open STDOUT, '>', \$out or die "Could not open LOG for writing: $!";

# Send an alarm signal in one second.
# Then, send a SIGINT to stop the server.
$SIG{ALRM} = sub { kill 2, $$ };
alarm(1);

{
   package My::Unit;
   our @ISA = ('Device::Modbus::Unit');

   sub init_unit {
       my $unit = shift;

       #                Zone            addr qty   method
       #           -------------------  ---- ---  ---------
       $unit->get('holding_registers',    2,  1,  'get_addr_2');
   }
 
   sub get_addr_2 {
       my ($unit, $server, $req, $addr, $qty) = @_;
       say "Executed server routine for address 2, 1 register";
       return 6;
   }
}
 
 
my $server = Device::Modbus::RTU::Server->new(
   port      =>  '/dev/ttyACM0',
   baudrate  => 9600,
   parity    => 'none',
   log_level => 4
);
isa_ok $server, 'Device::Modbus::Server';
 
my $unit = My::Unit->new(id => 3);
$server->add_server_unit($unit);
isa_ok $unit, 'Device::Modbus::Unit';

# Add test request to fake serial port:
# Get an exception
# Request an unsupported function to unit number 3
Device::SerialPort->add_test_strings(pack 'H*', '03120003ff007676');

$server->start;

# Alarm stops the server. Test for logging:
like $out, qr/Starting server/,           'Server started';
like $out, qr/Exception while waiting/,   'Unsupported function';
like $out, qr/Device::Modbus::Exception/, 'Server returned an exception';
like $out, qr/Server is shutting down/,   'Server shuts down';
like $out, qr/Server is down/,            'Disconnection was logged';

# note $out;

done_testing();
