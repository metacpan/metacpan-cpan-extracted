package t::Utils;

use strict;
use warnings;
use HTTP::Engine;

use Sub::Exporter -setup => {
    exports => [qw/ run_engine /],
    groups  => { default => [':all'] }
};

sub run_engine (&@) {
    my ($cb, $req, %args) = @_;

    HTTP::Engine->new(
        interface => {
            module => 'Test',
            args => { },
            request_handler => $cb,
        },
    )->run($req, %args);
}

1;
