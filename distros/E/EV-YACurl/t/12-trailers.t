use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 10;
use TestServer;
use EV;
use EV::YACurl ':constants';

TestServer::watchdog(120);

my $server = TestServer->new(sub {
    my ($request) = @_;
    my $trailers = join ',', map { "$_=$request->{trailers}{$_}" } sort keys %{ $request->{trailers} };
    return (200, [], "body=$request->{body} trailers=$trailers");
});
my $base = $server->base_url;

# Trailers only exist on a chunked upload, which is what curl uses when the
# size is not declared up front.
sub upload {
    my (%options) = @_;
    my @chunks = @{ delete $options{chunks} };
    my ($response, $error, $body) = (undef, undef, '');
    my $done = 0;

    EV::YACurl->new({})->request(sub { ($response, $error) = @_; $done = 1 }, {
        CURLOPT_URL => "$base/",
        CURLOPT_UPLOAD => 1,
        CURLOPT_READFUNCTION => sub { @chunks ? shift @chunks : '' },
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
        %options,
    });
    EV::run until $done;

    return ($response, $error, $body);
}

{
    my ($response, $error, $body) = upload(
        chunks => ['hello '],
        CURLOPT_HTTPHEADER => ['Trailer: X-Checksum'],
        CURLOPT_TRAILERFUNCTION => sub { ['X-Checksum: abc123'] },
    );

    is($error, undef, 'chunked upload with trailers succeeded');
    like($body, qr/body=hello /,               'the body arrived');
    like($body, qr/x-checksum=abc123/,         'the trailer arrived');
}

{
    my (undef, $error) = upload(
        chunks => ['x'],
        CURLOPT_HTTPHEADER => ['Trailer: X-Checksum'],
        CURLOPT_TRAILERFUNCTION => sub { undef },
    );
    ok($error, "returning undef from the trailer callback aborts ($error)");
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my (undef, $error) = upload(
        chunks => ['x'],
        CURLOPT_HTTPHEADER => ['Trailer: X-Checksum'],
        CURLOPT_TRAILERFUNCTION => sub { 'not an arrayref' },
    );
    ok($error, 'a non-arrayref from the trailer callback aborts');
    ok((grep { /ARRAY reference/ } @warnings), 'and says why');
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my (undef, $error) = upload(
        chunks => ['x'],
        CURLOPT_HTTPHEADER => ['Trailer: X-Checksum'],
        CURLOPT_TRAILERFUNCTION => sub { die "no trailers for you\n" },
    );
    ok($error, 'a dying trailer callback aborts instead of escaping into libcurl');
}

# An undef among the trailers used to raise a warning from inside libcurl's
# frames, which a dying handler turned into a longjmp that wedged the client.
{
    my $client = EV::YACurl->new({});

    {
        local $SIG{__WARN__} = sub { die "warned: $_[0]" };
        my @chunks = ('x');
        my $first = 0;

        eval {
            $client->request(sub { $first = 1 }, {
                CURLOPT_URL => "$base/",
                CURLOPT_UPLOAD => 1,
                CURLOPT_READFUNCTION => sub { @chunks ? shift @chunks : '' },
                CURLOPT_HTTPHEADER => ['Trailer: X-Present'],
                CURLOPT_TRAILERFUNCTION => sub { ['X-Present: yes', undef] },
                CURLOPT_WRITEFUNCTION => sub { },
            });
            EV::run until $first;
            1;
        };

        ok($first, 'an undef trailer does not stop the transfer completing');
    }

    my ($error, $second) = (undef, 0);
    $client->request(sub { $error = $_[1]; $second = 1 },
                     { CURLOPT_URL => "$base/", CURLOPT_WRITEFUNCTION => sub { } });
    EV::run until $second;

    ok($second,          'the client is still usable afterwards');
    is($error, undef,    'and the multi handle was not left wedged');
}
