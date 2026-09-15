use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::HTTP::_ClientConnect;
use Linux::Event::HTTP::Request;
use Linux::Event::IO::Sock::Stream;

{
    package T::ConnectValidationTarget;
    use parent 'Linux::Event::IO::Sock::Stream';
}

sub request_with ($name, $value) {
    return Linux::Event::HTTP::Request->new(
        method  => 'CONNECT',
        target  => 'example.test:443',
        headers => [
            [ Host => 'example.test:443' ],
            [ $name => $value ],
        ],
    );
}

my $ok = eval {
    Linux::Event::HTTP::_ClientConnect->prepare_request(
        request_with('Content-Length', '0'),
        'T::ConnectValidationTarget',
        { streaming => 0 },
    );
    1;
};
ok(!$ok, 'Content-Length: 0 is rejected by field presence');
like($@, qr/must not contain Content-Length/,
    'zero Content-Length rejection is explicit');

$ok = eval {
    Linux::Event::HTTP::_ClientConnect->prepare_request(
        request_with('Transfer-Encoding', 'chunked'),
        'T::ConnectValidationTarget',
        { streaming => 0 },
    );
    1;
};
ok(!$ok, 'Transfer-Encoding is rejected on CONNECT');
like($@, qr/must not contain Transfer-Encoding/,
    'Transfer-Encoding rejection is explicit');

done_testing;
