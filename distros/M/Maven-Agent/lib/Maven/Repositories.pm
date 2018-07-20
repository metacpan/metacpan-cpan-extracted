use strict;
use warnings;

package Maven::Repositories;
$Maven::Repositories::VERSION = '1.15';
# ABSTRACT: An ordered collection of repositories from which to resolve artifacts
# PODNAME: Maven::Repositories

use parent qw(Class::Accessor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(repositories));

use Carp;
use Log::Any;
use Maven::LocalRepository;
use Maven::RemoteRepository;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub add_central {
    my ( $self, @args ) = @_;
    $logger->debug('adding central');

    return $self->add_repository( 'http://repo.maven.apache.org/maven2', @args );
}

sub _artifact_not_found {
    my ( $self, $coordinate_or_artifact, $options ) = @_;
    my $artifact =
        ref($coordinate_or_artifact)
        && UNIVERSAL::isa( $coordinate_or_artifact, 'Maven::Artifact' )
        ? $coordinate_or_artifact
        : Maven::Artifact->new( $coordinate_or_artifact, %$options )->get_coordinate();
    return "artifact $artifact not found";
}

sub add_local {
    my ( $self, $local_repository_path, @args ) = @_;
    $logger->debugf( 'adding local %s', $local_repository_path );

    push(
        @{ $self->{repositories} },
        Maven::LocalRepository->new( $local_repository_path, @args )
    );

    return $self;
}

sub add_repository {
    my ( $self, $url, @args ) = @_;
    $logger->debugf( 'adding repo %s', $url );

    push( @{ $self->{repositories} }, Maven::RemoteRepository->new( $url, @args ) );

    return $self;
}

sub _init {
    my ( $self, @args ) = @_;
    $logger->trace('initializing repositories');

    $self->{repositories} = [];

    return $self;
}

sub get_repository {
    my ( $self, $url ) = @_;
    foreach my $repository ( @{ $self->{repositories} } ) {
        if ( $repository->contains($url) ) {
            return $repository;
        }
    }
    return;
}

sub resolve {
    my ( $self, $coordinate_or_artifact, @parts ) = @_;

    my $artifact;
    foreach my $repository ( @{ $self->{repositories} } ) {
        last if ( $artifact = $repository->resolve( $coordinate_or_artifact, @parts ) );
    }

    return $artifact;
}

sub resolve_or_die {
    my ( $self, $coordinate_or_artifact, %parts ) = @_;
    my $resolved = $self->resolve( $coordinate_or_artifact, %parts );
    croak( $self->_artifact_not_found( $coordinate_or_artifact, \%parts ) ) if ( !$resolved );

    return $resolved;
}

1;

__END__

=pod

=head1 NAME

Maven::Repositories - An ordered collection of repositories from which to resolve artifacts

=head1 VERSION

version 1.15

=head1 SYNOPSIS

    # Dont use Repositories directly...  instead:
    use Maven::Agent;
    my $agent = Maven::Agent->new();
    $agent->resolve('javax.servlet:servlet-api:2.5');

=head1 DESCRIPTION

Represents an ordered collection of repositories that can be used to resolve
C<Maven::Artifact>'s.  This class should not be used directly.  Instead you 
should use an C<Maven::Agent>.

=head1 METHODS

=head2 add_central(agent => $agent, [%options])

Adds L<maven central|http://repo.maven.apache.org/maven2> to the list of
repositories.  Passes all arguments through to C<add_repository>.

=head2 add_local($local_repository_path)

Add your C<$local_repository_path> to the list of repositories.

=head2 add_repository($url, agent => $agent, [%options])

Adds C<$url> to the list of repositories.  C<$agent> will be used to connect 
to the repository.  The current options are:

=over 4

=item metadata_filename

The name of the metadata file.  Defaults to 'maven-metadata.xml'.

=back

=head2 get_repository($url)

Returns the repository that contains C<$url>.

=head2 resolve($artifact, [%parts])

Will attempt to resolve C<$artifact>.  C<$artifact> can be either an 
instance of L<Maven::Artifact> or a coordinate string of the form
L<groupId:artifactId[:packaging[:classifier]]:version|https://maven.apache.org/pom.html#Maven_Coordinates>
If resolution was successful, a new L<Maven::Artifact> will be returned 
with its C<uri> set.  Otherwise, C<undef> will be returned.  If C<%parts> 
are supplied, their values will be used to override the corresponding values
in C<$artifact> before resolution is attempted.

=head2 resolve_or_die($artifact, [%parts])

Calls L<resolve|/"resolve($artifact, [%parts])">, and, if resolution was 
successful, the new C<$artifact> will be returned, otherwise, C<croak> will 
be called.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Maven::Agent|Maven::Agent>

=item *

L<Maven::MvnAgent|Maven::MvnAgent>

=item *

L<Maven::Artifact|Maven::Artifact>

=item *

L<Maven::Maven|Maven::Maven>

=back

=cut
