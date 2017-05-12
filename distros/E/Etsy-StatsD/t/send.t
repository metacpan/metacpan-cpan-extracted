use strict;
use Test::More tests=>7;
use Test::MockModule;
use Etsy::StatsD;

my $module = Test::MockModule->new('Etsy::StatsD');
my $data;

$module->mock(
	_send_to_sock => sub($$) {
		$data = $_[1];
	}
);

my $bucket = 'test';
my $update = 5;
my $time = 1234;

ok (my $statsd = Etsy::StatsD->new );

$data = undef;
ok( $statsd->timing($bucket,$time) );
is ( $data, "$bucket:$time|ms\n", 'data was sent');

$data = undef;
ok( $statsd->timing($bucket,$time, 1) );
is ( $data, "$bucket:$time|ms\n", 'data was sent');

$data = undef;
ok( $statsd->timing($bucket,$time, 0));
is ( $data, undef, 'no data was sent');
