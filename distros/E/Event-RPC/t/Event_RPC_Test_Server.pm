package Event_RPC_Test_Server;

use strict;
use utf8;

use lib qw(t);
use Fcntl qw( :flock );

sub start_server {
    my $class = shift;
    my %opts = @_;

    #-- fork
    my $server_pid = fork();
    die "can't fork" unless defined $server_pid;
    
    #-- Client?
    if ( $server_pid ) {
        #-- client tries to make a log connection to
        #-- verify that the server is up and running
        #-- (20 times with a usleep of 0.25, so the
        #--  overall timeout is 5 seconds)
        for ( 1..20 ) {
	    eval {
	        Event::RPC::Client->log_connect (
		    server => "localhost",
		    port   => $opts{p}+1,
	        );
	    };
	    #-- return to client code if connect succeeded
	    return $server_pid if !$@;
	    #-- bail out if the limit is reached
	    if ( $_ == 20 ) {
	        die "Couldn't start server: $@";
	    }
	    #-- wait a quarter second...
	    select(undef, undef, undef, 0.25);
	}
        #-- Client is finished here
        return $server_pid;
    }

    #-- We're in the server
    require Event::RPC::Server;
    require Event::RPC::Logger;
    require Event_RPC_Test;
    require Event_RPC_Test2;

    #-- This code is mainly copied from the server.pl
    #-- example and works with a command line style
    #-- %opts hash
    my %ssl_args;
    if ( $opts{s} ) {
        %ssl_args = (
            ssl           => 1,
            ssl_key_file  => 't/ssl/server.key',
            ssl_cert_file => ($opts{sf}||'t/ssl/server.crt'),
            ssl_passwd_cb => sub { 'eventrpc' },
        );
        if ( not -f 't/ssl/server.key' ) {
            print "please execute from toplevel directory\n";
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
    my $logger = $opts{l} ? Event::RPC::Logger->new (
        min_level => $opts{l},
        fh_lref   => [ \*STDOUT ],
    ) : undef;

    #-- Create a loop object
    my $loop;
    my $loop_module = $opts{L};
    if ( $loop_module ) {
        eval "use $loop_module";
        die $@ if $@;
        $loop = $loop_module->new();
    }
    
    my $port = $opts{p} || 5555;
    
    my $disconnect_cnt = $opts{S};
    
    #-- Create a Server instance and declare the
    #-- exported interface
    my $server;
    $server = Event::RPC::Server->new (
        name               => "test daemon",
        port               => $port,
        loop               => $loop,
        logger             => $logger,
        start_log_listener => 1,
        load_modules       => 0,
        message_formats    => $opts{f},
        insecure_msg_fmt_ok => $opts{i},
        %auth_args,
        %ssl_args,
        classes => {
            'Event_RPC_Test'   => {
                new              => '_constructor',
                singleton        => '_singleton',
                set_data         => 1,
                get_data         => 1,
                hello            => 1,
                quit             => 1,
                clone            => '_object',
                multi            => '_object',
                get_object2      => '_object',
                new_object2      => '_object',
                echo             => 1,
                get_cid          => 1,
                get_object_cnt   => 1,
                get_undef_object => '_object',
                get_big_data_struct => 1,
                async_call_1     => 'object:async:reeintrant'
            },
            'Event_RPC_Test2'  => {
                new              => '_constructor',
                set_data         => 1,
                get_data         => 1,
                hello            => 1,
                quit             => 1,
                clone            => '_object',
                multi            => '_object',
                get_object2      => '_object',
                new_object2      => '_object',
                echo             => 1,
                get_cid          => 1,
                get_object_cnt   => 1,
                get_undef_object => '_object',
                get_big_data_struct => 1,
                async_call_1     => 'object:async:reeintrant'
            },
            'Event_RPC_Test2'  => {
                new              => '_constructor',
                set_data         => 1,
                get_data         => 1,
                get_object_copy  => 1,
            },
        },
        connection_hook   => sub {
            my ($conn, $event) = @_;
            return if $event eq 'connect';
            --$disconnect_cnt;
            $server->stop
                if $disconnect_cnt <= 0 &&
                    $server->get_clients_connected == 0;
            1;
        },
    );

    $server->set_max_packet_size($opts{M}) if $opts{M};

    #-- Start the server resp. the Event loop.
    $server->start;
    
    #-- Exit the program
    exit;
}

sub port {
    my $file = "port.txt";

    open (my $fh, "+>>", $file) or die "Can't open '$file': $!";
    flock($fh, LOCK_EX) or die "Cannot lock $file: $!";

    seek $fh, 0, 0;

    my $port = <$fh> || 27808;
    chomp $port;

    truncate $fh, 0;

    $port += 2;

    $port = 27810 if $port > 65000;

    print $fh "$port\n";
    close $fh;
    
    return $port;
}

1;

