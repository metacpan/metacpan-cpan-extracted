use strict;
use warnings;

use Test::More tests => 2;
use Test::Fatal;

use HTTP::Async;
use HTTP::Request;

{
    like(
        exception {
            HTTP::Async->new(
                proxy_addr => "localhost",
                proxy_port => 12345,
            )
        },
        qr/proxy_addr not valid/,
        'new dies on invalid option.'
    );
}

{
    my $q = HTTP::Async->new;
    my $r = HTTP::Request->new;

    like(
        exception {
            $q->add_with_opts($r, {
                proxy_addr => "localhost",
                proxy_port => 12345,
            })
        },
        qr/proxy_addr not valid/,
        'add_with_opts dies on invalid option.'
    );
}

1;

