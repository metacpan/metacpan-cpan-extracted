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

plan tests => 13;
my $guard;  # kept: an unkept EV::timer never fires
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
$guard = EV::timer(10, 0, sub { EV::break });
EV::run;

is $put_info->{chunks}, 4, 'put produces 4 chunks for 100B with 32B chunk_size';
is $got, $payload, 'get returns identical payload';
ok ref($list_names) eq 'ARRAY' && (grep { $_ eq 'report.txt' } @$list_names),
   'list includes report.txt';
is $info->{name}, 'report.txt', 'info returns correct metadata' if $info;

# status: shape sanity (sealed should be 0; this client never seals)
my $status;
$os->status(sub { $status = $_[0]; EV::break });
$guard = EV::timer(3, 0, sub { EV::break });
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
$guard = EV::timer(5, 0, sub { EV::break });
EV::run;
is $info_after, undef, 'delete tombstones the object (info returns undef)';
ok ref($list_after) eq 'ARRAY' && (grep { $_ eq 'report.txt' } @$list_after),
   'list still surfaces the deleted entry (filter via info)';

# Missing, empty, and deleted objects
my ($miss_data, $miss_err, $empty_chunks, $empty_data, $del_data, $del_err);
$os->get('no-such-object', sub {
    ($miss_data, $miss_err) = @_;
    $os->put('empty.txt', '', sub {
        $empty_chunks = $_[0] ? $_[0]->{chunks} : undef;
        $os->get('empty.txt', sub {
            ($empty_data) = @_;
            $os->get('report.txt', sub {
                ($del_data, $del_err) = @_;
                EV::break;
            });
        });
    });
});
$guard = EV::timer(8, 0, sub { EV::break });
EV::run;
ok !defined($miss_data) && !defined($miss_err), 'get on missing object is a clean miss';
is $empty_chunks, 1, 'empty object stored as one chunk';
ok defined($empty_data) && $empty_data eq '', 'empty object reads back as empty string';
ok !defined($del_data) && !defined($del_err), 'get on deleted object is a clean miss';

$os->delete_bucket(sub { EV::break });
$guard = EV::timer(3, 0, sub { EV::break });
EV::run;
$nats->disconnect;
