#!/usr/bin/perl -w

#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

use strict;

use Event::RPC::Client;
use Getopt::Std;

my $USAGE = <<__EOU;

Usage: client.pl [-s] [-a user:pass]

Description:
  Event::RPC client demonstration program. Execute this from
  the distribution's base or examples/ directory after starting
  the correspondent examples/server.pl program.

Options:
  -s             Use SSL encryption
  -a user:pass   Pass this authorization data to the server
  -h host        Server hostname. Default: localhost

__EOU

sub HELP_MESSAGE {
    my ($fh) = @_;
    $fh ||= \*STDOUT;
    print $fh $USAGE;
    exit;
}

main: {
    my %opts;
    my $opts_ok = getopts('h:l:a:s',\%opts);
   
    HELP_MESSAGE() unless $opts_ok;

    my $ssl = $opts{s} || 0;

    my %auth_args;
    if ( $opts{a} ) {
        my ($user, $pass) = split(":", $opts{a}); 
        $pass = Event::RPC->crypt($user,$pass);
        %auth_args = (
            auth_user => $user,
            auth_pass => $pass,
        );
    }

    #-- Host parameter
    my $host = $opts{h} || 'localhost';

    #-- This connects to the server, requests the exported
    #-- interfaces and establishes correspondent proxy methods
    #-- in the correspondent packages.
    my $client;
    $client = Event::RPC::Client->new (
        host     => $host,
        port     => 5555,
        ssl      => $ssl,
        %auth_args,
        error_cb => sub {
            my ($client, $error) = @_;
            print "An RPC error occured!\n> $error";
            print "Disconnect and exit.\n";
            $client->disconnect if $client;
            exit;
        },
        classes => [ "Test_class" ],
    );

    $client->connect;

    print "\nConnected to localhost:5555\n\n";
    print "Server version:  ".$client->get_server_version,"\n";
    print "Server protocol: ".$client->get_server_protocol,"\n";
    print "Message format:  ".eval { $client->get_message_format },"\n";
    print "\n";

    #-- So the call to Event::RPC::Test->new is handled transparently
    #-- by Event::RPC::Client
    print "** Create object on server\n";
    my $object = Test_class->new (
            data => "Initial data",
    );
    print "=> Object created with data: '".$object->get_data."'\n\n";

    #-- and methods calls as well...
    print "** Say hello to server.\n";
    print "=> Server returned: >>".$object->hello,"<<\n";

    print "\n** Update object data.\n";
    $object->set_data ("Yes, updating works");
    print "=> Retrieve data from server: '".$object->get_data."'\n";

    print "\n** Disconnecting\n\n";
    $client->disconnect;

}
