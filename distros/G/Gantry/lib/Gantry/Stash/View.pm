package Gantry::Stash::View;
package view;
use strict;

use Gantry::Stash::View::Form;
  
#-------------------------------------------------
# AUTOLOAD 
#-------------------------------------------------
sub AUTOLOAD {
    my $self    = shift;
    my $command = our $AUTOLOAD;
    $command    =~ s/.*://;

    die( "Undefined stash->view method $command" );
}

#-------------------------------------------------
# DESTROY
#-------------------------------------------------
sub DESTROY { }
                
#-------------------------------------------------
# new 
#-------------------------------------------------
sub new {
    my $class   = shift;
    my $self    = bless( {}, $class );
    return $self;

} # end new

#-------------------------------------------------
# template( value )
#-------------------------------------------------
sub template {
    my( $self, $p ) = ( shift, shift );

    $self->{__TEMPLATE__} = $p if defined $p;
    return( $self->{__TEMPLATE__} );

} # end template

#-------------------------------------------------
# data( value )
#-------------------------------------------------
sub data {
    my( $self, $p ) = ( shift, shift );

    $self->{__DATA__} = $p if defined $p;
    return( $self->{__DATA__} );

} # end data

#-------------------------------------------------
# title( value )
#-------------------------------------------------
sub title {
    my( $self, $p ) = ( shift, shift );

    $self->{__TITLE__} = $p if defined $p;
    return( $self->{__TITLE__} );
    
} # end title

#-------------------------------------------------
# form( value )
#-------------------------------------------------
sub form {
    my( $self, $p ) = ( shift, shift );

    $self->{__FORM__} = form->new( $p ) if defined $p;

    $self->{__FORM__} = form->new( ) unless defined $self->{__FORM__};

    return( $self->{__FORM__} );
}

1;

__END__

=head1 NAME

Gantry::Stash::View - Stash object for the view

=head1 SYNOPSIS

    $self->stash->view->title( 'Your Browser Window Title Here' );
    $self->stash->view->template( 'some_template.template' );
    $self->stash->view->data( { } ); # the hash goes to template's proccessor

=head1 DESCRIPTION

Gantry builds the stash view for you in its handler.  Fill in values as
shown above to communicate with your template and/or your template engine.

=head1 METHODS

=over 4

=item template

=item data

=item title

=back

=head1 MODULES

=over 4

=item Gantry::Stash::View::Form

=back

=head1 SEE ALSO

Gantry(3), Gantry::Stash(3), Gantry::Stash::View::Form(3)

=head1 LIMITATIONS

=head1 AUTHOR

Phil Crow <pcrow@sunflowerbroadband.com>
Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005, Phil Crow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

