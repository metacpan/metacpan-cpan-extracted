use strict;
use Test::More;
use LWP::UserAgent::DNS::Hosts;

sub _peer_addr { $LWP::UserAgent::DNS::Hosts::Hosts{+shift} }
sub _clear { LWP::UserAgent::DNS::Hosts->clear_hosts }

subtest '.register_host' => sub {
    LWP::UserAgent::DNS::Hosts->register_host('www.google.com' => '127.0.0.1');

    is _peer_addr('www.google.com') => '127.0.0.1';

    _clear();
};

subtest '.register_hosts' => sub {
    my @hosts = qw( www.example.com  www.example.co.jp );
    LWP::UserAgent::DNS::Hosts->register_hosts(
        map { $_ => '127.0.0.1' } @hosts
    );

    for my $host (@hosts) {
        is _peer_addr($host) => '127.0.0.1';
    }

    _clear();
};

done_testing;
