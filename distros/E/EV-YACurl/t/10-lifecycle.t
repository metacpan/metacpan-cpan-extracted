use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 16;
use Scalar::Util qw(weaken);
use EV;
use TestServer;
use EV::YACurl ':constants';

TestServer::watchdog(120);

my $server = TestServer->new(sub { (200, [], 'body') });
my $base = $server->base_url;

# The client is kept alive by an in-flight request, and released afterwards.
{
    my $alive;
    my ($done, $error) = (0, undef);

    {
        my $client = EV::YACurl->new({});
        weaken($alive = $client);
        $client->request(sub { $error = $_[1]; $done = 1 },
                         { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
    }

    ok(defined $alive, 'client survives going out of scope mid request');
    EV::run until $done;
    is($error, undef, 'the abandoned request still completed');
    ok(!defined $alive, 'client is released once the request is done');
}

# Dropping the last reference from inside the completion callback must not
# pull the ground out from under the code still unwinding around it.
{
    my $client = EV::YACurl->new({});
    my $done = 0;
    $client->request(sub { undef $client; $done = 1 },
                     { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
    EV::run until $done;
    pass('client destroyed from within its own callback');
}

{
    my $client = EV::YACurl->new({});
    undef $client;
    pass('client destroyed with nothing in flight');
}

{
    my $foreign = bless \(my $scalar = 0), 'EV::YACurl';
    eval { EV::YACurl::DESTROY(bless {}, 'Some::Other::Class') };
    is($@, '', 'DESTROY on a foreign invocant is a no-op');
}

{
    eval { EV::YACurl->new({ CURLOPT_URL => 'http://example.com/' }) };
    like($@, qr/not a CURLMOPT_\* option/,
         'an easy option passed to new() is rejected, not silently applied');
}

{
    my $client = EV::YACurl->new({});
    eval { $client->request(sub { }, { CURLOPT_PRIVATE => 1 }) };
    like($@, qr/Not sure what to do/, 'CURLOPT_PRIVATE cannot be hijacked');
}

{
    my $client = EV::YACurl->new({});
    eval { $client->request('not a coderef', { CURLOPT_URL => "$base/" }) };
    like($@, qr/code reference/, 'a non-callable callback is caught up front');
}

{
    my $client = EV::YACurl->new({});
    my ($done, @warnings) = (0);
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    $client->request(sub { $done = 1; die "boom\n" },
                     { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
    EV::run until $done;

    ok(@warnings && $warnings[0] =~ /boom/, 'a dying callback is warned about, not fatal');
}

{
    my $client = EV::YACurl->new({});
    my $done = 0;
    $client->request(sub { $done = 1 }, { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
    EV::run until $done;
    pass('loop is still usable afterwards');
}

# A response handed to the callback may outlive both the callback and the client.
{
    my $kept;
    {
        my $client = EV::YACurl->new({});
        my $done = 0;
        $client->request(sub { $kept = $_[0]; $done = 1 },
                         { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
        EV::run until $done;
    }

    is($kept->getinfo(CURLINFO_RESPONSE_CODE), 200, 'response outlives the client');
    undef $kept;
    pass('and can be released afterwards');
}

# Starting the next request from inside a completion callback re-enters the
# same code that is still unwinding around it.
{
    my $client = EV::YACurl->new({});
    my $completed = 0;

    my $again;
    $again = sub {
        return if ++$completed >= 4;
        $client->request($again, { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
    };
    $client->request($again, { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });

    EV::run until $completed >= 4;
    is($completed, 4, 'a request started from inside a callback runs to completion');
}

# libcurl is inside its own API while a data callback runs, and only some
# versions notice; the binding refuses on its own so the rule is the same
# everywhere. Chaining from the completion callback stays legal.
{
    my $client = EV::YACurl->new({});
    my ($done, @warnings) = (0);
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    $client->request(sub { $done = 1 }, {
        CURLOPT_URL => "$base/",
        CURLOPT_WRITEFUNCTION => sub {
            $client->request(sub { }, { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
        },
    });
    EV::run until $done;

    ok((grep { /from a data callback/ } @warnings),
       'request() from a data callback is refused by the binding itself');
    ok($done, 'and the transfer it was called from still completes');
}
