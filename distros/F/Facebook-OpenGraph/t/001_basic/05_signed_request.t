use strict;
use warnings;
use Test::More;
use Test::Exception;
use Facebook::OpenGraph;

subtest 'parse' => sub {

    my $signed_request = "vlXgu64BQGFSQrY0ZcJBZASMvYvTHu9GQ0YM9rjPSso.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsIjAiOiJwYXlsb2FkIn0";
    my $fb = Facebook::OpenGraph->new(+{
        secret => 'secret'
    });
    my $datum_ref = $fb->parse_signed_request($signed_request);
    my $expected_datum_ref = +{
        0           => 'payload',
        'algorithm' => 'HMAC-SHA256',
    };

    is_deeply $datum_ref, $expected_datum_ref, 'datum';

};

subtest 'w/o secret key' => sub {

    my $signed_request = "vlXgu64BQGFSQrY0ZcJBZASMvYvTHu9GQ0YM9rjPSso.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsIjAiOiJwYXlsb2FkIn0";
    my $fb = Facebook::OpenGraph->new;

    throws_ok(
        sub {
            my $datum_ref = $fb->parse_signed_request($signed_request);
        },
        qr/secret key must be set/,
        'secret key is mandatory',
    );

};

done_testing;
