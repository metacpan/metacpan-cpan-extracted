use strict;
use warnings;

package Maven::RemoteRepository;
$Maven::RemoteRepository::VERSION = '1.14';
# ABSTRACT: An repository from which to resolve artifacts
# PODNAME: Maven::RemoteRepository

use parent qw(Maven::Repository);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(agent));

use Log::Any;
use Maven::Xml::Metadata;

my $logger = Log::Any->get_logger();

sub _detect_latest_snapshotVersion {
    my ( $self, $base_url, $extension, $classifier ) = @_;

    $logger->tracef( 'loading metadata from %s', $base_url );
    my $metadata = Maven::Xml::Metadata->new(
        agent => $self->{agent},
        url   => "$base_url/$self->{metadata_filename}"
    );
    return if ( !$metadata );

    my $latest_snapshot;
    foreach my $snapshot_version ( @{ $metadata->get_versioning()->get_snapshotVersions() } ) {
        if ( $extension && $extension eq $snapshot_version->get_extension() ) {
            if ( !$classifier || $classifier eq $snapshot_version->get_classifier() ) {
                $latest_snapshot = $snapshot_version;
                last;
            }
        }
    }
    return $latest_snapshot;
}

sub _detect_latest_version {
    my ( $self, $base_url ) = @_;

    $logger->tracef( 'loading metadata from %s', $base_url );
    my $metadata = Maven::Xml::Metadata->new(
        agent => $self->{agent},
        url   => "$base_url/$self->{metadata_filename}"
    );
    return if ( !$metadata );
    return $metadata->get_versioning()->get_latest();
}

sub _has_version {
    my ( $self, $url ) = @_;
    my $has_version = $self->{agent}->head($url)->is_success();
    $logger->debugf( 'version %s at %s', ( $has_version ? 'found' : 'not found' ), $url );
    return $has_version;
}

sub _init {
    my ( $self, $url, %args ) = @_;

    $self->Maven::Repository::_init($url);
    $self->{agent}             = $args{agent};
    $self->{metadata_filename} = $args{metadata_filename}
        || 'maven-metadata.xml';

    return $self;
}

1;

__END__

=pod

=head1 NAME

Maven::RemoteRepository - An repository from which to resolve artifacts

=head1 VERSION

version 1.14

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

=back

=cut
