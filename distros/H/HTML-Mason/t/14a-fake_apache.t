use strict;
use warnings;

use Test::More tests => 97;
use CGI qw(-no_debug);

BEGIN { use_ok('HTML::Mason::CGIHandler') }

# Create headers object.
ok( my $h = HTML::Mason::FakeTable->new, "Create new FakeTable" );

# Test direct hash access.
ok( $h->{Location} = 'foo', "Assing to Location" );
is( $h->{Location}, 'foo', "Location if 'foo'" );

# Test case-insensitivity.
is( $h->{location}, 'foo', "location if 'foo'" );
is( delete $h->{Location}, 'foo', "Delete location" );

# Test add().
ok( $h->{Hey} = 1, "Set 'Hey' to 1" );
ok( $h->add('Hey', 2), "Add another value to 'Hey'" );

# Fetch both values at once.
is_deeply( [$h->get('Hey')], [1,2], "Get array for 'Hey'" );
is( scalar $h->get('Hey'), 1, "Get first 'Hey' value only" );

# Try do(). The code ref should be executed twice, once for each value
# in the 'Hey' array reference.
my $i;
$h->do( sub {
    my ($k, $v) = @_;
    is( $k, 'Hey', "Check key in 'do'" );
    is( $v, ++$i, "Check value in 'do'" );
});

# Try short-circutiting do(). The code ref should be executed only once,
# because it returns a false value.
$h->do( sub {
    my ($k, $v) = @_;
    is( $k, 'Hey', "Check key in short 'do'" );
    is( $v, 1, "Check value in short 'do'" );
    return;
});

# Test set() and get().
ok( $h->set('Hey', 'bar'), "Set 'Hey' to 'bar'" );
is( $h->{Hey}, 'bar', "Get 'Hey'" );
is( $h->get('Hey'), 'bar', "Get 'Hey' with get()" );

# Try merge().
ok( $h->merge(Hey => 'you'), "Add 'you' to 'Hey'" );
is( $h->{Hey}, 'bar,you', "Get 'Hey'" );
is( $h->get('Hey'), 'bar,you', "Get 'Hey' with get()" );

# Try unset().
ok( $h->unset('Hey'), "Unset 'Hey'" );
ok( ! exists $h->{Hey}, "Hey doesn't exist" );
is( $h->{Hey}, undef, 'Hey is undef' );

# Try clear().
ok( $h->{Foo} = 'bar', "Add Foo value" );
$h->clear;
ok( ! exists $h->{Foo}, "Hey doesn't exist" );
is( $h->{Foo}, undef, 'Hey is undef' );

# Set up some environment variables.
%ENV = ( 'SCRIPT_NAME'          => '/login/welcome.html',
         'REQUEST_METHOD'       => 'GET',
         'HTTP_ACCEPT'          => 'text/html',
         'HTTP_USER_AGENT'      => 'Mozilla/5.0',
         'HTTP_CACHE_CONTROL'   => 'max-age=0',
         'HTTP_ACCEPT_LANGUAGE' => 'en-us,en;q=0.5',
         'HTTP_KEEP_ALIVE'      => '300',
         'GATEWAY_INTERFACE'    => 'CGI-Perl/1.1',
         'DOCUMENT_ROOT'        => '/usr/local/bricolage/comp',
         'HTTP_REFERER'         => 'http://localhost/',
         'HTTP_ACCEPT_ENCODING' => 'gzip,deflate',
         'HTTP_CONNECTION'      => 'keep-alive',
         'HTTP_ACCEPT_CHARSET'  => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
         'HTTP_COOKIE'          => 'FOO=BAR; HEY=You',
         'HTTP_HOST'            => 'localhost',
         'AUTH_TYPE'            => 'Something',
         'CONTENT_TYPE'         => 'text/html',
         'CONTENT_LENGTH'       => 42,
         'REQUEST_METHOD'       => 'GET',
         'PATH_INFO'            => '/index.html',
         'QUERY_STRING'         => "foo=1&bar=2&you=3&you=4",
       );

# Now create a fake apache object.
ok( my $r = HTML::Mason::FakeApache->new, "Create new FakeApache" );

# Check its basic methods.
is( $r->method, $ENV{REQUEST_METHOD}, "Check request method" );
ok( $r->content_type('text/xml'), 'Set content type' );
is( $r->content_type, 'text/xml', 'Check content type' );

# Check the headers out.
ok( $h = $r->headers_out, "Get headers out" );
is( $h->{'Content-Type'}, 'text/xml', 'Check header content-type' );
is( $h->{'content-type'}, 'text/xml', 'Check lc header content-type' );

# Check with get().
is( $h->get('Content-Type'), 'text/xml', 'Check header content-type' );
is( $h->get('content-type'), 'text/xml', 'Check lc header content-type' );

# Try getting an array.
ok( my %h = $r->headers_out, "Get headers out" );
is( $h{'Content-Type'}, 'text/xml', 'Check header content-type' );
is( $h{'content-type'}, undef, 'List context returns new hash list' );

# Try assigning a new value via header_out().
ok( $r->header_out('Annoyance-Level' => 'high'), "Set annoyance level" );
is( $r->header_out('Annoyance-Level'), 'high', "Check annoyance level" );
is( $h->{'annoyance-level'}, 'high', "Check the hash directly" );
ok( $h->unset('annoyance-level'), 'Unset annoyance level' );
is( $r->header_out('Annoyance-Level'), undef, "Check annoyance level again" );
is( $h->{'annoyance-level'}, undef, "Check the hash directly again" );

# Add some cookies
ok( $r->headers_out()->add('Set-Cookie' => 'AF_SID=6e8834d8787ee57a; path=/'), "Set cookie" );
ok( $r->headers_out()->add('Set-Cookie' => 'uniq_id=5608074; path=/; expires=Tue, 26-Aug-2008 21:27:03 GMT'), "Set cookie" );

# Now check err_headers_out.
my $url = 'http://example.com/';
ok( my $e = $r->err_headers_out, "Get error headers out" );
is( scalar keys %$e, 0, "Check for no error headers out" );
ok( $r->err_header_out(Location => $url), "Set location header" );
is( $e->{Location}, $url, "Check Location" );
is( $e->{location}, $url, "Check location" );
is( $e->get('Location'), $url, "Get Location" );
is( $e->get('location'), $url, "Get location" );

# Now check headers_in().
is( $r->header_in('User-Agent'), $ENV{HTTP_USER_AGENT}, "Check user agent" );
ok( $h = $r->headers_in, "Get headers in table" );
is( $h->{Referer}, $ENV{HTTP_REFERER}, "Check referer" );
is( $h->get('Content-Type'), $ENV{CONTENT_TYPE}, "Check in content type" );

# Try notes().
ok( my $n = $r->notes, "Get notes" );
is( scalar keys %$n, 0, "No notes yet" );
ok( $r->notes( foo => 'bar'), "Set note 'foo'" );
is( $r->notes('foo'), 'bar', "Get note 'foo'" );
is( $r->notes('FOO'), 'bar', "Get note 'FOO'" );
is( $n->{foo}, 'bar', "Check note 'foo'" );
is( $n->{FOO}, 'bar', "Check uc note 'foo'" );
my $ref = [];
ok( $n->{bar} = $ref, "Set 'bar' to '$ref'" );
is( $n->{bar}, "$ref", "Check for stringified ref" );
is( $n->get('bar'), "$ref", "Get stringified ref" );

# Try pnotes().
ok( my $pn = $r->pnotes, "Get pnotes" );
is( scalar keys %$pn, 0, "No pnotes yet" );
ok( $r->pnotes( foo => 'bar'), "Set note 'foo'" );
is( $r->pnotes('foo'), 'bar', "Get note 'foo'" );
is( $pn->{foo}, 'bar', "Check note 'foo'" );
$ref = [];
ok( $pn->{bar} = $ref, "Set 'bar' to '$ref'" );
is( $pn->{bar}, $ref, "Check for stringified ref" );

# Check params()
ok( my $p = $r->params, "Get params" );
is( $p->{foo}, 1, "Check 'foo'" );
is( $p->{bar}, 2, "Check 'bar'" );
is_deeply( $p->{you}, [3, 4], "Check 'you'" );

# Check subprocess_env.
is( $r->subprocess_env('CONTENT_LENGTH'), 42, "Get CONTENT_LENGTH env" );
is( $r->subprocess_env('content_length'), 42, "Get content_length env" );
is( $r->subprocess_env->{CONTENT_LENGTH}, 42, "Check CONTENT_LENGTH env" );
is( $r->subprocess_env->{content_length}, 42, "Check content_length env" );
ok( $r->subprocess_env('CONTENT_LENGTH', 56), "Set CONTENT_LENGTH 56" );
is( $r->subprocess_env('CONTENT_LENGTH'), 56, "Check CONTENT_LENGTH env 56" );
is( $r->subprocess_env('content_length'), 56, "Check content_length env 56" );

# Reset subprocess_env.
ok( $r->subprocess_env, "Reset env" );
is( $r->subprocess_env('CONTENT_LENGTH'), 42, "Check CONTENT_LENGTH env again" );
is( $r->subprocess_env('content_length'), 42, "Check content_length env again" );

# Now see what CGI.pm does with the headers out.
ok( my $headers = $r->http_header, "Get http headers" );
like( $headers, qr/Status: 302 (?:Moved|Found)/i, "Check status" );
like( $headers, qr|Location: $url|i, "Check location" );
like( $headers, qr|Content-Type: text/xml(?:; charset=ISO-8859-1)?|i,
      "Check content type" );
like( $headers, qr|Set-Cookie: AF_SID=6e8834d8787ee57a; path=/|i,
      'Check first cookie');
like( $headers, qr|Set-Cookie: uniq_id=5608074; path=/; expires=Tue, 26-Aug-2008 21:27:03 GMT|i,
      'Check second cookie' );

is( $r->uri, '/login/welcome.html/index.html', 'test uri method' );
is( $r->path_info, '/index.html', 'test path_info method' );

SKIP:
{
    skip 'This test requires Test::Output', 1
        unless eval { require Test::Output; Test::Output->import; 1};

    stdout_is( sub { $r->print('Foo bar') }, 'Foo bar',
               'print does not include the object itself' );
}

__END__
