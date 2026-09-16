use v5.10; use strict; use warnings;
use Test::More;
use lib 't/lib'; use TWK; TWK::skip_unless_available(); use TCTL;
use File::Temp qw(tempdir);
use EV; use EV::WebKit; use EV::WebKit::Control; use EV::WebKit::Protocol;

# The server, driven by a RAW socket -- on purpose. It must be correct on its own
# terms, not merely agree with a client module that shares its bugs.

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/ctl.sock";

my $b = EV::WebKit->new(window => [300,200], ephemeral => 1);
$b->mock_scheme('cs', sub {
    ('<html><head><title>T</title></head><body><h1>hi</h1></body></html>', 'text/html')
});
my $ctl = EV::WebKit::Control->listen($b, path => $path);

ok(-S $path, 'the socket exists');
is((stat $path)[2] & 07777, 0600,
    'and is mode 0600 -- the socket IS the auth boundary (anyone who can open it owns the browser)');

my $cl = TCTL->new($path);

# 1) hello on connect: a client attaching to a long-lived session must learn
#    where the browser already IS, without having to ask
{
    my @f = $cl->pump(1);
    is($f[0]{ev}, 'hello', 'the server greets a new client');
    is($f[0]{proto}, EV::WebKit::Protocol::PROTO, '...with the protocol version');
    ok(exists $f[0]{uri}, '...and where the browser currently is');
}

# NOTE: from here on, every request is matched by ID (TCTL::reply). Events are
# unsolicited and land whenever they like -- a go() emits navigate and load
# events BEFORE its own response -- and responses can arrive out of order. A
# client that assumes "the next frame is my answer" is relying on something the
# protocol does not promise.

# 2) a sync method
{
    my $r = $cl->reply({ i => 1, m => 'title' });
    is($r->{i}, 1, 'a response carries the id of the request it answers');
    ok(exists $r->{r}, '...and a result');
}

# 3) an async method, end to end
{
    my $r = $cl->reply({ i => 2, m => 'go', a => ['cs://p'] }, 25);
    is($r->{i}, 2, 'go() answers');
    ok(!exists $r->{e}, '...without an error') or diag("err=" . ($r->{e} // ''));

    is($cl->reply({ i => 3, m => 'title' })->{r}, 'T',
        'the browser really navigated where the client told it to');
}

# 4) errors come back AS errors, never as silence -- a dropped request is a hung
#    client, which is the whole failure mode this protocol must not have
{
    my $r = $cl->reply({ i => 4, m => 'no_such_method' });
    like($r->{e}, qr/unknown method/, 'an unknown method answers with an error');
    is($r->{i}, 4, '...against the right id');

    $r = $cl->reply({ i => 5, m => 'go', a => [undef] });
    like($r->{e}, qr/uri required/,
        "the module's own error strings cross the wire unchanged");
}

# 5) a malformed line is answered, and the connection survives it
{
    $cl->send_raw("this is not json\n");
    my ($bad) = grep { !defined $_->{ev} } $cl->pump(1);
    ok($bad && $bad->{e}, 'a malformed line gets an error');
    ok($bad && !defined $bad->{i}, '...with a null id (there was no id to answer)');

    is($cl->reply({ i => 6, m => 'title' })->{i}, 6,
        '...and the connection is still usable afterwards');
}

# 6) a script round-trip, since that is what most clients will actually do
{
    is($cl->reply({ i => 7, m => 'script', a => ['return 40 + 2'] })->{r}, 42,
        'script() runs in the browser and the value comes back');
}

# 7) close() cleans up after itself
$cl->close;
$ctl->close;
ok(!-e $path, 'close() unlinks the socket');
$b->quit;

# 8) listen() refuses to put the socket somewhere the world can reach: the socket
#    is the only thing standing between a stranger and arbitrary JS in your
#    logged-in browser
{
    my $wdir = "$dir/world";
    mkdir $wdir or die $!;
    chmod 0777, $wdir or die $!;      # world-writable, no sticky bit
    my $b2 = EV::WebKit->new(window => [200,150], ephemeral => 1);
    my $ok = eval { EV::WebKit::Control->listen($b2, path => "$wdir/x.sock"); 1 };
    ok(!$ok, 'listen() refuses a world-writable directory');
    like($@, qr/world-writable/, '...saying why');
    $b2->quit;
}

# Both constructors warned "Odd number of elements in hash assignment" from
# inside the module on an odd list -- and connect() then built a BLOCKING
# client with `ev` silently unset, so the caller's first call from inside the
# loop they meant to keep running would block it.
{
    require EV::WebKit::Client;
    my @w; local $SIG{__WARN__} = sub { push @w, $_[0] };
    ok(!eval { EV::WebKit::Client->connect('/nonexistent.sock', 'ev'); 1 },
       'connect croaks on an odd option list');
    like($@, qr/name => value pairs/, '...rather than silently building a blocking client');
    ok(!eval { EV::WebKit::Client->connect('/nonexistent.sock', evv => 1); 1 },
       'connect croaks on an unknown option');
    like($@, qr/unknown option\(s\): evv/, '...naming it');

    my $lb = EV::WebKit->new(window => [100,80], ephemeral => 1, timeout => 5);
    ok(!eval { EV::WebKit::Control->listen($lb, 'path'); 1 },
       'listen croaks on an odd option list');
    like($@, qr/name => value pairs/, '...saying so');
    ok(!eval { EV::WebKit::Control->listen($lb, path => "$dir/sweep.sock", pth => 1); 1 },
       'listen croaks on an unknown option');
    like($@, qr/unknown option\(s\): pth/, '...naming it');
    is(scalar(@w), 0, 'none of that warned from inside the module');
    $lb->quit;
}

# 9) listen() replaces a dangling symlink at the socket path
{
    my $b3 = EV::WebKit->new(window => [100,80], ephemeral => 1, timeout => 5);
    my $sym_sock = "$dir/dangling.sock";
    symlink("$dir/nonexistent_target.sock", $sym_sock) or die $!;
    ok(-l $sym_sock && !-e $sym_sock, 'dangling symlink created');
    my $ctl3 = eval { EV::WebKit::Control->listen($b3, path => $sym_sock) };
    ok($ctl3, 'listen() replaces dangling symlink at socket path') or diag($@);
    $ctl3->close if $ctl3;
    $b3->quit;
}

done_testing;
