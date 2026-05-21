use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use EV::Nats;

plan skip_all => 'creds_file requires NKey support (build with OpenSSL)'
    unless EV::Nats::HAS_NKEY();

plan tests => 6;

# Sample seed/jwt strings copied from a real .creds file format. Not real
# credentials — random bytes that pass the regex shape only.
my $JWT  = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJlZDI1NTE5LW5rZXkifQ.payload.sig';
my $SEED = 'SUAFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKE';

sub write_creds {
    my ($content) = @_;
    my ($fh, $path) = tempfile(SUFFIX => '.creds', UNLINK => 1);
    print $fh $content;
    close $fh;
    $path;
}

sub make_nats { EV::Nats->new() }  # no host => no connection attempt

# 1. Well-formed file (LF)
{
    my $path = write_creds(<<EOF);
-----BEGIN NATS USER JWT-----
$JWT
------END NATS USER JWT------

-----BEGIN USER NKEY SEED-----
$SEED
------END USER NKEY SEED------
EOF
    my $nats = make_nats();
    eval { $nats->creds_file($path) };
    is $@, '', 'well-formed creds file accepted';
}

# 2. CRLF line endings (Windows-style or fetched from a remote store)
{
    my $content = "-----BEGIN NATS USER JWT-----\r\n$JWT\r\n"
                . "------END NATS USER JWT------\r\n\r\n"
                . "-----BEGIN USER NKEY SEED-----\r\n$SEED\r\n"
                . "------END USER NKEY SEED------\r\n";
    my $path = write_creds($content);
    my $nats = make_nats();
    eval { $nats->creds_file($path) };
    is $@, '', 'CRLF creds file accepted';
}

# 3. Missing END marker for JWT block
{
    my $path = write_creds(<<EOF);
-----BEGIN NATS USER JWT-----
$JWT

-----BEGIN USER NKEY SEED-----
$SEED
------END USER NKEY SEED------
EOF
    my $nats = make_nats();
    eval { $nats->creds_file($path) };
    like $@, qr/missing NATS USER JWT/, 'missing JWT END marker rejected';
}

# 4. Missing SEED block entirely
{
    my $path = write_creds(<<EOF);
-----BEGIN NATS USER JWT-----
$JWT
------END NATS USER JWT------
EOF
    my $nats = make_nats();
    eval { $nats->creds_file($path) };
    like $@, qr/missing USER NKEY SEED/, 'missing SEED block rejected';
}

# 5. Truncated (only BEGIN markers, no payload)
{
    my $path = write_creds(<<EOF);
-----BEGIN NATS USER JWT-----
EOF
    my $nats = make_nats();
    eval { $nats->creds_file($path) };
    ok $@, 'truncated creds file rejected';
}

# 6. Nonexistent path
{
    my $nats = make_nats();
    eval { $nats->creds_file('/nonexistent/path/should/not/exist.creds') };
    like $@, qr/cannot open creds file/, 'missing file rejected';
}
