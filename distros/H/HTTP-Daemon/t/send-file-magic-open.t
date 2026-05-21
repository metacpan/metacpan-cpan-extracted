use strict;
use warnings;

use Test::More;

BEGIN {
    if ($^O eq 'MSWin32') {
        plan skip_all =>
            'POSIX shell is required to exercise 2-arg open() shell-magic shapes';
    }
}

use File::Spec   ();
use File::Temp   qw(tempfile tempdir);
use Socket       qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use HTTP::Daemon ();    # also defines HTTP::Daemon::ClientConn, which
                        # is where send_file() actually lives

# Regression test for CVE-2026-8450. send_file() used to call open() in
# the 2-arg form, which interpreted shell-magic prefixes in the path.
# The 3-arg form with an explicit '<' mode treats the path as a literal
# filename. The load-bearing oracle for each shape is a marker file:
# an unpatched build runs a child that creates the marker, the patched
# build never does. For the pipe shapes the marker path is passed to
# the child via an env var (not shell-interpolated) so the test is
# robust to spaces/quotes in $TMPDIR. For the redirect shape the path
# goes straight to Perl's open() with no shell, so a literal path is
# fine there too.

# Stand up a real HTTP::Daemon::ClientConn so $self in send_file is
# a blessed socket. Any future method dispatch on $self surfaces here
# instead of silently no-oping against an unblessed scalar filehandle.
sub make_clientconn {
    socketpair(my $server, my $client, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";
    bless $server, 'HTTP::Daemon::ClientConn';
    return ($server, $client);
}

my $tmpdir = tempdir(CLEANUP => 1);

# A perl one-liner that touches $ENV{HTTPD_MAGIC_MARKER}. Single-quoted
# for the shell so $f / $ENV are seen by perl, not by the shell.
my $writer
    = qq{$^X -e 'open my \$f, q{>}, \$ENV{HTTPD_MAGIC_MARKER} or die; close \$f'};

my @magic_shapes = (

    # One pipe shape stands for the whole command-execution family
    # (| cmd, cmd |, ...). The leading-space spelling is the one kept:
    # 2-arg open() strips leading whitespace before testing for a magic
    # prefix, so " | cmd" also exercises that quirk.
    {name => 'pipe',           shape => sub {" | $writer"}},
    {name => 'write-redirect', shape => sub { my ($m) = @_; "> $m" }},
);

for my $case (@magic_shapes) {
    my $name   = $case->{name};
    my $marker = File::Spec->catfile($tmpdir, "marker-$name");
    unlink $marker;
    my $shape = $case->{shape}->($marker);

    local $ENV{HTTPD_MAGIC_MARKER} = $marker;

    my ($server, $client) = make_clientconn();

    my $rv = $server->send_file($shape);

    is($rv, undef, "[$name] send_file refuses magic shape '$shape'");
    ok(!-e $marker, "[$name] no on-disk side effect for '$shape'");

    close $server;
    my $captured = do { local $/; <$client> };
    $captured = q{} unless defined $captured;
    is($captured, q{}, "[$name] no bytes streamed for '$shape'");
}

# Bare "<file" prefix: under 2-arg open() this opens "file" for read,
# bypassing any path validation a caller may have done on the
# attacker-supplied string. Under 3-arg open with mode '<' the leading
# '<' is part of the literal filename, so the open fails and no bytes
# leak. Place a real file at the would-be target so an unpatched build
# would actually stream its contents (and the assertion would catch it),
# rather than failing for the boring reason that the file doesn't exist.
{
    my $secret = File::Spec->catfile($tmpdir, 'secret-do-not-leak');
    open my $f, '>', $secret or die "open $secret: $!";
    print $f "do-not-leak-this-string\n";
    close $f;

    my $shape = "<$secret";
    my ($server, $client) = make_clientconn();
    my $rv = $server->send_file($shape);

    is($rv, undef, "[bare-lt] send_file refuses magic shape '$shape'");
    close $server;
    my $captured = do { local $/; <$client> };
    $captured = q{} unless defined $captured;
    unlike($captured, qr/do-not-leak/,
        '[bare-lt] secret contents did not stream to the client');
}

# Positive control: an ordinary file still streams through the real
# blessed ClientConn.
my ($src_fh, $src) = tempfile(UNLINK => 1);
binmode $src_fh;
print $src_fh "hello world\n";
close $src_fh;

my ($server, $client) = make_clientconn();
my $rv = $server->send_file($src);
close $server;
my $captured = do { local $/; <$client> };
$captured = q{} unless defined $captured;

ok(defined $rv, 'send_file still works on an ordinary filename');
cmp_ok($rv, '>', 0, 'non-zero byte count returned');
like($captured, qr/hello world/, 'file contents reach the client end');

# Return-value contract: an empty-but-successful copy must be
# distinguishable from open failure. send_file() returns '0E0' (zero
# numerically, true in boolean context) on success-with-no-bytes so
# that `send_file or die` only trips on undef.
{
    my (undef, $empty) = tempfile(UNLINK => 1);
    my ($server) = make_clientconn();
    my $rv = $server->send_file($empty);
    ok(defined $rv, 'empty file: rv is defined');
    ok($rv,         'empty file: rv is true (so `or die` does not fire)');
    cmp_ok($rv, '==', 0, 'empty file: rv compares numerically equal to 0');
}

done_testing();
