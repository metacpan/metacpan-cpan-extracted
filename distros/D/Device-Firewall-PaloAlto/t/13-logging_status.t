use strict;
use warnings;
use 5.010;

use Test::More tests => 8;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::LogStatus;

use lib 't/lib';
use Local::TestSupport qw(pseudo_api_call);


#### Log status return with log collector info
my $log = pseudo_api_call(
    "./t/xml/op/logging_status/01_log_collector.xml", 
    sub { Device::Firewall::PaloAlto::Op::LogStatus->_new(@_) }
);

isa_ok( $log, 'Device::Firewall::PaloAlto::Op::LogStatus' );

my ($last_sent, $last_acked) = $log->seq_numbers( 'traffic' );
is( $last_sent, 561720752, 'Last sent seq number' );
is( $last_acked, 561720564, 'Last acked seq number' );

is( $log->total( 'traffic' ), 33105406, 'Traffic total' );



#### Log status with no log collector info
$log = pseudo_api_call(
    "./t/xml/op/logging_status/02_no_log_collector.xml", 
    sub { Device::Firewall::PaloAlto::Op::LogStatus->_new(@_) }
);

isa_ok( $log, 'Device::Firewall::PaloAlto::Op::LogStatus' );
($last_sent, $last_acked) = $log->seq_numbers( 'traffic' );
is( $last_sent, undef, 'No log collector - Last sent seq number' );
is( $last_acked, undef, 'No log collector - Last acked seq number' );

is( $log->total( 'traffic' ), 0, 'No log collector - Traffic total' );
