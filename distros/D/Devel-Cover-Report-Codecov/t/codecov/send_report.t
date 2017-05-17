use strict;
use warnings FATAL => 'all';
use utf8;

use Test::MockObject;
use Test::Mock::Guard;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov;

sub send_report {
    Devel::Cover::Report::Codecov::send_report(@_);
}

sub _make_furl {
    my $res = shift;

    my $furl = Test::MockObject->new;
    $furl->mock(post => sub {
        my ($class, $url, $headers, $json) = @_;

        is $url, 'http://www.example.com';
        cmp_deeply $headers, ['Accept' => 'application/json'];
        is $json, '{"test":1}';

        return $res;
    });

    return $furl;
}

subtest 'if 200' => sub {
    my $res  = Test::MockObject->new;
    my $furl = _make_furl($res);

    $res->mock(code    => sub { 200 });
    $res->mock(message => sub { 'OK' });
    $res->mock(content => sub { '{"message":"OK","url":"http://www.example.net/ok"}' });

    my $guard = mock_guard('Furl', { new => sub { $furl } });

    my $message = <<EOF;
200 OK
OK
http://www.example.net/ok
EOF

    cmp_deeply
        send_report('http://www.example.com', '{"test":1}'),
        { ok => 1, message => $message };
};

subtest 'if not 200' => sub {
    my $res  = Test::MockObject->new;
    my $furl = _make_furl($res);

    $res->mock(code    => sub { 400 });
    $res->mock(message => sub { 'Bad Request' });
    $res->mock(content => sub { '{"message":"ERROR"}' });

    my $guard = mock_guard('Furl', { new => sub { $furl } });

    my $message = <<EOF;
400 Bad Request
{"message":"ERROR"}
EOF

    cmp_deeply
        send_report('http://www.example.com', '{"test":1}'),
        { ok => 0, message => $message };
};

done_testing;
