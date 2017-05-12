use strict;
use warnings;
use Test::More tests => 5;
use Test::Requires +{
    'HTTP::Engine'   => 0.02,
    'Test::TCP'      => 0.12,
    'LWP::UserAgent' => 0,
};

use HTTP::Request::StreamingUpload;

my $makefile = do {
    open my $fh, '<', 'Makefile.PL';
    local $/;
    <$fh>;
};

test_tcp(
    client => sub {
        my $port = shift;

        my $req = HTTP::Request::StreamingUpload->new(
            PUT => "http://localhost:$port/",
            path    => 'Makefile.PL',
            headers => {
                'Content-Length' => length($makefile),
                'Content-Type'   => 'text/plain',
            },
        );
        LWP::UserAgent->new->request($req);

        if (0) {
            # HTTP::Engine is chunked upload unsupported ;)
            $req = HTTP::Request::StreamingUpload->new(
                PUT => "http://localhost:$port/",
                path    => 'Makefile.PL',
                headers => {
                    'Content-Type'      => 'text/plain',
                },
                chunk_size => 10,
            );
            LWP::UserAgent->new->request($req);
        }
    },
    server => sub {
        my $port = shift;
        my $engine = HTTP::Engine->new(
            interface => {
                module => 'ServerSimple',
                args   => {
                    host => 'localhost',
                    port =>  $port,
                },
                request_handler => sub {
                    my $req = shift;
                    is $req->method, 'PUT', 'method';
                    is $req->uri, "http://localhost:$port/", 'uri';
                    is($req->header('Content-Length'), length($makefile), 'Content-Length header');
                    is($req->header('Content-Type'), 'text/plain', 'Content-Type header');
                    is($req->raw_body, $makefile, 'upload success');
                    HTTP::Engine::Response->new;
                },
            },
        );
        $engine->run;
    },
);


