#!/usr/bin/perl

=encoding utf8

=head1 NAME

Afilias.t

=head1 DESCRIPTION

Tests for IO::EPP::Afilias

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>

=cut

use Test::Spec;

use strict;
use warnings;

use lib '../lib';

use IO::EPP::Test::Server;


no utf8; # !!!

plan tests => 1;


my %sock_params = (
    PeerHost      => 'epp-ote.publicinterestregistry.net',
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
    provider    => 'pir',
    no_log      => 1,

    test_mode   => 1,
);

use_ok( 'IO::EPP::Afilias' );

