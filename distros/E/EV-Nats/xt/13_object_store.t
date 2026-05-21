use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_or_skip js_or_skip);
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::ObjectStore;

my ($host, $port) = nats_or_skip();
my $nats   = EV::Nats->new(host => $host, port => $port);
my $js     = EV::Nats::JetStream->new(nats => $nats, timeout => 2000);
my $bucket = "evnats_os_$$";
my $os     = EV::Nats::ObjectStore->new(js => $js, bucket => $bucket, chunk_size => 32);

js_or_skip($nats, sub { my ($d) = @_; $os->create_bucket({}, sub { $d->($_[1]) }) });

plan tests => 9;
pass 'create_bucket';

my $payload = 'A' x 100;  # 100 / 32 = 4 chunks
my ($put_info, $got, $list_names, $info);

$os->put('report.txt', $payload, sub {
    $put_info = $_[0];
    $os->get('report.txt', sub {
        $got = $_[0];
        $os->info('report.txt', sub {
            $info = $_[0];
            $os->list(sub {
                $list_names = $_[0];
                EV::break;
            });
        });
    });
});
EV::timer(10, 0, sub { EV::break });
EV::run;

is $put_info->{chunks}, 4, 'put produces 4 chunks for 100B with 32B chunk_size';
is $got, $payload, 'get returns identical payload';
ok ref($list_names) eq 'ARRAY' && (grep { $_ eq 'report.txt' } @$list_names),
   'list includes report.txt';
is $info->{name}, 'report.txt', 'info returns correct metadata' if $info;

# status: shape sanity (sealed should be 0; this client never seals)
my $status;
$os->status(sub { $status = $_[0]; EV::break });
EV::timer(3, 0, sub { EV::break });
EV::run;
ok $status && $status->{bucket} eq $bucket, 'status returns bucket name';
is $status->{sealed}, 0, 'status.sealed is 0 by default';

# Delete the object: chunks should be purged AND a tombstone written so
# subsequent info() returns undef. List still surfaces the entry (the
# tombstone keeps the metadata subject in state.subjects); info() is
# how callers filter.
my ($info_after, $list_after);
$os->delete('report.txt', sub {
    $os->info('report.txt', sub {
        $info_after = $_[0];
        $os->list(sub {
            $list_after = $_[0];
            EV::break;
        });
    });
});
EV::timer(5, 0, sub { EV::break });
EV::run;
is $info_after, undef, 'delete tombstones the object (info returns undef)';
ok ref($list_after) eq 'ARRAY' && (grep { $_ eq 'report.txt' } @$list_after),
   'list still surfaces the deleted entry (filter via info)';

$os->delete_bucket(sub { EV::break });
EV::timer(3, 0, sub { EV::break });
EV::run;
$nats->disconnect;
