use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 26;
use File::Temp qw(tempfile);
use TestServer;
use EV;
use EV::YACurl ':constants';

TestServer::watchdog(120);

my $server = TestServer->new(sub {
    my ($request) = @_;
    return (200, [], join "\n", $request->{headers}{'content-type'} // '-', $request->{body});
});
my $base = $server->base_url;

sub fetch {
    my (%options) = @_;
    my ($response, $error, $body) = (undef, undef, '');
    my $done = 0;

    EV::YACurl->new({})->request(sub { ($response, $error) = @_; $done = 1 }, {
        CURLOPT_URL => "$base/",
        CURLOPT_WRITEFUNCTION => sub { $body .= $_[0] },
        %options,
    });
    EV::run until $done;

    return ($response, $error, $body);
}

# Options may be named or given as the raw integer the constant carries.
{
    my (undef, $error, $body) = fetch(CURLOPT_URL() => "$base/numeric");
    is($error, undef, 'numeric option key accepted');
    like($body, qr/\S/, 'numeric option key reached the server');
}

{
    my (undef, undef, $body) = fetch(CURLOPT_POSTFIELDS => "a\0b\0c");
    my (undef, $echoed) = split /\n/, $body, 2;
    is($echoed, "a\0b\0c", 'POSTFIELDS keeps embedded NUL bytes');
}

{
    my (undef, undef, $body) = fetch(CURLOPT_MIMEPOST => [
        { name => 'field',  value => 'value one' },
        { name => 'second', value => "binary\0data" },
    ]);

    my ($type, $sent) = split /\n/, $body, 2;
    like($type, qr{^multipart/form-data; boundary=}, 'MIMEPOST sets a multipart content type');
    like($sent, qr/name="field"/,  'MIMEPOST sent the first part');
    like($sent, qr/name="second"/, 'MIMEPOST sent the second part');
    like($sent, qr/value one/,     'MIMEPOST sent the first value');
    like($sent, qr/binary\0data/,  'MIMEPOST values may contain NUL bytes');
}

{
    my (undef, $file) = tempfile('ev_yacurl_mime_XXXXXX', TMPDIR => 1, UNLINK => 1);
    open my $fh, '>', $file or die "$file: $!";
    print {$fh} "file contents\n";
    close $fh;

    my (undef, undef, $body) = fetch(CURLOPT_MIMEPOST => [
        { name => 'upload', file => $file },
    ]);
    like($body, qr/file contents/, 'MIMEPOST can send a file');
}

{
    my $client = EV::YACurl->new({});
    eval { $client->request(sub { }, { CURLOPT_MIMEPOST => 'not an array' }) };
    like($@, qr/ARRAY reference/, 'MIMEPOST rejects a non-arrayref');

    eval { $client->request(sub { }, { CURLOPT_MIMEPOST => ['not a hash'] }) };
    like($@, qr/HASH reference/, 'MIMEPOST rejects a non-hashref part');

    eval { $client->request(sub { }, { CURLOPT_MIMEPOST => [{ value => 'no name' }] }) };
    like($@, qr/at least 'name'/, 'MIMEPOST requires a name');

    eval { $client->request(sub { }, { CURLOPT_MIMEPOST => [{ name => 'n' }] }) };
    like($@, qr/one of 'value' or 'file'/, 'MIMEPOST requires a value or a file');

    eval { $client->request(sub { }, { CURLOPT_HTTPHEADER => 'not an array' }) };
    like($@, qr/ARRAY reference/, 'slist options reject a non-arrayref');
}

{
    my ($response) = fetch();
    eval { $response->getinfo(CURLINFO_PRIVATE) };
    like($@, qr/Refusing access/, 'getinfo refuses the private slot');

    eval { $response->getinfo('CURLOPT_URL') };
    like($@, qr/not a CURLINFO_\* option/, 'getinfo rejects an option that is not a CURLINFO');
}

# CURLOPT_STDERR takes a file descriptor, which the binding dups so the handle
# stays valid for the transfer even if Perl closes its copy.
{
    my ($fh, $file) = tempfile('ev_yacurl_stderr_XXXXXX', TMPDIR => 1, UNLINK => 1);

    my (undef, $error) = fetch(
        CURLOPT_VERBOSE => 1,
        CURLOPT_STDERR  => fileno($fh),
    );
    is($error, undef, 'CURLOPT_STDERR accepted');

    close $fh;
    open my $read, '<', $file or die "$file: $!";
    my $trace = do { local $/; <$read> };
    like($trace, qr/HTTP\/1\.1|Connected to|GET /, "curl's trace went to the given descriptor")
        or diag "trace was: $trace";
}

# Every option that takes a function needs a real code reference: a string
# would be taken as a sub name and quietly discard the transfer's data.
{
    my $client = EV::YACurl->new({});

    for my $option (qw(CURLOPT_WRITEFUNCTION CURLOPT_READFUNCTION CURLOPT_TRAILERFUNCTION)) {
        my $number = EV::YACurl->can($option)->();
        eval { $client->request(sub { }, { CURLOPT_URL => "$base/", $number => 'not a sub' }) };
        like($@, qr/needs a code reference/, "$option rejects a non-coderef");
    }
}

{
    my ($response) = fetch(
        CURLOPT_URL => "$base/cookie",
        CURLOPT_COOKIEFILE => '',
    );
    my $cookies = $response->getinfo(CURLINFO_COOKIELIST);
    is(ref $cookies, 'ARRAY', 'a slist getinfo comes back as an array reference');
    ok(!@$cookies || $cookies->[0] =~ /\S/, 'and holds strings');
}

# CURLINFO_PTR is the same typemask bit as CURLINFO_SLIST, so the pointer
# flavours have to be refused by name or they get freed as if they were lists.
{
    my ($response) = fetch(CURLOPT_URL => "$base/", CURLOPT_CERTINFO => 1);

    for my $name (qw(CURLINFO_CERTINFO CURLINFO_TLS_SESSION CURLINFO_TLS_SSL_PTR)) {
        my $info = EV::YACurl->can($name) or next;
        eval { $response->getinfo($info->()) };
        like($@, qr/Don't know what to do/, "$name is refused rather than freed");
    }
}
