######################################################################
# 04_ltsv_viewer.pl - LTSV access log viewer using HTTP::Handy
#
# Usage: perl eg/04_ltsv_viewer.pl [port]
#
# Demonstrates:
#   - is_htmx: distinguish htmx partial requests from full page loads
#   - response_redirect with 301 (permanent)
#   - Error handling: app die -> 500 response
#   - Reading files safely with Perl 5.005_03-compatible open
#   - Serving an HTML page that updates itself via htmx (optional)
#   - Parsing LTSV lines produced by HTTP::Handy's own access log
#   - Custom response status codes (200, 204, 400, 404, 500)
#
# The server reads its own logs/access/ directory so you can watch
# requests appear in real time by refreshing the browser.
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use HTTP::Handy;

my $port    = $ARGV[0] || 8080;
my $log_dir = 'logs/access';

my $app = sub {
    my $env    = shift;
    my $method = $env->{REQUEST_METHOD};
    my $path   = $env->{PATH_INFO};

    # ---- GET /  --  full HTML page ----
    if ($method eq 'GET' && $path eq '/') {
        return _full_page();
    }

    # ---- GET /log  --  LTSV log table (fragment if htmx, full page otherwise) ----
    if ($method eq 'GET' && $path eq '/log') {
        my $table = _log_table($log_dir);
        if (HTTP::Handy->is_htmx($env)) {
            # htmx: return the table fragment only
            return HTTP::Handy->response_html($table);
        }
        else {
            # Direct browser access: wrap in full page
            return HTTP::Handy->response_html(
                "<!DOCTYPE html><html><head><meta charset='utf-8'>"
                . "<title>Log</title></head><body>$table"
                . "<p><a href='/'>Back</a></p></body></html>");
        }
    }

    # ---- GET /api/stats  --  JSON summary of today's log ----
    if ($method eq 'GET' && $path eq '/api/stats') {
        my @lines = _read_log_lines($log_dir);
        my %status_count;
        for my $line (@lines) {
            my %f = _parse_ltsv($line);
            my $s = $f{status} || 'unknown';
            $status_count{$s}++;
        }
        my $pairs = join(',',
            map { "\"$_\":$status_count{$_}" } sort keys %status_count);
        my $total = scalar @lines;
        return HTTP::Handy->response_json(
            "{\"total\":$total,\"by_status\":{$pairs}}");
    }

    # ---- POST /api/echo  --  echo back POST body as JSON ----
    if ($method eq 'POST' && $path eq '/api/echo') {
        my $body = '';
        my $len  = $env->{CONTENT_LENGTH} || 0;
        $env->{'psgi.input'}->read($body, $len) if $len > 0;
        # Return 400 if body is empty
        unless ($body ne '') {
            return [400, ['Content-Type', 'application/json'],
                    ['{"error":"empty body"}']];
        }
        my $escaped = $body;
        $escaped =~ s/\\/\\\\/g;
        $escaped =~ s/"/\\"/g;
        $escaped =~ s/\n/\\n/g;
        return HTTP::Handy->response_json("{\"echo\":\"$escaped\"}");
    }

    # ---- GET /api/ping  --  returns 204 No Content ----
    if ($method eq 'GET' && $path eq '/api/ping') {
        return [204, ['Content-Length', '0'], []];
    }

    # ---- intentional error demo ----
    if ($path eq '/api/crash') {
        die "intentional crash for demo\n";
    }

    # ---- permanent redirect demo ----
    if ($path eq '/old-path') {
        return HTTP::Handy->response_redirect('/', 301);
    }

    return [404, ['Content-Type', 'text/plain'], ["Not Found: $path\n"]];
};

# ----------------------------------------------------------------
# Full HTML page (uses htmx CDN if available, graceful fallback)
# ----------------------------------------------------------------
sub _full_page {
    my $table = _log_table($log_dir);
    return HTTP::Handy->response_html(<<"HTML");
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>LTSV Log Viewer</title>
<style>
  body { font-family: monospace; max-width: 900px; margin: 20px auto; font-size: 13px; }
  h1 { font-family: sans-serif; }
  table { border-collapse: collapse; width: 100%; }
  th { background: #336699; color: white; padding: 4px 8px; text-align: left; }
  td { padding: 3px 8px; border-bottom: 1px solid #ddd; }
  tr:nth-child(even) { background: #f8f8f8; }
  .s2 { color: green; } .s3 { color: orange; }
  .s4 { color: red; }   .s5 { color: darkred; font-weight: bold; }
  button { padding: 4px 12px; }
</style>
<!-- htmx is optional: install from https://htmx.org if you want auto-refresh -->
<!-- For the latest htmx version, see: https://htmx.org/ -->
<script src="https://unpkg.com/htmx.org/dist/htmx.min.js"
        onerror="console.log('htmx not available; manual refresh only')"></script>
</head>
<body>
<h1>HTTP::Handy LTSV Log Viewer</h1>
<p>
  <button hx-get="/log" hx-target="#log-table" hx-swap="innerHTML">
    Refresh</button>
  &nbsp;
  <a href="/api/stats">JSON stats</a> |
  <a href="/api/ping">ping (204)</a> |
  <a href="/api/crash">crash demo (500)</a> |
  <a href="/old-path">redirect demo (301)</a>
</p>
<div id="log-table">$table</div>
</body></html>
HTML
}

# ----------------------------------------------------------------
# Build an HTML table from recent LTSV log lines
# ----------------------------------------------------------------
sub _log_table {
    my ($dir) = @_;
    my @lines = _read_log_lines($dir);

    unless (@lines) {
        return '<p><i>No log entries yet. Make some requests first.</i></p>';
    }

    my $rows = '';
    for my $line (reverse @lines) {
        my %f = _parse_ltsv($line);
        my $s  = $f{status} || '';
        my $cl = ($s =~ /^2/) ? 's2'
               : ($s =~ /^3/) ? 's3'
               : ($s =~ /^4/) ? 's4'
               : ($s =~ /^5/) ? 's5' : '';
        my $time = $f{time}   || '';
        my $meth = $f{method} || '';
        my $path = $f{path}   || '';
        my $size = $f{size}   || '0';
        $path =~ s/&/&amp;/g; $path =~ s/</&lt;/g;
        $rows .= "<tr><td>$time</td>"
              .  "<td>$meth</td>"
              .  "<td>$path</td>"
              .  "<td class='$cl'>$s</td>"
              .  "<td>$size</td></tr>\n";
    }

    return "<table>\n"
         . "<tr><th>Time</th><th>Method</th><th>Path</th>"
         . "<th>Status</th><th>Bytes</th></tr>\n"
         . $rows
         . "</table>\n"
         . "<p>" . scalar(@lines) . " entries total</p>";
}

# ----------------------------------------------------------------
# Read all lines from all *.log.ltsv files in $dir
# ----------------------------------------------------------------
sub _read_log_lines {
    my ($dir) = @_;
    return () unless -d $dir;

    my @files;
    local *DH;
    opendir(DH, $dir) or return ();
    while (my $e = readdir DH) {
        push @files, "$dir/$e" if $e =~ /\.log\.ltsv$/;
    }
    closedir DH;

    my @lines;
    for my $file (sort @files) {
        local *FH;
        next unless open(FH, "< $file");
        while (my $line = <FH>) {
            $line =~ s/\r?\n$//;
            push @lines, $line if $line ne '';
        }
        close FH;
    }
    return @lines;
}

# ----------------------------------------------------------------
# Parse one LTSV line into a hash  (key:value\tkey:value...)
# ----------------------------------------------------------------
sub _parse_ltsv {
    my ($line) = @_;
    my %h;
    for my $field (split /\t/, $line) {
        if ($field =~ /^([^:]+):(.*)$/) {
            $h{$1} = $2;
        }
    }
    return %h;
}

print "Starting on http://127.0.0.1:$port/\n";
print "Reading logs from: $log_dir/\n";
HTTP::Handy->run(app => $app, host => '127.0.0.1', port => $port);
