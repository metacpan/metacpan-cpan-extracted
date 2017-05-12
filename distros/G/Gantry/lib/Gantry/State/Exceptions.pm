package Gantry::State::Exceptions;
require Exporter;

use Switch;
use Gantry::Exception;
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

    my $X;
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
                }
                case STATE_INIT {
                    $state = initialize($self, $r_or_cgi);
                }
                case STATE_POST_INIT {
                    $state = post_init($self, $plugin_callbacks);
                }
                case STATE_CACHED_PAGES {
                    $state = cached_pages($self);
                }
                case STATE_PRE_ACTION {
                    $state = pre_action($self, $plugin_callbacks);
                }
                case STATE_ACTION {
                    $state = perform_action($self);
                }
                case STATE_POST_ACTION {
                    $state = post_action($self, $plugin_callbacks);
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
                case STATE_SEND_STATUS {
                    $status =  $self->status ? $self->status : $self->success_code ;
                    $state = STATE_FINI;
                }
            };

        }

    }; if ($X = $@) {

        my $ref = ref($X);

        if ($ref && $X->isa('Gantry::Exception::Redirect')) {

            $self->header_out('location', "$X");
            $self->redirect_response();
            $status = $self->status_const('REDIRECT');

        } elsif ($ref && $X->isa('Gantry::Exception::RedirectPermanently')) {

            $self->header_out('location', "$X");
            $self->redirect_response();
            $status = $self->status_const('MOVED_PERMANENTLY');

        } elsif ($ref && $X->isa('Gantry::Exception::Declined')) {

            $status = $self->declined_response($self->action());

        } elsif ($ref && $X->isa('Gantry::Exception')) {

            if ($self->can('exception_handler')) {

                $status = $self->exception_handler($X);

            } else {

                warn "Unexpected exception caught:\n";
                warn "  status = " . $X->status . "\n";
                warn "  message = " . $X->message . "\n";
                $status = 500;

            }

        } else {

            # Call do_error and return

            $self->do_error($X);
            $status = $self->cast_custom_error($self->custom_error($X), $X);

        }

    }

    return $status;

}

#-------------------------------------------------
# $self->relocate( $location )
#-------------------------------------------------
sub relocate {
    my ( $self, $location ) = ( shift, shift );
    
    $location = $self->location if ( ! defined $location );
    Gantry::Exception::Redirect->throw($location);

} # end relocate

#-------------------------------------------------
# $self->relocate_permanently( $location )
#-------------------------------------------------
sub relocate_permanently {
    my ( $self, $location ) = ( shift, shift );

    $location = $self->location if ( ! defined $location );
    Gantry::Exception::RedirectPermanently->throw($location);

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

        Gantry::Exception::Declined->throw();

    }

    Gantry::Exception::Declined->throw() if ($self->is_status_declined());

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

    $self->send_http_header();
    $self->print_output( $self->gantry_response_page() );        
    $self->status($self->status_const('OK'));

    return STATE_SEND_STATUS;

}

1;

__END__

=head1 NAME

Gantry::State::Exceptions - A state machine for Gantry that uses exceptions

=head1 SYNOPSIS

This module implements a state machine to control the execution
context within Gantry’s handler() method. This state machine uses exceptions 
to alter flow instead of flag variables.

=head1 DESCRIPTION

When a request comes into Gantry a pre‐determined set of steps are executed. 
These pre‐determined steps can be termed "states", and the process can be 
called a "state machine". There are many ways to implement a "state machine", 
so this document will not get into the semantics of the term.

The currently implemented state machines use flag variables. At specific 
steps, these variables are checked, the flow is then altered based on the 
results of those tests. Gantry currently handles the following status 
codes: 200, 301, 302, 400 and 500. There are flag variables for these codes and 
handlers to be executed, when they are set. But what if you wanted to use a 
402 code. Well, you would need to create a flag variable, code a state 
machine to check for that variable and create a handler for that condition. 
Not a very scalable solution.

This module introduces the concept of using structured exceptions to 
change the flow of execution. If a redirect is issued using the relocate() 
method, an exception is raised instead of a flag variable being set. The 
exception takes effect immediately and is caught by the state machines handler. 
Which then goes thru the redirect process.

This is not too differant from how Gantry::State::Simple currently works. 
The advantage is that if I wanted to use that 402 code, all I would have to 
do is the following:

 Gantry::Exception->throw(
     status => 402,
     status_line => 'Payment required',
     message => "Gimme all your money, and your luvin\' too..."
 );

And then the exception handler would be able to do the "right thing". If there
is no defined exception handler, a message is printed to stdout and a 500 code 
is returned to the browser.

=head1 CONFIGURATION

To load a differant state machine you need to do the following:

=over 4

use MyApp qw{ -−StateMachine=Exceptions };

=back

=head1 SEE ALSO

 Gantry
 Gantry::Exception
 Gantry::State::Default
 Gantry::State::Simple
 Gantry::State::Constants
 Exception::Class

=head1 AUTHOR

Kevin L. Esteb <kesteb@wsipc.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
