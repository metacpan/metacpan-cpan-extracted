#!/usr/local/cpanel/3rdparty/bin/perl -w

# Copyright 2018 cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package t::Mail::Pyzor::Client;

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

use File::Temp;

use Mail::Pyzor::Client ();

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

sub test_check_and_report : Tests(6) {
    for my $method_name (qw( check report )) {
        my ( $tfh, $temp_file ) = File::Temp::tempfile( CLEANUP => 1 );

        my $send_packet;
        no warnings 'redefine';

        my $thread_id;

        my $faux_socket;

        local *Mail::Pyzor::Client::_get_connection_or_die = sub {
            open( $faux_socket, '+<', $temp_file );
            return $faux_socket;
        };

        local *Mail::Pyzor::Client::_send_packet = sub {
            my ( $self, $sock, $packet ) = @_;

            $packet =~ m<Thread: (\d+)> or die "no thread ID sent";
            $thread_id = $1;

            # Put the faux response into the file:
            syswrite( $faux_socket, "key: value\nkey2: value2\nPV: $Mail::Pyzor::Client::PYZOR_PROTOCOL_VERSION\nThread: $thread_id\n\n" );
            sysseek( $faux_socket, 0, 0 );

            $send_packet = $packet;
            return 1;
        };

        my $client = Mail::Pyzor::Client->new();

        throws_ok { $client->$method_name() } qr/digest/, "$method_name() throws when no digest is passed";

        my $ret = $client->$method_name("fakesha");

        is_deeply(
            $ret,
            {
                'key2' => 'value2',
                'key'  => 'value',
            },
            "$method_name(): The response is read from the handle"
        );

        my @packet_lines = split m<\n>, $send_packet, -1;

        cmp_deeply(
            \@packet_lines,
            [
                "Op: $method_name",
                'Op-Digest: fakesha',
                ( $method_name eq 'report' ? "Op-Spec: $Mail::Pyzor::Client::DEFAULT_OP_SPEC" : () ),
                "Thread: $thread_id",
                "PV: $Mail::Pyzor::Client::PYZOR_PROTOCOL_VERSION",
                "User: $Mail::Pyzor::Client::DEFAULT_USERNAME",
                re(qr<\ATime: [0-9]+\z>),
                re(qr<\ASig: [a-f0-9]+\z>),
                q<>,
                q<>,
            ],
            "$method_name(): The expected packet is sent",
        ) or diag explain \@packet_lines;
    }

    return;
}

1;
