package Gantry::Stash::View::Form;
package form;

use strict;

sub new {
    my $class   = shift;
    my $input   = shift;

    my $self;
    
    if ( $input ) { $self = bless( $input, $class ); }
    else          { $self = bless( {},     $class ); }

    return $self;
}

sub results {
    my( $self, $p ) = ( shift, shift );

    $self->{results} = $p if defined $p;
    return( $self->{results} );
}


sub error_text {
    my( $self, $p ) = ( shift, shift );

    $self->{error_text} = $p if defined $p;
    return( $self->{error_text} );

} # end error_text

sub message {
    my( $self, $p ) = ( shift, shift );

    $self->{message} = $p if defined $p;
    return( $self->{message} );
}

1;

__END__

=head1 NAME

Gantry::Stash::View::Form - Stash object for the view's form

=head1 SYNOPSIS

    $self->stash->view->form( { } );

=head1 DESCRIPTION

This module manages the form contents for Gantry::Plugins::AutoCRUD and
Gantry::Plugins::CRUD, see their docs for details of what goes into the hash.

=head1 METHODS

=over 4

=item new

Pass in a proper hash suitable for use by one of the crud plugins.  It
will be blessed into this class.

=item results

Used by add/edit templates to track form validation violations.

=item error_text

Not currently used.

=item message

Used by some templates for question text to present to the user.

=back

=head1 SEE ALSO

Gantry::Plugins::AutoCRUD(3), Gantry(3), Gantry::Stash(3)

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

