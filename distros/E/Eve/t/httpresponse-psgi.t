# -*- mode: Perl; -*-
package HttpResponseTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;
use Test::Exception;

use DateTime;
use DateTime::Format::HTTP;

use Eve::HttpResponse::Psgi;

sub setup : Test(setup) {
    my $self = shift;

    $self->{'http_response'} = Eve::HttpResponse::Psgi->new();
}

sub test_defaults : Test {
    my $self = shift;

    is($self->{'http_response'}->get_text(), "Status: 200 OK\r\n\r\n");
}

sub test_404 : Test {
    my $self = shift;

    $self->{'http_response'}->set_status(code => 404);

    is($self->{'http_response'}->get_text(), "Status: 404 Not Found\r\n\r\n");
}

sub test_302_location : Test {
    my $self = shift;

    $self->{'http_response'}->set_status(code => 302);
    $self->{'http_response'}->set_header(name => 'Location', value => '/some');

    is(
        $self->{'http_response'}->get_text(),
        "Status: 302 Found\r\nLocation: /some\r\n\r\n");
}

sub test_401_authenticate : Test {
    my $self = shift;

    $self->{'http_response'}->set_status(code => 401);
    $self->{'http_response'}->set_header(
        name => 'WWW-Authenticate', value => 'bla');

    is(
        $self->{'http_response'}->get_text(),
        "Status: 401 Unauthorized\r\nWWW-Authenticate: bla\r\n\r\n");
}

sub test_content_type : Test {
    my $self = shift;

    $self->{'http_response'}->set_header(
        name => 'Content-Type', value => 'image/lolcat');

    is(
        $self->{'http_response'}->get_text(),
        "Status: 200 OK\r\n"
        . "Content-Type: image/lolcat\r\n\r\n");
}

sub test_charset : Test(3) {
    my $self = shift;

    my $charset_hash = {
        'utf8' => 'UTF-8',
        'utf-8' => 'UTF-8',
        'cp1251' => 'windows-1251',
    };

    for my $charset (keys %{$charset_hash}) {
        $self->{'http_response'}->set_header(
            name => 'charset', value => $charset);

        is(
            $self->{'http_response'}->get_text(),
            "Status: 200 OK\r\n"
            . "Charset: " . $charset_hash->{$charset}
            . "\r\n\r\n");
    }
}

sub test_bogus_charset : Test {
    my $self = shift;

    throws_ok(
        sub {
            $self->{'http_response'}->set_header(
                name => 'charset', value => 'bogus');
        },
        'Eve::Error::Value');
}

sub test_set_cookie : Test(3) {
    my $self = shift;
    my $cookie_list = [
        {
            'string' =>
                "Set-Cookie: cookie1=value1; domain=.example.com; "
                . "path=/some/path; expires=Thursday, 25-Apr-1999 "
                . "00:40:33 GMT; secure\r\n",
            'hash' => {
                'name' => 'cookie1',
                'value' => 'value1',
                'expires' => 'Thursday, 25-Apr-1999 00:40:33 GMT',
                'domain' => '.example.com',
                'path' => '/some/path',
                'secure' => 1}},
        {
            'string' => "Set-Cookie: cookie2=value2; path=/\r\n",
            'hash' => {'name' => 'cookie2', 'value' => 'value2'}},
        {
            'string' =>
                "Set-Cookie: session_id=9807123acdfd7896cadf96ac; path=/\r\n",
            'hash' => {
                'name' => 'session_id',
                'value' => '9807123acdfd7896cadf96ac'}}];

    for my $cookie_hash (@$cookie_list) {
        $self->{'http_response'}->set_cookie(%{$cookie_hash->{'hash'}});
    }

    my $response = $self->{'http_response'}->get_text();

    for my $cookie_hash (@$cookie_list) {
        like($response, qr/$cookie_hash->{'string'}/);
    }
}

sub test_set_cookie_expires: Test {
    my $self = shift;

    $self->{'http_response'}->set_cookie(
        name => 'relative',
        value=> 'something',
        expires => time + (60 * 60 * 24));

    my $expected = DateTime::Format::HTTP->format_datetime(
        DateTime->now()->add(days => 1));
    substr($expected, 7, 1) = '-';
    substr($expected, 11, 1) = '-';

    my $cookie_header = "Set-Cookie: relative=something; path=/; expires="
        . $expected . "\r\n";

    is(
        $self->{'http_response'}->get_text(),
        "Status: 200 OK\r\n" . $cookie_header . "\r\n");
}

sub test_set_body : Test(2) {
    my $self = shift;

    for my $text ('Some random text.', 'Some not so random text.') {
        $self->{'http_response'}->set_body(text => $text);

        is(
            $self->{'http_response'}->get_text(),
            "Status: 200 OK\r\n"
            . "Content-Length: " . (length $text) . "\r\n\r\n"
            . $text);
    }
}

sub test_get_raw_list : Test {
    my $self = shift;

    my $body = 'Some body';

    $self->{'http_response'}->set_status(code => 200);
    $self->{'http_response'}->set_header(
        name => 'Content-type', value => 'text/html');
    $self->{'http_response'}->set_cookie(
        name => 'cookie1', value => 'value1');
    $self->{'http_response'}->set_body(text => $body);

    is_deeply(
        $self->{'http_response'}->get_raw_list(),
        [200,
         ['Content-Length', length $body,
          'Content-Type', 'text/html',
          'Set-Cookie', 'cookie1=value1; path=/'],
         [$body]]);
}

1;
