package Mail::Decency::LogParser::Core;

use Moose;
extends qw/
    Mail::Decency::Core::Child
/;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;

=head1 NAME

Mail::Decency::LogParser::Stats


=head1 DESCRIPTION

Generates usage statistics by configurable granulity (

=head1 CLASS ATTRIBUTES

=cut

has current_data => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

=head1 METHODS

=head2 init

=cut

sub init {
    my ( $self ) = @_;
    $self->setup;
}

=head2 handle

=cut

sub handle {
    my ( $self, $parsed_ref ) = @_;
    $self->current_data( {} );
    $self->handle_data( $parsed_ref );
}



=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
