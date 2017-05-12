use strict;
use warnings;

package Maven::Repository;
$Maven::Repository::VERSION = '1.14';
# ABSTRACT: An repository from which to resolve artifacts
# PODNAME: Maven::Repository

use parent qw(Class::Accessor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(agent url));

use Carp;
use Log::Any;
use Maven::Artifact;
use Maven::Xml::Metadata;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub _build_url {
    my ( $self, $artifact ) = @_;

    my @url =
        ( $self->{url}, split( /\./, $artifact->get_groupId() ), $artifact->get_artifactId() );

    my $artifact_name;
    if ( !$artifact->get_version() ) {

        # no version specified, detect latest
        $logger->trace('version not specified, detecting...');
        my $version = $self->_detect_latest_version( join( '/', @url ) );

        return if ( !$version );

        $artifact->set_version($version);
    }
    if ( $artifact->get_version() =~ /^.*-SNAPSHOT$/ ) {

        # snapshot version, detect most recent timestamp
        my $snapshotVersion = $self->_detect_latest_snapshotVersion(
            join( '/', @url, $artifact->get_version() ),
            $artifact->get_packaging(),
            $artifact->get_classifier()
        );

        return if ( !$snapshotVersion );

        $artifact_name = join( '-', $artifact->get_artifactId(), $snapshotVersion->get_value() );
        if ( $artifact->get_classifier() ) {
            $artifact_name .= '-' . $artifact->get_classifier();
        }
        $artifact_name .= '.' . $artifact->get_packaging();
    }
    else {
        $artifact_name = join( '-', $artifact->get_artifactId(), $artifact->get_version() );
        if ( $artifact->get_classifier() ) {
            $artifact_name .= '-' . $artifact->get_classifier();
        }
        $artifact_name .= '.' . $artifact->get_packaging();
    }
    $artifact->set_artifact_name($artifact_name);

    my $url = join( '/', @url, $artifact->get_version(), $artifact_name );

    # verify version is available in repo
    $logger->tracef(
        'verifying version %s is available on %s',
        $artifact->get_version(),
        $self->to_string()
    ) if ( $logger->is_trace() );
    return $self->_has_version($url) ? $url : undef;
}

sub contains {
    my ( $self, $url ) = @_;
    return $self->{url} eq substr( $url, 0, length( $self->{url} ) );
}

sub _detect_latest_snapshotVersion {
}

sub _detect_latest_version {
}

sub _has_version {
}

sub _init {
    my ( $self, $url, %args ) = @_;

    $self->{url} = $url;

    return $self;
}

sub resolve {
    my ( $self, $artifact, @parts ) = @_;

    if ( ref($artifact) eq 'Maven::Artifact' ) {

        # already resolved, no need to do so again
        return $artifact if ( $artifact->get_url() );
    }
    else {
        $artifact = Maven::Artifact->new( $artifact, @parts );
        $logger->trace( 'resolving ', $artifact );
    }
    croak('invalid artifact, no groupId')    if ( !$artifact->get_groupId() );
    croak('invalid artifact, no artifactId') if ( !$artifact->get_artifactId() );

    my $url = $self->_build_url($artifact);
    if ( defined($url) ) {
        $artifact->set_url($url);
        return $artifact;
    }
    return;
}

sub to_string {
    my ($self) = @_;
    return $self->{url};
}

1;

__END__

=pod

=head1 NAME

Maven::Repository - An repository from which to resolve artifacts

=head1 VERSION

version 1.14

=head1 SYNOPSIS

    # Base class for repositories

=head1 DESCRIPTION

Base class for repositories.  Should not be used directly

=head1 METHODS

=head2 contains($url)

Returns true if C<$url> starts with this repositories url.

=head2 resolve

Will attempt to resolve C<$artifact>.  C<$artifact> can be either an 
instance of L<Maven::Artifact> or a coordinate string of the form
L<groupId:artifactId[:packaging[:classifier]]:version|https://maven.apache.org/pom.html#Maven_Coordinates>
If resolution was successful, a new L<Maven::Artifact> will be returned 
with its C<uri> set.  Otherwise, C<undef> will be returned.  If C<%parts> 
are supplied, their values will be used to override the corresponding values
in C<$artifact> before resolution is attempted.

=head2 to_string

Returns the repository url.

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

L<Maven::LocalRepository|Maven::LocalRepository>

=item *

L<Maven::RemoteRepository|Maven::RemoteRepository>

=item *

L<Maven::Repositories|Maven::Repositories>

=back

=cut
