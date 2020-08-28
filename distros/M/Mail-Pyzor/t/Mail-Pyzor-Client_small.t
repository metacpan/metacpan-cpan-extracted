#!/usr/local/cpanel/3rdparty/bin/perl -w

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# Apache 2.0 license.

package t::Mail::Pyzor::Client_small;

use strict;
use warnings;
use autodie;

use Try::Tiny;

use FindBin;
use lib "$FindBin::Bin/../lib";

use parent qw(
  Test::Class
);

use Test::More;
use Test::FailWarnings;
use Test::Deep;
use Test::Exception;

use Errno;

use Mail::Pyzor::Client ();

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

sub test_new : Tests(12) {

    my $client = Mail::Pyzor::Client->new();

    isa_ok( $client, 'Mail::Pyzor::Client' );

    is( $client->{'_server_host'}, $Mail::Pyzor::Client::DEFAULT_SERVER_HOST, "The _server_host is the default when unspecified" );
    is( $client->{'_server_port'}, $Mail::Pyzor::Client::DEFAULT_SERVER_PORT, "The _server_port is the default when unspecified" );
    is( $client->{'_username'},    $Mail::Pyzor::Client::DEFAULT_USERNAME,    "The _username is the default when unspecified" );
    is( $client->{'_password'},    $Mail::Pyzor::Client::DEFAULT_PASSWORD,    "The _password is the default when unspecified" );
    is( $client->{'_timeout'},     $Mail::Pyzor::Client::DEFAULT_TIMEOUT,     "The _timeout is the default when unspecified" );

    $client = Mail::Pyzor::Client->new(
        'timeout'     => 5,
        'server_host' => 'localhost',
        'server_port' => 1234,
        'username'    => 'bob',
        'password'    => 'bobpass',
    );

    isa_ok( $client, 'Mail::Pyzor::Client' );

    is( $client->{'_server_host'}, 'localhost', "The _server_host is stored in the object" );
    is( $client->{'_server_port'}, 1234,        "The _server_port is stored in the object" );
    is( $client->{'_username'},    'bob',       "The _username is stored in the object" );
    is( $client->{'_password'},    'bobpass',   "The _password is stored in the object" );
    is( $client->{'_timeout'},     5,           "The _timeout is stored in the object" );

    return;

}

sub test_internals_sanity : Tests(2) {

    my $client = Mail::Pyzor::Client->new();

    throws_ok { $client->_get_base_msg() } qr/op/, "_get_base_msg throws when no op is passed";

    local $@;

    my $enoent_str = do { local $! = Errno::ENOENT(); "$!" };

    no warnings 'redefine';
    local *IO::Socket::INET::new = sub {
        $@ = 'heyhey';
        $! = Errno::ENOENT;

        return undef;
    };

    eval { $client->_get_connection_or_die() };
    my $msg = $@;

    cmp_deeply(
        $msg,
        all(
            re(qr/Cannot connect.+heyhey/),
            re(qr<\Q$enoent_str\E>),
        ),
        "_get_connection_or_die throws when IO::Socket::INET cannot connect",
    );

    return;
}
1;
