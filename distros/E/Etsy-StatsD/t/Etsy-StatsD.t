use strict;
use Test::More tests=>19;
use Test::MockModule;
use Etsy::StatsD;

my $module = Test::MockModule->new('Etsy::StatsD');
my $data;

$module->mock(
	send => sub {
		$data = $_[1];
	}
);

my $bucket = 'test';
my $update = 5;
my $time = 1234;

ok (my $statsd = Etsy::StatsD->new, "create an object" );
is ( $statsd->{sockets}[0]->peerport, 8125, 'used default port');

$data = {};
ok( $statsd->timing($bucket,$time) );
is ( $data->{$bucket}, "$time|ms");

$data = {};
ok( $statsd->increment($bucket) );
is( $data->{$bucket}, '1|c');

$data = {};
ok( $statsd->decrement($bucket) );
is( $data->{$bucket}, '-1|c');

$data = {};
ok( $statsd->update($bucket, $update) );
is( $data->{$bucket}, "$update|c");

$data = {};
ok( $statsd->update($bucket) );
is( $data->{$bucket}, "1|c");

$data = {};
ok( $statsd->update(['a','b']) );
is( $data->{a}, "1|c");
is( $data->{b}, "1|c");

ok ( my $remote = Etsy::StatsD->new('localhost', 123), 'created with host, port combo');
is ( $remote->{sockets}[0]->peerport, 123, 'used specified port');


my $err;
eval {
    my $t = Etsy::StatsD->new(['localhost:8126:igmp']);
} or do { $err = $@; };
ok( defined $err && $err =~ /Invalid protocol/, "invalid protocol dies" ) or diag($err);

eval {
    my $t = Etsy::StatsD->new(['localhost', 'localhost:8126:igmp']);
} or do { $err = $@; };
ok( defined $err && $err =~ /Invalid protocol/, "invalid protocol dies in array ref" ) or diag($err);

