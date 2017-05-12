package Mail::Decency::ContentFilter::Core::Virus;

use Moose::Role;

use version 0.74; our $VERSION = qv( "v0.1.6" );

use Mail::Decency::ContentFilter::Core::Constants;
use Data::Dumper;

=head1 NAME

Mail::Decency::ContentFilter::Core::Virus

=head1 DESCRIPTION

For all modules being a virus filter



=head2 METHODS

=head2 found_virus

Called whenever a virus is found by the virus filter module.

=cut

sub found_virus {
    my ( $self, $info_ref ) = @_;
    return $self->server->found_virus( $info_ref );
}


=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
