package Mail::Decency::Core::POEForking;

use strict;
use warnings;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Scalar::Util qw/ weaken /;

use POE qw/
    Filter::Postfix::Base64
    Filter::Postfix::Null
    Filter::Postfix::Plain
    Wheel::ReadWrite
    Wheel::SocketFactory
/;

=head1 NAME

Mail::Decency::Core::POEForking

=head1 DESCRIPTION

Base class for Postfix and SMTP server. Implements forking


=head1 METHODS


=head2 new

=cut

sub new {
    my ( $class, $decency, $args_ref ) = @_;
    
    weaken( my $decency_weak = $decency );
    POE::Session->create(
        inline_states => {
            _start             => \&forking_startup,
            _stop              => \&forking_halt,
            fork_child         => \&forking_fork_child,
            catch_sig_int      => \&forking_catch_sig_int,
            catch_sig_term     => \&forking_catch_sig_term,
            catch_sig_child    => \&forking_catch_sig_child,
            new_connection     => \&forking_new_connection,
            client_error       => \&forking_client_error,
            new_client_session => sub {
                my ( $heap, $client_session ) = @_[ HEAP, ARG0 ];
                $heap->{ client_sessions } ||= {};
                $heap->{ client_sessions }->{ $client_session->ID } = $client_session;
            },
            #_child             => sub { undef },
            # _default           => sub {
            #     my ( $heap, $event, $args ) = @_[ HEAP, ARG0, ARG1 ];
            #     $heap->{ decency }->logger->error( "** UNKNOWN EVENT $event, $args" );
            # }
        },
        heap => {
            decency => $decency_weak,
            conf    => $decency_weak->config,
            args    => $args_ref,
            class   => $class
        }
    );
}


=head2 forking_startup

Server startup event

=cut

sub forking_startup {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    # listen to port and adress
    $heap->{ server } = POE::Wheel::SocketFactory->new(
        BindAddress  => $heap->{ conf }->{ server }->{ host },
        BindPort     => $heap->{ conf }->{ server }->{ port },
        SuccessEvent => "new_connection",
        FailureEvent => "client_error",
        Reuse        => "yes"
    );
    
    # master does not list
    #$heap->{ server }->pause_accept();
    
    # bing sig int to final sig int (bye bye)
    $kernel->sig( INT  => "catch_sig_int" );
    $kernel->sig( TERM => "catch_sig_term" );
    
    # this is the parental process, set list of childs
    $heap->{ childs } = {};
    
    # mark as parent
    $heap->{ is_child } = 0;
    
    # startup message
    $heap->{ server_address } = "$heap->{ conf }->{ server }->{ host }:$heap->{ conf }->{ server }->{ port }";
    $heap->{ decency }->logger->debug0( "Start server on $heap->{ server_address } ($$)" );
    
    # begin create childs
    $kernel->yield( 'fork_child' );
}


=head2 forking_halt

All goes down

=cut

sub forking_halt {
    my $heap = $_[ HEAP ];
    $heap->{ decency }->logger->debug0( "Stop server on $heap->{ server_address } ($$)" );
}


=head2 forking_fork_child

Create a new child

=cut

sub forking_fork_child {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    # childs don't fork new childs!
    return if $heap->{ is_child };
    
    # main fork loop
    my $max = $heap->{ conf }->{ server }->{ instances } || 3;
    my $check = 0;
    while( scalar( keys %{ $heap->{ childs } } ) < $max ) {
        my $pid = fork();
        
        # oops, could not fork!
        unless ( defined $pid ) {
            $heap->{ decency }->logger->error( "Failed forking child: $!" );
            
            # try, try again!
            $kernel->delay( fork_child => 5 );
            return;
        }
        
        # we are in parent process:
        elsif ( $pid ) {
            
            # add new child
            $heap->{ decency }->logger->debug0( "Add new child $pid to list" );
            $heap->{ childs }->{ $pid } ++;
            
            # bind sig child to handler (if child dies -> this will be called)
            $kernel->sig_child( $pid, "catch_sig_child" );
        }
        
        # we are the child
        else {
            
            # child does accept connections
            #$heap->{ server }->resume_accept();
            
            # tell everybody we are here, new and forked
            $kernel->has_forked;
            
            # assure no misidentification
            $heap->{ is_child }++;
            $heap->{ childs } = {};
            return;
        }
    }
    
}


=head2 forking_catch_sig_int

Catch the death of the master process

=cut

sub forking_catch_sig_int {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    $heap->{ decency }->logger->debug0( "Caught SIG Int ($$)" );
    
    # remove one self
    delete $heap->{ server };
    
    # close all client session
    if ( defined $heap->{ client_sessions } ) {
        $kernel->post( $_, 'good_night' )
            for values %{ $heap->{ client_sessions } };
        delete $heap->{ client_sessions };
    }
    
    # close all childs
    if ( ! $heap->{ is_child } ) {
        kill "INT", $_
            for keys %{ $heap->{ childs } };
    }
    
    # say good night
    $kernel->sig_handled();
}


=head2 forking_catch_sig_int

Catch the death of the master process

=cut

sub forking_catch_sig_term {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    
    $heap->{ decency }->logger->debug0( "Caught SIG Term ($$)" );
    forking_catch_sig_int( @_ );
}



=head2 forking_catch_sig_child

Catch the death of a child .. sad as it might be

=cut

sub forking_catch_sig_child {
    my ( $kernel, $heap, $child_pid ) = @_[ KERNEL, HEAP, ARG1 ];
    
    # if there is NO such child -> return
    return unless delete $heap->{ childs }->{ $child_pid };
    
    # close all client session
    if ( defined $heap->{ client_sessions } ) {
        $kernel->post( $_, 'good_night' ) for values %{ $heap->{ client_sessions } };
        delete $heap->{ client_sessions };
    }
    
    # create new child -> if the server is still there!! (not been killed..)
    $kernel->yield( "fork_child" ) if exists $heap->{ server };
}


=head2 forking_new_connection

New connection etablished

=cut

sub forking_new_connection {
    my $heap = $_[ HEAP ];
    $heap->{ class }->create_handler( @_ );
}


=head2 forking_client_error

Error cleint ..

=cut

sub forking_client_error {
    my ( $kernel, $heap, $session, @args ) = @_[ KERNEL, HEAP, SESSION, ARG0..ARG9 ];
}


=head2 init_factory_args

Can be overwritten by childs

Returns additional args for create the factory

=cut

sub init_factory_args { return () }


=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
