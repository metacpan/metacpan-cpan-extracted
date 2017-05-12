use strict;
use warnings;

package Maven::LocalRepository;
$Maven::LocalRepository::VERSION = '1.14';
# ABSTRACT: An local repository from which to resolve artifacts
# PODNAME: Maven::LocalRepository

use parent qw(Maven::Repository);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(url));

use Log::Any;
use Maven::Xml::Metadata;
use Maven::Xml::Settings;
use Sort::Versions;
use URI::file;

my $logger = Log::Any->get_logger();

sub _by_maven_version {
    if ( $a =~ /^$b-SNAPSHOT$/ ) {
        return -1;
    }
    elsif ( $b =~ /^$a-SNAPSHOT$/ ) {
        return 1;
    }
    else {
        return versioncmp( $a, $b );
    }
}

sub _detect_latest_snapshotVersion {
    my ( $self, $base_url, $extension, $classifier ) = @_;

    $logger->tracef( 'loading snapshot metadata from %s', $base_url );
    my @versions = sort _by_maven_version $self->_list_versions( $base_url, 1 );

    return pop(@versions);
}

sub _detect_latest_version {
    my ( $self, $base_url ) = @_;

    $logger->tracef( 'loading metadata from %s', $base_url );
    my @versions = sort _by_maven_version $self->_list_versions($base_url);

    return pop(@versions);
}

sub _has_version {
    my ( $self, $url ) = @_;

    my $has_version = ( -f $self->_path_from_url($url) );
    $logger->debugf( 'version %s at %s', ( $has_version ? 'found' : 'not found' ), $url );

    return $has_version;
}

sub _init {
    my ( $self, $local_repository_path, @args ) = @_;

    $self->Maven::Repository::_init(
        URI::file->new(
            $^O =~ /^cygwin$/i

                #? Cygwin::win_to_posix_path($local_repository_path)
            ? `cygpath -u '$local_repository_path'`
            : $local_repository_path
        )->as_string()
    );

    return $self;
}

sub _list_versions {
    my ( $self, $base_url, $snapshot ) = @_;
    my $base_path = $self->_path_from_url($base_url);

    my ( $artifact, $version );
    if ($snapshot) {
        my @parts = File::Spec->splitdir($base_path);
        $version  = pop(@parts);
        $artifact = pop(@parts);
        $version =~ s/-SNAPSHOT$//;
    }

    my @versions = ();
    opendir( my $dir_handle, $base_path ) || return ();
    while ( my $entry = readdir($dir_handle) ) {
        next if ( $entry =~ /^\.+$/ );
        my $path = File::Spec->catdir( $base_path, $entry );
        if ($snapshot) {
            if ( $path =~ /.*\/$artifact-$version-(.*)/ ) {
                my $rest = $1;
                if ( $rest =~ /^SNAPSHOT(?:-(.*?))?\.([^\.]*)$/ ) {
                    my $snapshotVersion = Maven::Xml::Metadata::SnapshotVersion->new();
                    $snapshotVersion->{value}      = "$version-SNAPSHOT";
                    $snapshotVersion->{extension}  = $2;
                    $snapshotVersion->{classifier} = $1;
                    push( @versions, $snapshotVersion );
                }
            }
        }
        else {
            if ( -d $path ) {
                push( @versions, $entry );
            }
        }
    }
    closedir($dir_handle);
    return @versions;
}

sub _path_from_url {
    my ( $self, $url ) = @_;
    my $path = URI->new($url)->path();

    # if windows, we have to strip the leading /
    # from /C:/...
    $path =~ s/^\/([A-Za-z]:)/$1/;

    return $path;
}

1;

__END__

=pod

=head1 NAME

Maven::LocalRepository - An local repository from which to resolve artifacts

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
