#!/usr/bin/perl
######################################################################
# 01_hello_world.pl - Minimal HTTP::Handy application
#
# Usage: perl eg/01_hello_world.pl [port]
#
# Demonstrates:
#   - Minimal PSGI app (code reference returning [$status, \@headers, \@body])
#   - run() options: app, host, port, log
#   - response_html, response_text, response_json
#   - Simple routing on PATH_INFO
#   - Reading REQUEST_METHOD and QUERY_STRING from $env
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use HTTP::Handy;

my $port = $ARGV[0] || 8080;

# ----------------------------------------------------------------
# Application: one code reference handles all routes
# ----------------------------------------------------------------
my $app = sub {
    my $env    = shift;
    my $method = $env->{REQUEST_METHOD};
    my $path   = $env->{PATH_INFO};

    # GET /  --  HTML top page
    if ($method eq 'GET' && $path eq '/') {
        return HTTP::Handy->response_html(<<'HTML');
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Hello</title></head>
<body>
<h1>Hello, HTTP::Handy!</h1>
<ul>
  <li><a href="/text">Plain text response</a></li>
  <li><a href="/json">JSON response</a></li>
  <li><a href="/greet?name=World">Query string: greet?name=World</a></li>
  <li><a href="/env">PSGI environment dump</a></li>
</ul>
</body></html>
HTML
    }

    # GET /text  --  plain text
    if ($method eq 'GET' && $path eq '/text') {
        return HTTP::Handy->response_text("Hello from HTTP::Handy!\n");
    }

    # GET /json  --  JSON (manual encoding, no CPAN needed)
    if ($method eq 'GET' && $path eq '/json') {
        my $json = '{"message":"Hello","version":"' . $HTTP::Handy::VERSION . '"}';
        return HTTP::Handy->response_json($json);
    }

    # GET /greet?name=...  --  query string
    if ($method eq 'GET' && $path eq '/greet') {
        my %p    = HTTP::Handy->parse_query($env->{QUERY_STRING});
        my $name = ref($p{name}) ? $p{name}[0] : ($p{name} || 'stranger');
        # Simple HTML escape
        $name =~ s/&/&amp;/g;
        $name =~ s/</&lt;/g;
        $name =~ s/>/&gt;/g;
        return HTTP::Handy->response_html("<h1>Hello, $name!</h1>");
    }

    # GET /env  --  dump PSGI $env keys
    if ($method eq 'GET' && $path eq '/env') {
        my $rows = '';
        for my $k (sort keys %$env) {
            next if ref $env->{$k};
            my $v = defined $env->{$k} ? $env->{$k} : '';
            $v =~ s/&/&amp;/g;  $v =~ s/</&lt;/g;  $v =~ s/>/&gt;/g;
            $rows .= "<tr><td><code>$k</code></td><td>$v</td></tr>";
        }
        return HTTP::Handy->response_html(
            "<table border='1'>$rows</table>");
    }

    # 404 fallback
    return [404, ['Content-Type', 'text/plain'], ["Not Found: $path\n"]];
};

print "Starting on http://127.0.0.1:$port/\n";
HTTP::Handy->run(app => $app, host => '127.0.0.1', port => $port);
