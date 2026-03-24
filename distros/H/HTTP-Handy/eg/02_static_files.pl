######################################################################
# 02_static_files.pl - Static file serving with HTTP::Handy
#
# Usage: perl eg/02_static_files.pl [port]
#
# Demonstrates:
#   - serve_static: serve files from a document root
#   - cache_max_age option for Cache-Control header
#   - mime_type: look up MIME type by extension
#   - Mixing dynamic routes with static file fallback
#   - Path traversal protection (built into serve_static)
#
# Before running, the script creates a small htdocs/ tree for demo.
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use HTTP::Handy;
use File::Path ();

my $port   = $ARGV[0] || 8080;
my $docroot = 'htdocs';

# ----------------------------------------------------------------
# Create a small demo document tree if it does not exist
# ----------------------------------------------------------------
unless (-d $docroot) {
    for my $d ($docroot, "$docroot/css", "$docroot/img") {
        File::Path::mkpath($d, 0, 0777) unless -d $d;
    }
}

_write("$docroot/index.html", <<'HTML');
<!DOCTYPE html>
<html><head><meta charset="utf-8">
<link rel="stylesheet" href="/css/style.css">
<title>Static Demo</title></head>
<body>
<h1>HTTP::Handy Static File Demo</h1>
<p>This page is served from <code>htdocs/index.html</code>.</p>
<ul>
  <li><a href="/css/style.css">CSS file</a></li>
  <li><a href="/api/time">Dynamic route: /api/time</a></li>
  <li><a href="/no-such-file">404 example</a></li>
  <li><a href="/../etc/passwd">Path traversal (403)</a></li>
</ul>
</body></html>
HTML

_write("$docroot/css/style.css",
    "body { font-family: sans-serif; max-width: 600px; margin: 40px auto; }\n"
    . "h1 { color: #336699; }\n");

# ----------------------------------------------------------------
# Application
# ----------------------------------------------------------------
my $app = sub {
    my $env  = shift;
    my $path = $env->{PATH_INFO};

    # Dynamic API route
    if ($path =~ m{^/api/}) {
        return _api($env, $path);
    }

    # Static files -- cache assets for 1 hour, HTML never cached
    my $age = ($path =~ /\.(css|js|png|jpg|gif|ico|svg)$/) ? 3600 : 0;
    return HTTP::Handy->serve_static($env, $docroot, cache_max_age => $age);
};

sub _api {
    my ($env, $path) = @_;

    if ($path eq '/api/time') {
        my @t  = localtime;
        my $ts = sprintf('%04d-%02d-%02d %02d:%02d:%02d',
            1900 + $t[5], $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);
        my $json = "{\"time\":\"$ts\"}";
        return HTTP::Handy->response_json($json);
    }

    if ($path eq '/api/mime') {
        my $ext  = HTTP::Handy->url_decode($env->{QUERY_STRING});
        $ext     =~ s/^ext=//;
        my $mime = HTTP::Handy->mime_type($ext);
        return HTTP::Handy->response_text("$ext => $mime\n");
    }

    return [404, ['Content-Type', 'text/plain'], ["API not found: $path\n"]];
}

sub _write {
    my ($path, $data) = @_;
    return if -f $path;
    local *FH;
    open FH, ">$path" or die "open $path: $!";
    print FH $data;
    close FH;
}

print "Starting on http://127.0.0.1:$port/\n";
print "Serving static files from: $docroot/\n";
HTTP::Handy->run(app => $app, host => '127.0.0.1', port => $port);
