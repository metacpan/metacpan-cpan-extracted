######################################################################
# 01_hello_world.pl - Minimal HTTPS::Handy application
#
# Usage: perl eg/01_hello_world.pl [port]
#
# Demonstrates:
#   - Minimal PSGI app (code reference returning [$status, \@headers, \@body])
#   - Zero-configuration self-signed HTTPS via run(app=>..., port=>...)
#   - response_html, response_text, response_json
#   - psgi.url_scheme / psgi.ssl in $env
#   - Simple routing on PATH_INFO
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

my $port = $ARGV[0] || 8443;

# ----------------------------------------------------------------
# Application: one code reference handles all routes
# ----------------------------------------------------------------
my $app = sub {
    my $env    = shift;
    my $method = $env->{REQUEST_METHOD};
    my $path   = $env->{PATH_INFO};

    # GET /  --  HTML top page
    if ($method eq 'GET' && $path eq '/') {
        my $scheme = $env->{'psgi.url_scheme'};
        return HTTPS::Handy->response_html(<<"HTML");
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Hello</title></head>
<body>
<h1>Hello, HTTPS::Handy!</h1>
<p>Connection scheme: $scheme (psgi.ssl = $env->{'psgi.ssl'})</p>
<ul>
  <li><a href="/text">Plain text response</a></li>
  <li><a href="/json">JSON response</a></li>
  <li><a href="/greet?name=World">Query string: greet?name=World</a></li>
</ul>
</body></html>
HTML
    }

    # GET /text  --  plain text
    if ($method eq 'GET' && $path eq '/text') {
        return HTTPS::Handy->response_text("Hello from HTTPS::Handy!\n");
    }

    # GET /json  --  JSON (manual encoding, no CPAN needed)
    if ($method eq 'GET' && $path eq '/json') {
        my $json = '{"message":"Hello","version":"' . $HTTPS::Handy::VERSION . '"}';
        return HTTPS::Handy->response_json($json);
    }

    # GET /greet?name=...  --  query string
    if ($method eq 'GET' && $path eq '/greet') {
        my %p    = HTTPS::Handy->parse_query($env->{QUERY_STRING});
        my $name = ref($p{name}) ? $p{name}[0] : ($p{name} || 'stranger');
        # Simple HTML escape
        $name =~ s/&/&amp;/g;
        $name =~ s/</&lt;/g;
        $name =~ s/>/&gt;/g;
        return HTTPS::Handy->response_html("<h1>Hello, $name!</h1>");
    }

    # 404 fallback
    return [404, ['Content-Type', 'text/plain'], ["Not Found: $path\n"]];
};

print "Starting on https://127.0.0.1:$port/ (self-signed certificate)\n";
HTTPS::Handy->run(app => $app, host => '127.0.0.1', port => $port);
