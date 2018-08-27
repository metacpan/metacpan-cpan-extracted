use strict;
use warnings;

package Footprintless::Resource::Maven;
$Footprintless::Resource::Maven::VERSION = '1.29';
# ABSTRACT: A resource described by Maven artifact
# PODNAME: Footprintless::Resource::Maven

use parent qw(Footprintless::Resource);

sub get_artifact {
    return $_[0]->{artifact};
}

sub _init {
    my ( $self, $artifact ) = @_;

    $self->Footprintless::Resource::_init( $artifact->get_url() );
    $self->{artifact} = $artifact;

    return $self;
}

1;

__END__

=pod

=head1 NAME

Footprintless::Resource::Maven - A resource described by Maven artifact

=head1 VERSION

version 1.29

=head1 CONSTRUCTORS

=head2 new($artifact)

Creates a new C<Footprintless::Resource::Maven> for the supplied 
artifact.

=head1 ATTRIBUTES

=head2 get_artifact()

Returns the C<Maven::Artifact> object for the resource.

=head2 get_url()

Returns the URL for this resource.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::Resource::MavenProvider|Footprintless::Resource::MavenProvider>

=item *

L<Footprintless::ResourceManager|Footprintless::ResourceManager>

=item *

L<Footprintless|Footprintless>

=item *

L<Maven::Artifact|Maven::Artifact>

=back

=cut
