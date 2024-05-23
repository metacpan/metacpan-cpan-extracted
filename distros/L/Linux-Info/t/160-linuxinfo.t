use warnings;
use strict;
use Test::Most 0.38;

my $module = 'Linux::Info';
require_ok($module);
can_ok( $module, qw(new set get init settime gettime) );
dies_ok { Linux::Info->new( sysinfo => 1 ) }
'cannot accept SysInfo as parameter to new';
like(
    $@,
    qr/Linux::Info::SysInfo cannot be instantiated from Linux::Info/,
    'got the expected error message when trying to use SysInfo'
);
dies_ok { Linux::Info->new( abracadabra => 1 ) }
'cannot accept invalid delta name';
like(
    $@,
    qr/invalid delta option/,
    'got the expected error message for invalid delta'
);

done_testing;
