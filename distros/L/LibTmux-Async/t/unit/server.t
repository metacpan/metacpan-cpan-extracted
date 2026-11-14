use v5.44;
use Test2::V1;
use IO::Async::Loop::Ppoll;
use Scalar::Util qw(blessed);
my $loaded = eval { require LibTmux::Async::Server; 1 };
T2->ok($loaded, 'optional Future facade loads');
unless ($loaded) { T2->diag($@); T2->done_testing; exit }
my $loop   = IO::Async::Loop::Ppoll->new;
my $server = LibTmux::Async::Server->new(
    loop       => $loop,
    executable => '/missing-libtmux-test'
);
my $invalid = $server->new_session(name => 'x', unknown => 1);
T2->ok(
    $invalid->is_failed
        && blessed(scalar $invalid->failure)
        && scalar($invalid->failure)->isa('LibTmux::X::InvalidArgument'),
    'validation is a failed Future before dispatch'
);
my $plan = $server->explain_panes(where => {width => {-gt => 80}});
T2->ok(
    $plan->is_done && $plan->get->isa('LibTmux::QueryPlan'),
    'local explanation yields one value without process I/O'
);
my $close = $server->close;
$loop->await($close);
T2->ok($close->is_done,              'close proves empty facade cleanup');
T2->ok($server->snapshot->is_failed, 'closed facade rejects new operations');
T2->ok($loop->new_future->done('usable')->is_done, 'caller keeps the loop');
T2->done_testing;
