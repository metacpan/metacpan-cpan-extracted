#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman ();

# Response compression end to end (hm_compress.h + hm_queue_response).
# Every gate condition gets one request, because each of them is a rule that
# silently corrupts a response if it is wrong in the other direction.
#
# The whole file runs on a build without zlib too: `compress => 1` is
# accepted and inert there, so the ASSERTIONS about what is NOT touched
# still hold and only the round trip is skipped. A passthrough build is a
# supported configuration, not an untested one.

my $HAVE_Z = Hyperman->has_compression;
my $BIG    = join '', map { "line $_ of a document that repeats itself. " } 1 .. 400;
my $SMALL  = 'tiny';
my $BIN    = pack 'C*', map { $_ % 256 } 1 .. 4000;

my ($port) = free_ports(1);
plan skip_all => "no free loopback port" unless $port;

my $sup = fork;
die "fork: $!" unless defined $sup;
if ($sup == 0) {
    open STDERR, '>', '/dev/null';
    require Hyperman;
    Hyperman->run(
        app => sub {
            my $env  = shift;
            my $path = $env->{PATH_INFO};
            return [ 200, ['Content-Type','text/plain'], [ $BIG ] ]
                if $path eq '/big';
            return [ 200, ['Content-Type','text/plain'], [ $SMALL ] ]
                if $path eq '/small';
            return [ 200, ['Content-Type','image/png'],  [ $BIN ] ]
                if $path eq '/png';
            return [ 200, ['Content-Type','application/json'],
                          [ '{"k":"' . ('v' x 3000) . '"}' ] ]
                if $path eq '/json';
            return [ 206, ['Content-Type','text/plain',
                           'Content-Range','bytes 0-99/100000'], [ $BIG ] ]
                if $path eq '/partial';
            return [ 200, ['Content-Type','text/plain',
                           'Content-Encoding','gzip'], [ $BIG ] ]
                if $path eq '/already';
            return [ 200, ['Content-Type','text/plain',
                           'Content-Encoding','identity'], [ $BIG ] ]
                if $path eq '/optout';
            return [ 200, ['Content-Type','text/plain',
                           'ETag','"abc123"'], [ $BIG ] ]
                if $path eq '/etag';
            return [ 200, ['Content-Type','text/plain',
                           'Content-Length', length $BIG ], [ $BIG ] ]
                if $path eq '/withlen';
            return [ 204, [], [] ] if $path eq '/nocontent';
            return [ 200, ['Content-Type','text/plain'], [ $BIG ] ];
        },
        compress => 1,
        host     => '127.0.0.1',
        port     => $port,
        workers  => 1,
    );
    exit 0;
}

# Returns (\%headers, $body) with the raw bytes, so a compressed body stays
# compressed for inspection.
sub get {
    my ($path, %opt) = @_;
    for (1 .. 50) {
        my $s = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp')
            or (Time::HiRes::sleep(0.1), next);
        binmode $s;
        my $req = "GET $path HTTP/1.0\r\n";
        $req .= "Accept-Encoding: $opt{ae}\r\n" if defined $opt{ae};
        $req .= "\r\n";
        $s->print($req);
        my $r = eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 10;
            local $/;
            my $all = <$s>;
            alarm 0;
            $all;
        };
        alarm 0;
        next unless defined $r && $r =~ /\r\n\r\n/;
        my ($head, $body) = split /\r\n\r\n/, $r, 2;
        my %h;
        for my $line (split /\r\n/, $head) {
            next unless $line =~ /^([^:]+):\s*(.*)$/;
            $h{lc $1} = $2;
        }
        return (\%h, $body);
    }
    return (undef, undef);
}

# ---- the happy path --------------------------------------------------------

{
    my ($h, $b) = get('/big', ae => 'gzip');
    ok $h, 'the server answered' or BAIL_OUT('no server');
    if ($HAVE_Z) {
        is $h->{'content-encoding'}, 'gzip', 'a large text body is compressed';
        is $h->{'vary'}, 'Accept-Encoding', '...with Vary';
        ok length($b) < length($BIG), '...and is actually smaller';
        is $h->{'content-length'}, length($b),
           '...with Content-Length describing the compressed bytes';
      SKIP: {
            eval { require IO::Uncompress::Gunzip; 1 }
                or skip 'IO::Uncompress::Gunzip not available', 1;
            my $out;
            IO::Uncompress::Gunzip::gunzip(\$b => \$out);
            is $out, $BIG, '...and inflates back to the original bytes';
        }
    } else {
        ok !exists $h->{'content-encoding'},
           'without zlib nothing is encoded (compress => 1 is inert)';
        is $b, $BIG, '...and the body is untouched';
    }
}

# ---- the client did not ask ------------------------------------------------

{
    my ($h, $b) = get('/big');
    ok !exists $h->{'content-encoding'},
       'no Accept-Encoding: nothing is compressed';
    is $b, $BIG, '...body untouched';

    ($h, $b) = get('/big', ae => 'gzip;q=0');
    ok !exists $h->{'content-encoding'}, 'q=0 is honoured end to end';
    is $b, $BIG, '...body untouched';

    ($h, $b) = get('/big', ae => 'deflate');
    ok !exists $h->{'content-encoding'},
       'an encoding we do not emit is not a licence to gzip';
}

# ---- the gates -------------------------------------------------------------

{
    my ($h, $b) = get('/small', ae => 'gzip');
    ok !exists $h->{'content-encoding'},
       'a body under min_length is left alone';
    is $b, $SMALL, '...untouched';
}
{
    my ($h, $b) = get('/png', ae => 'gzip');
    ok !exists $h->{'content-encoding'},
       'an already-compressed media type is not re-compressed';
    is length($b), length($BIN), '...untouched';
}
{
    # A range describes offsets into the UNCOMPRESSED representation, so
    # compressing a 206 makes Content-Range a lie.
    my ($h) = get('/partial', ae => 'gzip');
    ok !exists $h->{'content-encoding'}, 'a 206 is never compressed';
}
{
    my ($h) = get('/nocontent', ae => 'gzip');
    ok !exists $h->{'content-encoding'}, 'a 204 is never compressed';
}

# ---- the hands-off contract ------------------------------------------------

{
    # THE anti-collision rule: a response that already declares an encoding
    # is not ours to touch. This is what lets a framework serve precompressed
    # files off disk through the same server.
    my ($h, $b) = get('/already', ae => 'gzip');
    is $h->{'content-encoding'}, 'gzip',
       'a response that already declares gzip keeps its own encoding';
    is $b, $BIG, '...and its own bytes, un-double-compressed';
}
{
    # ...and the documented opt-out spelling, which we consume and strip.
    my ($h, $b) = get('/optout', ae => 'gzip');
    ok !exists $h->{'content-encoding'},
       'Content-Encoding: identity opts a response out';
    is $b, $BIG, '...leaving the body untouched';
}

# ---- header rewriting ------------------------------------------------------

SKIP: {
    skip 'no zlib: nothing is rewritten because nothing is compressed', 4
        unless $HAVE_Z;

    my ($h) = get('/etag', ae => 'gzip');
    is $h->{'content-encoding'}, 'gzip', 'the ETag route compresses';
    is $h->{'etag'}, '"abc123-gzip"',
       'the ETag is tagged, so a cache never serves gzip bytes as identity';

    my ($h2) = get('/etag');
    is $h2->{'etag'}, '"abc123"',
       '...and the identity response keeps the app\'s ETag unchanged';

    # The app set a Content-Length describing the bytes we replaced; sending
    # it on would truncate or hang the client.
    my ($h3, $b3) = get('/withlen', ae => 'gzip');
    is $h3->{'content-length'}, length($b3),
       "an app-supplied Content-Length is replaced, not passed through";
}

# ---- json, the case this exists for ----------------------------------------

SKIP: {
    skip 'no zlib', 1 unless $HAVE_Z;
    my ($h, $b) = get('/json', ae => 'gzip');
    is $h->{'content-encoding'}, 'gzip', 'application/json compresses';
}

kill 'TERM', $sup;
waitpid $sup, 0;
done_testing;
