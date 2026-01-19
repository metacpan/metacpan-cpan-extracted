#!/usr/bin/perl
use strict;
use warnings;
use URI;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../lib";
use LightTCP::SSLclient qw(ECONNECT ETIMEOUT ESSL);

my %opts = (
    verbose        => 0,
    insecure       => 0,
    json           => 0,
    save           => 0,
    timeout        => 15,
    type           => 'get',
    cert           => undef,
    dir            => '',
    file           => '',
    proxy          => '',
    proxyauth      => '',
    header         => [],
    keep_alive     => 0,
    follow_redirects => 1,
    max_redirects  => 5,
);

GetOptions(
    'v+'            => \$opts{verbose},
    'insecure'      => \$opts{insecure},
    'json'          => \$opts{json},
    'save'          => \$opts{save},
    'timeout=i'     => \$opts{timeout},
    'type=s'        => \$opts{type},
    'cert=s'        => \$opts{cert},
    'dir=s'         => \$opts{dir},
    'file=s'        => \$opts{file},
    'proxy=s'       => \$opts{proxy},
    'proxyauth=s'   => \$opts{proxyauth},
    'header=s'      => \@{$opts{header}},
    'keep-alive'    => \$opts{keep_alive},
    'no-redirect'   => sub { $opts{follow_redirects} = 0 },
) or show_usage();

my $url = $ARGV[0] // '';
if (substr($url, 0, 8) ne 'https://') {
    show_usage("ERROR: You must always provide a full URL as the last argument");
}

my $uri = URI->new($url);
die "ERROR: Invalid URL: $url\n" unless ($uri->scheme && $uri->host);
my $host = $uri->host;
my $port = $uri->port || 443;
my $path = $uri->path_query || '/';

$opts{type} = 'post' if ($opts{file} && $opts{type} eq 'get');
unless ($opts{type} =~ /^(get|post|put|delete)$/) {
    show_usage("ERROR: Invalid -type. Must be get, post, put, or delete");
}
my $method = uc $opts{type};

my $client = LightTCP::SSLclient->new(
    timeout          => $opts{timeout},
    insecure         => $opts{insecure},
    cert             => $opts{cert},
    verbose          => $opts{verbose},
    keep_alive       => $opts{keep_alive},
    follow_redirects => $opts{follow_redirects},
    max_redirects    => $opts{max_redirects},
);

my ($ok, $errors, $debug, $error_code) = $client->connect($host, $port, $opts{proxy}, $opts{proxyauth});
print join('', @$debug) if $opts{verbose};
print join('', @$errors) if @$errors;
if (!$ok) {
    my $err_type = $error_code == ECONNECT ? 'Connection' :
                   $error_code == ETIMEOUT ? 'Timeout' :
                   $error_code == ESSL ? 'SSL' : 'Connection';
    die "- ERROR: $err_type error. Failed to establish SSL connection.\n";
}

check_certpinning($client, $host, $port, $opts{dir}, $opts{save}) if $opts{dir} ne '';

my %hdr;
for my $h (@{$opts{header}}) {
    if ($h =~ /^\s*([^:]+)\s*:\s*(.+)\s*$/) {
        $hdr{$1} = $2;
    } elsif ($opts{verbose}) {
        print "# WARNING: Invalid format (skipping): $h\n";
    }
}

my $payload = undef;
if ($opts{file} && -r $opts{file}) {
    print "- adding file: $opts{file}\n" if $opts{verbose} > 1;
    open my $fh, '<:raw', $opts{file} or die "Cannot open '$opts{file}': $!\n";
    $payload = do { local $/; <$fh> };
    close $fh;
}

if ($method eq 'PUT') {
    my ($filename) = $opts{file} =~ m{([^/\\]+)$} or die "Cannot extract filename from $opts{file}";
    $filename //= 'uploaded.file';
    $hdr{'Content-Type'}        = 'application/octet-stream';
    $hdr{'Content-Disposition'} = "attachment; filename=\"$filename\"";
} elsif ($opts{json}) {
    $hdr{'Content-Type'}  ||= 'application/json';
    $hdr{'Accept'}        ||= 'application/json';
}
$hdr{'Content-Type'} = 'application/json' if $opts{json};

($ok, $errors, $debug, $error_code) = $client->request($method, $path,
    host    => $host,
    payload => $payload,
    headers => \%hdr,
);
print join('', @$debug) if $opts{verbose};
print join('', @$errors) if @$errors;
if (!$ok) {
    my $err_type = $error_code == ETIMEOUT ? 'Timeout' : 'Request';
    die "- ERROR: $err_type error. Unable to do the request\n";
}

my ($code, $state, $headers, $body, $resp_errors, $resp_debug, $resp_code) = $client->response();
print join('', @$resp_debug) if $opts{verbose};
print join('', @$resp_errors) if @$resp_errors;
$client->close();

if ($code) {
    if ($opts{verbose} > 1) {
        print "# === Headers: ===\n";
        for my $k (sort keys %$headers) {
            printf "- %-30s: %s\n", $k, $headers->{$k};
        }
    }
    print "# === Body: ===\n" if $opts{verbose};
    print $body;
    print "\n" unless $body =~ /\n\z/;
}
exit 0;

sub check_certpinning {
    my ($client, $host, $port, $fingerprint_dir, $save) = @_;

    my $socket = $client->socket();
    my $actual_fp = $socket->get_fingerprint('sha256');
    print "- Certificate fingerprint: $actual_fp\n" if $opts{verbose} > 1;

    my $expected_fp = $client->fingerprint_read($fingerprint_dir, $host, $port);
    if ($expected_fp eq $actual_fp) {
        print "- Same as the expected fingerprint\n" if $opts{verbose} > 1;
    } else {
        my ($err, $pferrors, $pfdebug, $pfcode) = $client->fingerprint_save($fingerprint_dir, $host, $port, $actual_fp, $save);
        print join('', @$pfdebug) if $opts{verbose};
        print join('', @$pferrors) if @$pferrors;
        if ($save && $expected_fp) {
            print "- ERROR: FINGERPRINT MISMATCH!\n  Expected: $expected_fp\n  Actual:   $actual_fp\n";
            $client->close();
            exit 1;
        }
    }
}

sub show_usage {
    my $msg = shift // '';
    print "$msg\n\n" if $msg;

    my @progparts = split(/\//, $0);
    my $prognm = pop @progparts;
    print <<"EOF";
Usage  : $prognm [options] <https://host/path>
Options:
  -v                            Verbose mode (repeat for more verbosity)
  --timeout                     default 15 seconds timeout for the request
  --json                        add Content-Type: application/json
  --type <get|post|put|delete>  HTTP method (default: get)
  --file <filename>             Upload file -> forces method to POST
  --header "Name: Value"        Custom header (can be repeated)
  --proxy <host:port>           HTTP CONNECT proxy
  --proxyauth <user:pass>       Proxy Basic authentication
  --cert <client base filename> Client certificate without extension for mTLS
  --insecure                    self-signed certificate: use SSL_VERIFY_NONE
  --save                        save certificate fingerprint as expected
  --dir <path>                  Fingerprint directory (optional)
                                 If omitted: no certificate pinning
  --keep-alive                  Use HTTP keep-alive connection
  --no-redirect                 Don't follow 3xx redirects
Example:
  $prognm -v -v                   https://reqbin.com/echo/get/json
  $prognm --cert ./client         https://reqbin.com/echo/post/json
  $prognm --file data.json        https://reqbin.com/echo/post/json
  $prognm -v --dir cert.d --save  https://reqbin.com/echo/get/json
  $prognm --type put --file doc.pdf https://example.com/upload
  $prognm --header "Authorization: Bearer abc123" --header "Accept: application/json" https://api.example.com/data

EOF
    exit 1;
}
