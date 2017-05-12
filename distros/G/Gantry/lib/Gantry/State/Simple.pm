package Gantry::State::Simple;
require Exporter;

use Switch;
use Gantry::State::Constants;

use strict; 
use warnings;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

############################################################
# Variables                                                #
############################################################

@ISA        = qw( Exporter );
@EXPORT     = qw( 
    state_run
    state_engine
    relocate
    relocate_permanently
);

@EXPORT_OK  = qw( );

my ( @p, $p1 );

############################################################
# Functions                                                #
############################################################

#-------------------------------------------------
# $self->state_run( r_or_cgi, plugin_callbacks )
#-------------------------------------------------
sub state_run {
    my ( $self, $r_or_cgi, $plugin_callbacks ) = @_;

    my $status = 200;
    my $state = STATE_POST_ENGINE_INIT;

    eval {

        while ($state) {

            switch ($state) {
                case STATE_POST_ENGINE_INIT {
                    $state = post_engine_init($self, $plugin_callbacks);
                }
                case STATE_PRE_INIT {
                    $state = pre_init($self, $r_or_cgi, $plugin_callbacks);
                    $state = STATE_REDIRECT if ($self->redirect);
                }
                case STATE_INIT {
                    $state = initialize($self, $r_or_cgi);
                    $state = STATE_REDIRECT if ($self->redirect);
                }
                case STATE_POST_INIT {
                    $state = post_init($self, $plugin_callbacks);
                    $state = STATE_REDIRECT if ($self->redirect);
                }
                case STATE_CACHED_PAGES {
                    $state = cached_pages($self);
                }
                case STATE_PRE_ACTION {
                    $state = pre_action($self, $plugin_callbacks);
                    $state = STATE_REDIRECT if ($self->redirect);
                }
                case STATE_ACTION {
                    $state = perform_action($self);
                    $state = STATE_REDIRECT if ($self->redirect);
                    $state = STATE_DECLINED if ($self->declined);
                }
                case STATE_POST_ACTION {
                    $state = post_action($self, $plugin_callbacks);
                    $state = STATE_REDIRECT if ($self->redirect);
                }
                case STATE_SET_HEADERS {
                    $state = set_headers($self);
                }
                case STATE_PRE_PROCESS {
                    $state = pre_process($self, $plugin_callbacks);
                }
                case STATE_PROCESS {
                    $state = process_template($self);
                }
                case STATE_POST_PROCESS {
                    $state = post_process($self, $plugin_callbacks);
                }
                case STATE_OUTPUT {
                    $state = send_output($self);
                }
                case STATE_REDIRECT {
                    $self->redirect_response();
                    $state = STATE_SEND_STATUS;
                }
                case STATE_DECLINED {
                    $self->declined_response($self->action());
                    $state = STATE_SEND_STATUS;
                }
                case STATE_SEND_STATUS {
                    $status =  $self->status ? $self->status : $self->success_code ;
                    $state = STATE_FINI;
                }
            };

        }

    }; if ($@) {

        # Call do_error and return

        my $e = $@;
        $self->do_error($e);
        return($self->cast_custom_error($self->custom_error($e), $e));

    }

    return $status;
}

#-------------------------------------------------
# $self->relocate( $location )
#-------------------------------------------------
sub relocate {
    my ( $self, $location ) = ( shift, shift );

    $location = $self->location if ( ! defined $location );
    $self->redirect( 1 ); # Tag it for the handler to handle nice.
    $self->header_out( 'location', $location );
    $self->status( $self->status_const( 'REDIRECT' ) );

} # end relocate

#-------------------------------------------------
# $self->relocate_permanently( $location )
#-------------------------------------------------
sub relocate_permanently {
    my ( $self, $location ) = ( shift, shift );

    $location = $self->location if ( ! defined $location );
    $self->redirect( 1 ); # Tag it for the handler to handle nice.
    $self->header_out( 'location', $location );
    $self->status( $self->status_const( 'MOVED_PERMANENTLY' ) );

} # end relocate_permanently

#-------------------------------------------------
# $self->state_engine
#-------------------------------------------------
sub state_engine {
    return __PACKAGE__;

} # end state_engine

#-------------------------------------------------
# Private methods
#-------------------------------------------------

sub post_engine_init {
    my ($self, $plugin_callbacks) = @_;

    # Do the plugin callbacks for the 'post_engine_init' phase

    if (defined $plugin_callbacks->{ $self->namespace }->{ post_engine_init }) {

        foreach my $cb (
            @{ $plugin_callbacks->{ $self->namespace }->{ post_engine_init } }
        ) {
            $cb->( $self );
        }

    }

    return STATE_PRE_INIT;

}

sub pre_init {
    my ($self, $r_or_cgi, $plugin_callbacks) = @_;

    # Do the plugin callbacks for the 'pre_init' phase 

    if (defined $plugin_callbacks->{ $self->namespace }->{ pre_init }) {

        foreach my $cb (
            @{ $plugin_callbacks->{ $self->namespace }->{ pre_init } }
        ) {
            $cb->( $self, $r_or_cgi );
        }

    }

    return STATE_INIT;

}

sub initialize {
    my ($self, $r_or_cgi) = @_;

    $self->init( $r_or_cgi );

    @p  = $self->cleanroot( $self->dispatch_location() );
    $p1 = ( shift( @p ) || 'main' );

    # set the action
    $self->action( 'do_'. $p1 );

    return STATE_POST_INIT;

}

sub post_init {
    my ($self, $plugin_callbacks) = @_;

    # Do the plugin callbacks for the 'post_init' phase 

    if (defined $plugin_callbacks->{ $self->namespace }->{ post_init }) {

        foreach my $cb ( 
            @{ $plugin_callbacks->{ $self->namespace }->{ post_init } } 
        ) {
            $cb->( $self );
        }

    }

    return STATE_CACHED_PAGES;

}

sub cached_pages {
    my ($self) = @_;

    # check for response page -- used primarily for caching

    if ($self->gantry_response_page()) {

        $self->set_content_type();
        $self->set_no_cache();       
        $self->status($self->success_code());
        return STATE_OUTPUT;

    }

    return STATE_PRE_ACTION;

}

sub pre_action {
    my ($self, $plugin_callbacks) = @_;

    # Do the plugin callbacks for the 'pre_action' phase

    if (defined $plugin_callbacks->{ $self->namespace }->{ pre_action }) {

        foreach my $cb (
            @{ $plugin_callbacks->{ $self->namespace }->{ pre_action } } 
        ) {
            $cb->( $self );
        }

    }

    return STATE_ACTION;

}

sub perform_action {
    my ($self) = @_;

    # Do action if valid

    if ($self->can($self->action())) {  

        $self->do_action($self->action(), @p);
        $self->cleanup();  # Cleanup.

    } elsif ($self->can('do_default')) {

        # try the default action

        $self->do_action('do_default', $p1, @p);
        $self->cleanup();

    } else {

        # else return declined

        $self->declined(1);

    }

    $self->declined(1) if ($self->is_status_declined());

    return STATE_POST_ACTION;

}

sub post_action {
    my ($self, $plugin_callbacks) = @_;

    # Do the plugin callbacks for the 'post_action' phase

    if (defined $plugin_callbacks->{ $self->namespace }->{ post_action }) {

        foreach my $cb (
            @{ $plugin_callbacks->{ $self->namespace }->{ post_action } } 
        ) {
            $cb->( $self );
        }

    }

    return STATE_SET_HEADERS;

}

sub set_headers {
    my ($self) = @_;

    # set http headers

    $self->set_content_type();
    $self->set_no_cache();

    return STATE_PRE_PROCESS;

}

sub pre_process {
    my ($self, $plugin_callbacks) = @_;

    # Do the plugin callbacks for the 'pre_process' phase

    if (defined $plugin_callbacks->{ $self->namespace }->{ pre_process }) {

        foreach my $cb ( 
            @{ $plugin_callbacks->{ $self->namespace }->{ pre_process } } 
        ) {
            $cb->( $self );
        }

    }

    return STATE_PROCESS;

}

sub process_template {
    my ($self) = @_;

    $self->gantry_response_page( $self->do_process() || '' );

    return STATE_POST_PROCESS;

}

sub post_process {
    my ($self, $plugin_callbacks) = @_;

    # Do the plugin callbacks for the 'post_process' phase 

    if (defined $plugin_callbacks->{ $self->namespace }->{ post_process }) {

        foreach my $cb ( 
            @{ $plugin_callbacks->{ $self->namespace }->{ post_process } } 
        ) {
            $cb->( $self );
        }

    }

    return STATE_OUTPUT;

}

sub send_output {
    my ($self) = @_;

    my $status = $self->status() ? $self->status() : 200;

    if ( $status < 400 ) {
        $self->send_http_header();
        $self->print_output( $self->gantry_response_page() );        
        $self->status($self->status_const('OK'));

    } else {

        $self->cast_custom_error( $self->gantry_response_page() ); 

    }

    return STATE_SEND_STATUS;

}

1;

__END__

=head1 NAME

Gantry::State::Simple - A simple state machine for Gantry

=head1 SYNOPSIS

This module implements a simple state machine to control the execution
context within Gantry’s handler() method.

=head1 DESCRIPTION

When a request comes into Gantry a pre‐determined set of steps are executed. 
These pre‐determined steps can be termed "states", and the process can be 
called a "state machine". There are many ways to implement a "state machine", 
so this document will not get into the semantics of the term.

What this module does, is allow plugins to issue a redirect and have them
take effect immediately. The default behavior is to have the redirect happen
after the controllers have finished processing.

This is to allow a plugin to initialize properly. For example 
Gantry::Plugins::Session requires a redirect to /cookiecheck to see if the 
session cookie has been set. Under the default state handler, this redirect 
happens after the initial controller has finished processing. 

So a race condition happens. You can not manipulate a session until the 
cookie has been established which doesn't happen until after the initial 
controller executes. This problem goes away after the redirect.

This module fixes the problem. 

=head1 CONFIGURATION

To load a differant state machine you need to do the following:

=over 4

use MyApp qw{ −StateMachine=Simple };

=back

=head1 SEE ALSO

 Gantry
 Gantry::State::Default
 Gantry::State::Constants

=head1 AUTHOR

Kevin L. Esteb <kesteb@wsipc.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
