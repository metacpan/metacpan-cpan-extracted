######################################################################
# 03_certificates.pl - Certificate options for HTTPS::Handy
#
# Usage:
#   perl eg/03_certificates.pl                     # self-signed (default)
#   perl eg/03_certificates.pl --cert C --key K    # explicit cert/key files
#   perl eg/03_certificates.pl --domain example.com
#
# Demonstrates:
#   - Explicit ssl_cert_file / ssl_key_file (skips all auto-resolution)
#   - The domains option, which uses an installed Let's Encrypt
#     certificate when there is one, and otherwise puts the names into
#     the self-signed certificate this module generates
#   - cert_dir, where the generated certificate and key are cached.
#     The generated key is a P-256 elliptic curve key, which takes
#     about a second to make; the result is cached, so later runs of
#     this example start at once
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use HTTPS::Handy;

my %opt;
{
    my @argv = @ARGV;
    while (@argv) {
        my $flag = shift @argv;
        if    ($flag eq '--cert')   { $opt{ssl_cert_file} = shift @argv }
        elsif ($flag eq '--key')    { $opt{ssl_key_file}  = shift @argv }
        elsif ($flag eq '--domain') { $opt{domains}       = shift @argv }
        elsif ($flag eq '--port')   { $opt{port}          = shift @argv }
    }
}

my $app = sub {
    my $env = shift;
    return HTTPS::Handy->response_text(
        "Secure hello! scheme=$env->{'psgi.url_scheme'} ssl=$env->{'psgi.ssl'}\n");
};

if ($opt{ssl_cert_file} && $opt{ssl_key_file}) {
    print "Using explicit certificate: $opt{ssl_cert_file}\n";
}
elsif ($opt{domains}) {
    print "Looking for an installed certificate for: $opt{domains}\n";
    print "(a self-signed one for that name is generated if there is none)\n";
    $opt{cert_dir} = '.https_handy_certs';
}
else {
    print "No certificate options given -- using a self-signed certificate.\n";
    print "The first run generates a key, which takes about a second.\n";
    $opt{cert_dir} = '.https_handy_certs';
}

$opt{port} ||= 8443;
print "Starting on https://0.0.0.0:$opt{port}/\n";
HTTPS::Handy->run(app => $app, %opt);
