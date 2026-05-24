######################################################################
#
# 02_with_http_handy.pl - HP::Handy + HTTP::Handy web app example
#
# Run: perl eg/02_with_http_handy.pl [port]
#
# Demonstrates:
#   render_string, render_file, add_filter, add_test
# Then open http://localhost:8080/
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

use lib 'lib';
use HP::Handy;
use HTTP::Handy;

my $port = $ARGV[0] || 8080;
my $tmpl = HP::Handy->new(auto_escape => 1);

######################################################################
# Inline templates
######################################################################
my $BASE_HTML = <<'BASE';
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>{% block title %}HP::Handy Demo{% endblock %}</title>
<style>
body { font-family: sans-serif; max-width: 700px; margin: 40px auto; padding: 0 20px; }
h1   { color: #336699; }
nav  { margin: 16px 0; }
nav a { margin-right: 12px; }
table { border-collapse: collapse; width: 100%; }
th, td { padding: 8px 12px; border: 1px solid #ccc; text-align: left; }
th { background: #336699; color: white; }
tr:nth-child(even) { background: #f8f8f8; }
.badge { display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 12px; }
.high { background: #ffe0e0; }
.mid  { background: #fff8e0; }
.low  { background: #e0ffe0; }
</style>
</head>
<body>
<nav><a href="/">Home</a> <a href="/list">Item List</a> <a href="/info">ENV Info</a></nav>
{% block content %}{% endblock %}
</body>
</html>
BASE

my $INDEX_HTML = <<'INDEX';
{% extends "base.html" %}
{% block title %}Welcome - HP::Handy Demo{% endblock %}
{% block content %}
<h1>HP::Handy + HTTP::Handy Demo</h1>
<p>A minimal Jinja2-compatible template engine for Perl 5.5.3+.</p>
<h2>Quick Render Test</h2>
{% for item in features %}
<p>{{ loop.index }}. {{ item }}</p>
{% endfor %}
<h2>Filter Demo</h2>
<ul>
  <li>upper: {{ sample | upper }}</li>
  <li>length: {{ sample | length }}</li>
  <li>reverse: {{ sample | reverse }}</li>
  <li>truncate(10): {{ sample | truncate(10) }}</li>
</ul>
{% endblock %}
INDEX

my $LIST_HTML = <<'LIST';
{% extends "base.html" %}
{% block title %}Item List - HP::Handy Demo{% endblock %}
{% block content %}
<h1>Item List</h1>
{% if items %}
<table>
<tr><th>#</th><th>Name</th><th>Score</th><th>Grade</th></tr>
{% for item in items %}
<tr>
  <td>{{ loop.index }}</td>
  <td>{{ item.name }}</td>
  <td>{{ item.score }}</td>
  <td>
    {% if item.score >= 90 %}
    <span class="badge high">A</span>
    {% elif item.score >= 70 %}
    <span class="badge mid">B</span>
    {% else %}
    <span class="badge low">C</span>
    {% endif %}
  </td>
</tr>
{% endfor %}
</table>
<p>Total: {{ items | count }} items,
   Average: {{ items | map("score") | sum }} / {{ items | count }}</p>
{% else %}
<p>No items found.</p>
{% endif %}
{% endblock %}
LIST

my $INFO_HTML = <<'INFO';
{% extends "base.html" %}
{% block title %}ENV Info{% endblock %}
{% block content %}
<h1>PSGI Environment</h1>
<table>
<tr><th>Key</th><th>Value</th></tr>
{% for key, val in env %}
<tr><td>{{ key }}</td><td>{{ val }}</td></tr>
{% endfor %}
</table>
{% endblock %}
INFO

######################################################################
# Sample data
######################################################################
my @ITEMS = (
    { name => 'Alice',   score => 95 },
    { name => 'Bob',     score => 82 },
    { name => 'Carol',   score => 67 },
    { name => 'Dave',    score => 91 },
    { name => 'Eve',     score => 55 },
);

######################################################################
# Template renderer with inheritance via string
######################################################################
sub render_with_base {
    my ($page_tmpl, $vars) = @_;

    # Simulate extends by writing base to a temp buffer
    # In real apps, use template_dir with actual files
    my $tmpdir = "t/tmp_http_$$";
    mkdir($tmpdir, 0777) unless -d $tmpdir;
    open(BF, "> $tmpdir/base.html") or die $!;
    print BF $BASE_HTML;
    close BF;

    my $t = HP::Handy->new(template_dir => $tmpdir, auto_escape => 1);
    my $html = $t->render_string($page_tmpl, $vars);

    unlink "$tmpdir/base.html";
    rmdir $tmpdir;

    return $html;
}

######################################################################
# PSGI app
######################################################################
my $app = sub {
    my $env = shift;
    my $path = $env->{PATH_INFO};

    if ($path eq '/' || $path eq '') {
        my $html = render_with_base($INDEX_HTML, {
            features => [
                'Jinja2-compatible syntax: {{ }}, {% %}, {# #}',
                'Built-in filters: upper, lower, truncate, join, sort, ...',
                'Tags: if/elif/else, for, set, include, extends, macro, with',
                'Auto HTML-escaping with | safe override',
                'Custom filters and tests via add_filter() / add_test()',
            ],
            sample => 'Hello, HP::Handy!',
        });
        return HTTP::Handy->response_html($html);
    }

    if ($path eq '/list') {
        my $html = render_with_base($LIST_HTML, { items => \@ITEMS });
        return HTTP::Handy->response_html($html);
    }

    if ($path eq '/info') {
        my %safe_env;
        for my $k (sort keys %$env) {
            next if $k eq 'psgi.input' || $k eq 'psgi.errors';
            my $v = defined $env->{$k} ? $env->{$k} : '';
            $safe_env{$k} = $v;
        }
        my $html = render_with_base($INFO_HTML, { env => \%safe_env });
        return HTTP::Handy->response_html($html);
    }

    return [404, ['Content-Type', 'text/plain'], ["Not Found: $path"]];
};

HTTP::Handy->run(app => $app, port => $port);
