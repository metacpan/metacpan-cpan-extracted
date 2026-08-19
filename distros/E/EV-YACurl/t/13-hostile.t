use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 12;
use TestServer;
use EV;
use EV::YACurl ':constants';

TestServer::watchdog(120);

my $server = TestServer->new(sub { (200, [], 'ok') });
my $base = $server->base_url;

sub run_one {
    my ($callback, %options) = @_;
    my $client = EV::YACurl->new({});
    my $done = 0;

    $client->request(sub { $callback->($client, @_); $done = 1 }, {
        CURLOPT_URL => "$base/",
        CURLOPT_WRITEFUNCTION => sub { },
        %options,
    });
    EV::run until $done;

    return $done;
}

# Writing through @_ must not reach anything the binding still owns.
ok(run_one(sub { $_[1] = undef }), 'clearing the response in the callback is survivable');

ok(run_one(sub { $_[1]->DESTROY if $_[1] }), 'an explicit response DESTROY in the callback is survivable');

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    ok(run_one(sub { $_[0]->DESTROY }), 'an explicit client DESTROY in the callback is survivable');
    ok((grep { /still in a callback/ } @warnings), 'and is refused with a warning');
}

# A __WARN__ handler that dies must not unwind through libcurl and wedge the
# multi handle: turning warnings into failures is a common test idiom.
{
    my $client = EV::YACurl->new({});
    my ($first, $second) = (0, 0);

    {
        local $SIG{__WARN__} = sub { die "warned: $_[0]" };
        eval {
            $client->request(sub { $first = 1 }, {
                CURLOPT_URL => "$base/",
                CURLOPT_WRITEFUNCTION => sub { die "boom\n" },
            });
            EV::run until $first;
            1;
        };
    }

    ok($first, 'a dying warn handler does not stop the transfer completing');

    my $error;
    $client->request(sub { $error = $_[1]; $second = 1 },
                     { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
    EV::run until $second;

    ok($second, 'the client is still usable afterwards');
    is($error, undef, 'and the multi handle was not left wedged');
}

# Priority changed from inside a callback, while another watcher of the same
# client is pending, must not be lost.
{
    my $client = EV::YACurl->new({});
    my $completed = 0;

    for (1 .. 4) {
        $client->request(sub {
            $client->priority(EV::MINPRI) if ++$completed == 1;
        }, { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
    }
    EV::run until $completed == 4;

    is($client->priority, EV::MINPRI, 'priority set from inside a callback sticks');
}

# A malformed URL fails before the loop ever runs, so the callback fires from
# inside request(); the in-callback guard has to cover that path too.
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $client = EV::YACurl->new({});
    my $called = 0;
    $client->request(sub { $client->DESTROY; $called = 1 },
                     { CURLOPT_URL => 'http://', CURLOPT_WRITEFUNCTION => sub { } });

    ok($called && grep({ /still in a callback/ } @warnings),
       'client DESTROY inside a synchronous completion is refused, not fatal');
}

# The empty argument must be a writable mortal: assigning to the immortal
# undef would die inside the callback.
{
    my $touched = 0;
    ok(run_one(sub { eval { $_[2] = 'written'; $touched = 1 } }),
       'writing to the empty error slot is survivable');
    ok($touched, 'and actually succeeded');

    # The malformed URL leaves the response slot empty instead.
    my $error_path = 0;
    run_one(sub { eval { $_[1] = 'written'; $error_path = 1 } },
            CURLOPT_URL => 'http://');
    ok($error_path, 'writing to the empty response slot is survivable too');
}
