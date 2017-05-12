#!/usr/bin/perl -w

#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

use strict;

use strict;

use Event::RPC::Server;
use Event::RPC::Logger;
use Getopt::Std;

my $USAGE = <<__EOU;

Usage: server.pl [-l log-level] [-s] [-a user:pass] [-L loop-module] 

Description:
  Event::RPC server demonstration program. Execute this from
  the distribution's base or examples/ directory. Then execute
  examples/client.pl on another console.

Options:
  -l log-level       Logging level. Default: 4
  -s                 Use SSL encryption
  -a user:pass       Require authorization
  -h host            Bind to this host interface. Default: localhost
  -L loop-module     Event loop module to use.
                     Default: Event::RPC::Loop::Event

__EOU

sub HELP_MESSAGE {
    my ($fh) = @_;
    $fh ||= \*STDOUT;
    print $fh $USAGE;
    exit;
}

main: {
    my %opts;
    my $opts_ok = getopts('h:L:l:a:s',\%opts);
   
    HELP_MESSAGE() unless $opts_ok;

    my %ssl_args;
    if ( $opts{s} ) {
        %ssl_args = (
            ssl => 1,
            ssl_key_file  => 'ssl/server.key',
            ssl_cert_file => 'ssl/server.crt',
            ssl_passwd_cb => sub { 'eventrpc' },
        );
        if ( not -f 'ssl/server.key' ) {
            chdir ("examples");
            if ( not -f 'ssl/server.key' ) {
                print "please execute from toplevel or examples/ directory\n";
                exit 1;
            }
        }
    }

    my %auth_args;
    if ( $opts{a} ) {
        my ($user, $pass) = split(":", $opts{a}); 
        $pass = Event::RPC->crypt($user, $pass);
        %auth_args = (
            auth_required    => 1,
            auth_passwd_href => { $user => $pass },
        );
    }

    #-- Create a logger object
    my $logger = Event::RPC::Logger->new (
        min_level => ($opts{l}||4),
        fh_lref   => [ \*STDOUT ],
    );

    #-- Create a loop object
    my $loop;
    my $loop_module = $opts{L};
    if ( $loop_module ) {
        eval "use $loop_module";
        die $@ if $@;
        $loop = $loop_module->new();
    }
    
    #-- Host parameter
    my $host = $opts{h} || "localhost";
    
    #-- Create a Server instance and declare the
    #-- exported interface
    my $server = Event::RPC::Server->new (
        name                => "test daemon",
        host                => $host,
        port                => 5555,
        logger              => $logger,
        loop                => $loop,
        start_log_listener  => 1,
        auto_reload_modules => 1,
        message_formats     => [qw/ SERL CBOR JSON STOR /],
        %auth_args,
        %ssl_args,
        classes => {
            'Test_class' => {
                new       => '_constructor',
                set_data  => 1,
                get_data  => 1,
                hello     => 1,
                quit      => 1,
            },
        },
    );

    #-- Start the server resp. the Event loop.
    $server->start;
}
