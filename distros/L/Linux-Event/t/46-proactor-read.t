use v5.36;
use Test2::V0;

use Linux::Event::Proactor;

open my $fh, '<', \$ENV{HOME} or die "failed to open scalar fh: $!";

subtest 'read success settles with expected result shape' => sub {
my $loop = Linux::Event::Proactor->new;
my @calls;

my $op = $loop->read(
    fh   => $fh,
len  => 10,
data => 'ctx',
on_complete => sub ($op, $result, $data) {
push @calls, [$op->state, $op->success, $op->failed, $result, $data];
},
);

ok($op->is_pending, 'read starts pending');

my $token = $op->_backend_token;
$loop->_fake_complete_read_success($token, 'hello');

ok($op->is_done, 'read is done');
ok($op->success, 'read success true');
ok(!$op->failed, 'read failed false');
is(
    $op->result,
{
bytes => 5,
data  => 'hello',
eof   => 0,
},
'read result stored',
);

is(scalar(@calls), 0, 'callback still deferred');
is($loop->run_once, 1, 'callback dispatched');

is(scalar(@calls), 1, 'callback ran once');
is($calls[0][0], 'done', 'callback saw done');
is($calls[0][1], 1, 'callback saw success');
is($calls[0][2], 0, 'callback saw failed false');
is(
    $calls[0][3],
{
bytes => 5,
data  => 'hello',
eof   => 0,
},
'callback got expected result',
);
is($calls[0][4], 'ctx', 'callback got data');

ok(!exists $loop->{ops_by_token}{$token}, 'op registry entry removed');
};

subtest 'read eof is success with eof flag' => sub {
my $loop = Linux::Event::Proactor->new;

my $op = $loop->read(
    fh  => $fh,
len => 10,
);

my $token = $op->_backend_token;
$loop->_fake_complete_read_success($token, '');

ok($op->is_done, 'done');
ok($op->success, 'success');
is(
    $op->result,
{
bytes => 0,
data  => '',
eof   => 1,
},
'eof result shape is correct',
);
};

subtest 'read error settles with Linux::Event::Error' => sub {
my $loop = Linux::Event::Proactor->new;
my @calls;

my $op = $loop->read(
    fh   => $fh,
len  => 10,
data => 'ctx',
on_complete => sub ($op, $result, $data) {
push @calls, [$op->state, $op->success, $op->failed, $result, $op->error, $data];
},
);

my $token = $op->_backend_token;
$loop->_fake_complete_read_error(
    $token,
code    => 104,
name    => 'ECONNRESET',
message => 'Connection reset by peer',
);

ok($op->is_done, 'done');
ok(!$op->success, 'success false');
ok($op->failed, 'failed true');
is($op->result, undef, 'no result on error');
isa_ok($op->error, ['Linux::Event::Error'], 'error object stored');

is(scalar(@calls), 0, 'callback still deferred');
is($loop->run_once, 1, 'callback dispatched');

is(scalar(@calls), 1, 'callback ran once');
is($calls[0][0], 'done', 'callback saw done');
is($calls[0][1], 0, 'callback saw success false');
is($calls[0][2], 1, 'callback saw failed true');
is($calls[0][3], undef, 'callback got undef result');
isa_ok($calls[0][4], ['Linux::Event::Error'], 'callback can inspect error object');
is($calls[0][5], 'ctx', 'callback got data');
};

subtest 'read cancel settles cancelled' => sub {
my $loop = Linux::Event::Proactor->new;

my $op = $loop->read(
    fh  => $fh,
len => 10,
);

ok($op->cancel, 'cancel accepted');
ok($op->is_cancelled, 'op is cancelled');
};

done_testing;
