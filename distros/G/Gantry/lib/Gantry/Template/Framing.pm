package Gantry::Template::Framing;

########### STILL BROKEN #######################

use strict;

use base 'Exporter';

use Carp;

############################################################
# Variables                                                #
############################################################
our @EXPORT     = qw( 
    do_action
    do_error
    do_process 
    template_engine
);

############################################################
# Functions                                                #
############################################################
#-------------------------------------------------
# $self->do_action( 'do_main|do_edit', @p )
#-------------------------------------------------
sub do_action {
    my( $self, $action, @p ) = @_;
    
    $self->stash->controller->data( $self->$action( @p ) ); 
}

#-------------------------------------------------
# $self->do_error( $r, @err )
#-------------------------------------------------
sub do_error {
    my( $self, $r, @err ) = @_;
    
#    $r->log_error( @err ); 

}

#-------------------------------------------------
# $self->do_process( $r, @err )
#-------------------------------------------------
sub do_process {
    my( $self ) = @_;

    if ( $self->template_disable ) {
        return( $self->stash->controller->data );
    }
    else {
        if ( not defined $self->stash->view->tempalte ) {
            $self->stash->view->template( $self->template );
        }

        return( $self->stash->view->data . $self->stash->controller->data )
            if not $self->stash->view->tempalte;

        return $self->_templatify();
    }
} # END do_process

#-------------------------------------------------
# $self->_templatify
#-------------------------------------------------
sub _templatify {
    my $self = shift;

    my $retval;

    # find the template
    my $template_file;
    my @dirs = split /:/, $self->root;  # assumes Unix style paths

    CANDIDATE_DIR:
    foreach my $dir ( @dirs ) {
        my $candidate = "$dir/" . $self->template;

        if ( -f $candidate ) {
            $template_file = $candidate;
            last CANDIDATE_DIR;
        }
    }

    die 'Error: could not find ' . $self->template . ' in ' . $self->root
            unless $template_file;

    open my $TEMPLATE, '<', $template_file
            or die "Couldn't read $template_file: $!";

    while ( my $line = <$TEMPLATE> ) {

        if ( $line =~ /(##DIR_CONFIG\(([a-zA-Z_0-9-]+)\)##)/ ) {
            my $val = $self->fish_config($2) || '';
            my $hook = quotemeta($1);

            $line =~ s/$hook/$val/g;
        }

        # directives to implement:
        # x DIR_CONFIG
        # - VAR
        # BODY_TEXT
        # AUX_BODY_TEXT
        # AUX_BODY_TEXT2
        # PAGE_TITLE
        # ONPAGE_TITLE
        # DATE
        # USER_NAME
        # INCLUDE (not yet), dumps a named file from doc root to output stream
    }

    close $TEMPLATE;

    return $retval;
}

#-------------------------------------------------
# $self->template_engine
#-------------------------------------------------
sub template_engine {
    return __PACKAGE__;
}

1;

__END__

=head1 NAME

Gantry::Template::Framing - Framing  plugin for Gantry.

=head1 SYNOPSIS

  use Gantry::Template::Framing;


=head1 DESCRIPTION

To use Old World framing do something like this:

    use Gantry qw/ -Engine=YourChoice -TemplateEngine=Framing /;

This plugin module contains the method calls for the Template Framing.

=head1 METHODS

=over 4

=item $self->do_action

C<do_action> is a required function for the template plugin. It purpose
is to call or dispatch to the appropriate method. This function is passed
three parameters:

my( $self, $action, @path_array ) = @_;

This method is responsible for calling the controller method and
storing the output from the controller.

=item $self->do_error

This method gives you the flexibility of logging, re-estabilishing a
database connection, rebuilding the template object, etc.

=item $self->do_process

This method is the final step in the template plugin. Here you need
call the template object passing the controller data and return the
output.

=item webapp_get_framing

A function for internal use.  Returns to other methods of this class
an old world framing object.

=item template_engine

Returns the package name.

=back

=head1 SEE ALSO

Gantry(3), Gantry::Template::TT


=head1 LIMITATIONS


=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
