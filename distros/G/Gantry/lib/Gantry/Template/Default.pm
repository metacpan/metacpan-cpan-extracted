package Gantry::Template::Default;
require Exporter;

use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

############################################################
# Variables                                                #
############################################################
@ISA        = qw( Exporter );
@EXPORT     = qw( 
    do_action
    do_error
    do_process
    template_engine
);

@EXPORT_OK  = qw( );

############################################################
# Functions                                                #
############################################################
#-------------------------------------------------
# $site->do_action( 'do_main|do_edit', @p )
#-------------------------------------------------
sub do_action {
    my( $site, $action, @p ) = @_;
    
    $site->stash->controller->data( $site->$action( @p ) ); 
}

#-------------------------------------------------
# $site->do_error( @err )
#-------------------------------------------------
 sub do_error {
    my( $site, @err ) = @_;
    
    #$$site{r}->log_error( $msg ); 

}

#-------------------------------------------------
# $site->do_process( )
#-------------------------------------------------
sub do_process {
    my( $site ) = @_;
    
    return( $site->stash->controller->data );   

} # end do_process

#-------------------------------------------------
# $site->template_engine
#-------------------------------------------------
sub template_engine {
    return __PACKAGE__;
    
} # end template_engine

# EOF
1;

__END__

=head1 NAME

Gantry::Template::Default - Default text plugin for Gantry.

=head1 SYNOPSIS

  use Gantry::Template::Default;


=head1 DESCRIPTION

Use this module when you don't want templating:

    use Gantry qw/ -Engine=YourChoice -TemplateEngine=Default /;

Then, your controller should return plain text ready for immediate handing
to the browser.

=head1 METHODS

=over 4

=item $site->do_action

C<do_action> is a required function for the template plugin. It purpose
is to call or dispatch to the appropriate method. This function is passed
three parameters:

my( $self, $action, @path_array ) = @_;

This method is responsible for calling the controller method and
storing the output from the controller.

=item $site->do_error

This method gives you the flexibility of logging, re-estabilishing a
database connection, rebuilding the template object, etc.

=item $site->do_process

This method is the final step in the template plugin. Here you need
call the template object passing the controller data and return the
output.

=item $site->template_engine

Returns the name of the current template engine.  (The one in this
package always returns the package name.)

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
