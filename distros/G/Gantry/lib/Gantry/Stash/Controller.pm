package Gantry::Stash::Controller;
package controller;

#-------------------------------------------------
# AUTOLOAD
#-------------------------------------------------
sub AUTOLOAD {
    my $self    = shift;
    my $command = our $AUTOLOAD;
    $command    =~ s/.*://;

    die( "Undefined stash->controller method $command" );

} # end AUTOLOAD

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
# data( value )
#-------------------------------------------------
sub data {
    my( $self, $p ) = ( shift, shift );

    $self->{__DATA__} = $p if defined $p;
    return( $self->{__DATA__} );

} # end data

1;

__END__

=head1 NAME

Gantry::Stash::Controller - Stash object for the controller

=head1 SYNOPSIS

    $self->stash->controller->data( {} );

=head1 DESCRIPTION

Controller data is an alternative to things like pnotes for data you want
to track during a single requiest.

=head1 METHODS

=over 4

=item data

=back

=head1 SEE ALSO

Gantry(3), Gantry::Stash(3)

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

