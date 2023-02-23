use strict;
use warnings;

use Test::More;

use HTTP::Daemon ();
use Socket qw( AF_INET6 );

{
    no warnings 'redefine';
    local *IO::Socket::sockdomain = sub { return Socket::AF_INET6 };
    local *IO::Socket::IP::sockhost
        = sub { return q{fe80::250:54ff:fe00:f01%ens3} };

    my $d = HTTP::Daemon->new;
    is($d->sockhost, q{fe80::250:54ff:fe00:f01%ens3}, 'we overrode sockhost');
    is($d->sockdomain, Socket::AF_INET6, 'we overrode sockdomain');

    like(
        $d->url,
        qr{\Q[fe80::250:54ff:fe00:f01%25ens3]\E},
        '% is encoded in host'
    );

}

done_testing;
