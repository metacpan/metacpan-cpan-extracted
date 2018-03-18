use strict;
use warnings;

package Footprintless::Resource::MavenProvider;
$Footprintless::Resource::MavenProvider::VERSION = '1.28';
# ABSTRACT: A resource provider for resources retrieved by maven coordinate
# PODNAME: Footprintless::Resource::MavenProvider

use parent qw(Footprintless::Resource::Provider);

use Maven::Agent;

sub _download {
    my ( $self, $resource, %options ) = @_;
    return $self->{maven_agent}->download( $resource->get_artifact(), %options );
}

sub _init {
    my ( $self, %options ) = @_;

    $self->{maven_agent} = Maven::Agent->new( agent => $self->{factory}->agent() );

    return $self;
}

sub resource {
    my ( $self, $spec ) = @_;

    return $spec if ( UNIVERSAL::isa( $spec, 'Footprintless::Resource::Maven' ) );

    return Footprintless::Resource::Maven->new(
        $self->{maven_agent}->resolve_or_die( ref($spec) ? $spec->{coordinate} : $spec ) );
}

sub supports {
    my ( $self, $resource ) = @_;

    return 1 if ( UNIVERSAL::isa( $resource, 'Footprintless::Resource::Maven' ) );

    my $ref = ref($resource);
    if ($ref) {
        return 1 if ( $resource->{coordinate} );
    }
    elsif ( $resource =~ /^(?:[^:]+:){2,4}[^:]+$/ ) {
        return 1;
    }

    return 0;
}

1;

__END__

=pod

=head1 NAME

Footprintless::Resource::MavenProvider - A resource provider for resources retrieved by maven coordinate

=head1 VERSION

version 1.28

=head1 METHODS

=head2 download($resource, \%options)

Downloads C<$resource> and returns the filename it downloaded to.  If 
using C<Maven::MvnAgent>, the resource will be cached in the local C<.m2>
repository.  All options are passed through to 
C<$maven_agent-E<gt>download()>.

=head2 resource($spec)

Returns the C<Footprintless::Resource::Maven> indicated by C<$spec>.

=head2 supports($spec)

Returns C<1> if C<$resource> is a hash ref containing an entry for 
C<coordinate>, or if C<$resource> is a string in the form of a maven 
coordinate (ex: groupId:artifactId:[packaging]:[classifier]:version).

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

L<Footprintless::Resource::Maven|Footprintless::Resource::Maven>

=item *

L<Footprintless::Resource::Provider|Footprintless::Resource::Provider>

=item *

L<Footprintless::ResourceManager|Footprintless::ResourceManager>

=item *

L<Footprintless|Footprintless>

=item *

L<Maven::Agent|Maven::Agent>

=item *

L<Maven::MvnAgent|Maven::MvnAgent>

=back

=cut
