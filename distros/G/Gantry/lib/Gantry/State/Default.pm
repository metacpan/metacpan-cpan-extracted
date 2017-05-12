package Gantry::State::Default;
require Exporter;

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

############################################################
# Functions                                                #
############################################################

#-------------------------------------------------
# $self->state_run( r_or_cgi, plugin_callbacks )
#-------------------------------------------------
sub state_run {
    my ( $self, $r_or_cgi, $plugin_callbacks ) = @_;
    
    my ( @p, $p1 );


    eval {

        if (defined $plugin_callbacks->{ $self->namespace }->{ post_engine_init }) {
            # Do the plugin callbacks for the 'post_engine_init' phase
            foreach my $cb (
                @{ $plugin_callbacks->{ $self->namespace }->{ post_engine_init } }
            ) {
                $cb->( $self );
            }
        }

        # Do the plugin callbacks for the 'pre_init' phase 
        if (defined $plugin_callbacks->{ $self->namespace }->{ pre_init }) {
            foreach my $cb (
               @{ $plugin_callbacks->{ $self->namespace }->{ pre_init } }
            ) {
                $cb->( $self, $r_or_cgi );
            }
        }

        $self->init( $r_or_cgi );

        @p  = $self->cleanroot( $self->dispatch_location() );
        $p1 = ( shift( @p ) || 'main' );

        # set the action
        $self->action( 'do_'. $p1 );

        if (defined $plugin_callbacks->{ $self->namespace }->{ post_init }) {
            # Do the plugin callbacks for the 'post_init' phase 
            foreach my $cb ( 
                @{ $plugin_callbacks->{ $self->namespace }->{ post_init } } 
            ) {
                $cb->( $self );
            }
        }
    };

    # Call do_error and Return
    if( $@ ) {
        my $e = $@;
        return( $self->cast_custom_error( $self->custom_error( $e ), $e ) );
    }
    
    # check for response page -- used primarily for caching
    if ( $self->gantry_response_page() ) {
        $self->set_content_type();
        $self->set_no_cache();       
        $self->send_http_header();
        $self->print_output( $self->gantry_response_page() );
        return( $self->success_code() );            
    }
    
    eval {    

        if (defined $plugin_callbacks->{ $self->namespace }->{ pre_action }) {
            # Do the plugin callbacks for the 'pre_action' phase 
            foreach my $cb ( 
                @{ $plugin_callbacks->{ $self->namespace }->{ pre_action } } 
            ) {
                $cb->( $self );
            }
        }

        # Do action if valid
        if ( $self->can( $self->action() ) ) {  
            $self->do_action( $self->action(), @p );
            $self->cleanup( );  # Cleanup.
        }
        
        # Try default action
        elsif ( $self->can( 'do_default' ) ) {
            $self->do_action( 'do_default', $p1, @p );
            $self->cleanup( );
        }
        
        # Else return declined
        else {
            $self->declined( 1 );
        }
        
        $self->declined( 1 ) if ( $self->is_status_declined( ) );

        if (defined $plugin_callbacks->{ $self->namespace }->{ post_action }) {
            # Do the plugin callbacks for the 'post_action' phase 
            foreach my $cb ( 
                @{ $plugin_callbacks->{ $self->namespace }->{ post_action } } 
            ) {
                $cb->( $self );
            }
        }
    };

    # Return REDIRECT
    return $self->redirect_response() if ( $self->redirect );
    
    # Return DECLINED
    return $self->declined_response( $self->action() ) if ( $self->declined );
        
    # Call do_error and Return 
    if( $@ ) {
        my $e = $@;

        return( $self->cast_custom_error( $self->custom_error( $e ), $e ) );
    }

    # set http headers
    $self->set_content_type();
    $self->set_no_cache();
    
    # Call do_process, defined within the template plugin
    eval {
        if (defined $plugin_callbacks->{ $self->namespace }->{ pre_process }) {
            # Do the plugin callbacks for the 'pre_process' phase
            foreach my $cb ( 
                @{ $plugin_callbacks->{ $self->namespace }->{ pre_process } } 
            ) {
                $cb->( $self );
            }
        }

        $self->gantry_response_page( $self->do_process() || '' );

        if (defined $plugin_callbacks->{ $self->namespace }->{ post_process }) {
            # Do the plugin callbacks for the 'post_process' phase 
            foreach my $cb ( 
                @{ $plugin_callbacks->{ $self->namespace }->{ post_process } } 
            ) {
                $cb->( $self );
            }
        }

        my $status = $self->status() ? $self->status() : 200;

        if ( $status < 400 ) {

            $self->send_http_header();
            $self->print_output( $self->gantry_response_page() );

        } else {

            $self->cast_custom_error( $self->gantry_response_page() ); 

        }
    };

    if ( $@ ) {
        my $e = $@;
        
        $self->do_error( $e );
        return( $self->cast_custom_error( $self->custom_error( $e ), $e ) );
    }
    
    my $status = $self->status() ? $self->status() : $self->success_code;
    
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
    
    return( $self->status_const( 'REDIRECT' ) );
    
} # end relocate

#-------------------------------------------------
# $self->relocate_permanently( $location )
#-------------------------------------------------
sub relocate_permanently {
    my ( $self, $location ) = ( shift, shift );

    $location = $self->location if ( ! defined $location );
    $self->header_out( 'location', $location );
    $self->status( $self->status_const( 'MOVED_PERMANENTLY' ) );

    return( $self->status_const( 'MOVED_PERMANENTLY' ) );

} # end relocate_permanently

#-------------------------------------------------
# $self->state_engine
#-------------------------------------------------
sub state_engine {
    return __PACKAGE__;

} # end state_engine

1;

__END__
  
=head1 NAME

Gantry::State::Default - Default state handler for Gantry

=head1 SYNOPSIS

This module implements the default handler to control the execution
context within Gantry’s handler() method.

=head1 DESCRIPTION

When a request comes into Gantry a pre‐determined set of steps are executed. 
These pre‐determined steps can be termed "states", and the process can be 
called a "state machine". There are many ways to implement a "state machine", 
so this document will not get into the semantics of the term.

What this module does, is take Gantry's default handling of a request,
and places it into a loadable module. With these "states" now in a
loadable module, you can change the execution order to suit your 
applications needs.

Why is this desirable?

Let’s say you have an application the loads some plugins, those plugins
must do a relocation for proper initialization and this relocation must
be done before the controllers can execute properly. Or you want "hook"
processing, using per and post "hook" plugins. With the default handler, 
this is not possible, with a loadable "state machine" this is now
quite easy to do.

This module also moves the methods relocate() and relocate_permanently() 
from Gantry.pm into this module.

=head1 CONFIGURATION

To load a differant state machine you need to do the following:

=over 4

use MyApp qw{ −StateMachine=Machine };

=back

=head1 METHODS

=over 4

=item state_run

This method is where the logic goes for your handler. It will
receive two paramters:

 r_or_cgi          This is passed into Gantry’s handler() method
                   and is determined by the execution environment
                   that Gantry is running within (CGI, MP13, MP20).

 plugin_callbacks  This is determined by Gantry at runtime.

Example:

=over 4

 sub state_run {
     my ($self, $r_or_cgi, $plugin_callbacks) = @_;

     # your code goes here

 }

=back

=item state_engine

This method returns the name of the state machine.

$name = $self−>state_engine;

=item relocate

This method can be called from any controller and will relocate the
user to the given location.

$self−>relocate( location );

=item relocate_permanently

This method can be called from any controller and will relocate the
user to the given location using HTTP_MOVED_PERMANENTLY 301.

$self−>relocate_permanently( location );

=back

=head1 SEE ALSO

Gantry

=head1 AUTHOR

Kevin L. Esteb <kesteb@wsipc.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
