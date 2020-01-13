#!/usr/bin/perl

=encoding utf8

=head1 NAME

CNic.t

=head1 DESCRIPTION

Tests for IO::EPP::CNic using IO::EPP::Test::CNic for registry emulation

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=cut

use Test::Spec;

use strict;
use warnings;

use lib '../lib';

use IO::EPP::CNic;


no utf8; # !!!

my %sock_params = (
    PeerHost      => 'epp-ote.centralnic.com',
    PeerPort      => 700,
    SSL_key_file  => 'key.pm',
    SSL_cert_file => 'cert.pm',
    Timeout       => 30,
    debug         => 1,
);

my %login_params = (
    sock_params => \%sock_params,
    user        => 'test',
    pass        => 'test123',
    no_log      => 1,

    test_mode   => 1,
);


use_ok( 'IO::EPP::CNic' );


describe 'IO::EPP::CNic::' => sub {
    it 'login, hello, logout' => sub {
        my %params = (
            %login_params,
            tld => 'com',
        );

        # тут пример работы через объект, далее всё будет через make_request чтоб короче было
        my $conn = IO::EPP::CNic->new( \%params );

        is $conn->{user}, 'test';

        ok $conn->{sock};

        my ( $answ, $code, $msg ) = $conn->hello();

        is $code, 1000;

        like $msg, qr/<greeting>/;

        my ( $answ2, $code2, $msg2 ) = $conn->logout();

        ok !$answ2;

        is $code2, 1500;

        is $msg2, 'ok';
    };

    it 'check_domains' => sub {
        my @domains = qw( fhej7fjd.ru.com njenre.bar jkfwbdweklr.site xn--41aaa.xyz  xn--41aaa.xn--p1acf );

        my %params = (
            %login_params,
            domains => \@domains,
        );

        my ( $answ, $msg ) = IO::EPP::CNic::make_request( 'check_domains', \%params );

        is $answ->{code}, 1000;

        foreach my $dm ( @domains ) {
            ok defined $answ->{$dm};
        }

        is $msg, "code: 1000\nmsg: Command completed successfully.";
    };
};

runtests unless caller;

