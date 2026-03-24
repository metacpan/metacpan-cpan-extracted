######################################################################
# 03_form_post.pl - HTML form handling with HTTP::Handy
#
# Usage: perl eg/03_form_post.pl [port]
#
# Demonstrates:
#   - GET vs POST routing on REQUEST_METHOD
#   - Reading POST body via psgi.input->read and CONTENT_LENGTH
#   - parse_query for both GET query strings and POST bodies
#   - url_decode for manual percent-decoding
#   - Multi-value form fields (same name repeated)
#   - max_post_size option to cap POST body size
#   - response_redirect for Post-Redirect-Get pattern
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use HTTP::Handy;

my $port = $ARGV[0] || 8080;

# In-memory "database" for submitted entries (lost on restart)
my @entries;

my $app = sub {
    my $env    = shift;
    my $method = $env->{REQUEST_METHOD};
    my $path   = $env->{PATH_INFO};

    # ---- GET /  --  show form and submitted entries ----
    if ($method eq 'GET' && $path eq '/') {
        return _show_form(\@entries);
    }

    # ---- POST /submit  --  handle form submission ----
    if ($method eq 'POST' && $path eq '/submit') {
        # Read raw POST body from psgi.input
        my $body = '';
        my $len  = $env->{CONTENT_LENGTH} || 0;
        $env->{'psgi.input'}->read($body, $len) if $len > 0;

        # Parse application/x-www-form-urlencoded body
        my %post = HTTP::Handy->parse_query($body);

        my $name    = ref($post{name})    ? $post{name}[0]    : ($post{name}    || '');
        my $message = ref($post{message}) ? $post{message}[0] : ($post{message} || '');

        # Multi-value: checkboxes share the same field name
        my $tags_raw = $post{tag} || [];
        my @tags = ref($tags_raw) ? @$tags_raw : ($tags_raw ? ($tags_raw) : ());

        if ($name ne '' && $message ne '') {
            push @entries, {
                name    => $name,
                message => $message,
                tags    => \@tags,
            };
        }

        # Post-Redirect-Get: redirect to GET / to avoid resubmission
        return HTTP::Handy->response_redirect('/');
    }

    # ---- GET /clear  --  clear all entries ----
    if ($method eq 'GET' && $path eq '/clear') {
        @entries = ();
        return HTTP::Handy->response_redirect('/');
    }

    return [404, ['Content-Type', 'text/plain'], ["Not Found: $path\n"]];
};

# ----------------------------------------------------------------
# Build the form page HTML
# ----------------------------------------------------------------
sub _show_form {
    my ($entries_ref) = @_;

    my $list = '';
    for my $e (reverse @$entries_ref) {
        my $n = _esc($e->{name});
        my $m = _esc($e->{message});
        my $t = join(', ', map { _esc($_) } @{$e->{tags}});
        $list .= "<li><b>$n</b>: $m" . ($t ? " <i>[$t]</i>" : '') . "</li>\n";
    }
    $list ||= '<li><i>(no entries yet)</i></li>';

    my $count = scalar @$entries_ref;

    return HTTP::Handy->response_html(<<"HTML");
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Form Demo</title>
<style>
  body { font-family: sans-serif; max-width: 500px; margin: 40px auto; }
  input[type=text], textarea { width: 100%; box-sizing: border-box; }
  .tags label { margin-right: 12px; }
</style>
</head>
<body>
<h1>HTTP::Handy Form Demo</h1>

<form method="post" action="/submit">
  <p>Name:<br><input type="text" name="name" required></p>
  <p>Message:<br><textarea name="message" rows="3" required></textarea></p>
  <p class="tags">Tags:
    <label><input type="checkbox" name="tag" value="perl"> Perl</label>
    <label><input type="checkbox" name="tag" value="web"> Web</label>
    <label><input type="checkbox" name="tag" value="psgi"> PSGI</label>
  </p>
  <p><button type="submit">Submit</button></p>
</form>

<h2>Entries ($count)</h2>
<ul>$list</ul>
<p><a href="/clear">Clear all</a></p>
</body></html>
HTML
}

sub _esc {
    my $s = defined $_[0] ? $_[0] : '';
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}

print "Starting on http://127.0.0.1:$port/\n";
HTTP::Handy->run(
    app           => $app,
    host          => '127.0.0.1',
    port          => $port,
    max_post_size => 64 * 1024,   # 64 KB limit for this demo
);
