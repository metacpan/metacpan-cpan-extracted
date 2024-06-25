package Linux::Info::DistributionFinder;

use warnings;
use strict;
use Hash::Util qw(lock_hash);
use Carp       qw(confess);
use Class::XSAccessor exists_predicates => {
    has_custom_dir  => 'custom_source_dir',
    has_os_release  => 'os_release',
    has_custom_file => 'custom_file'
};
use File::Spec;
use constant DEFAULT_CONFIG_DIR => '/etc';

use Linux::Info::Distribution::OSRelease;
use Linux::Info::Distribution::BasicInfo;

our $VERSION = '2.18'; # VERSION

# ABSTRACT: class to search for candidate files


my %release_files = (
    'gentoo-release'        => 'gentoo',
    'fedora-release'        => 'fedora',
    'centos-release'        => 'centos',
    'enterprise-release'    => 'oracle enterprise linux',
    'turbolinux-release'    => 'turbolinux',
    'mandrake-release'      => 'mandrake',
    'mandrakelinux-release' => 'mandrakelinux',
    'debian_version'        => 'debian',
    'debian_release'        => 'debian',
    'SuSE-release'          => 'suse',
    'knoppix-version'       => 'knoppix',
    'yellowdog-release'     => 'yellowdog',
    'slackware-version'     => 'slackware',
    'slackware-release'     => 'slackware',
    'redflag-release'       => 'redflag',
    'redhat-release'        => 'redhat',
    'redhat_version'        => 'redhat',
    'conectiva-release'     => 'conectiva',
    'immunix-release'       => 'immunix',
    'tinysofa-release'      => 'tinysofa',
    'trustix-release'       => 'trustix',
    'adamantix_version'     => 'adamantix',
    'yoper-release'         => 'yoper',
    'arch-release'          => 'arch',
    'libranet_version'      => 'libranet',
    'va-release'            => 'va-linux',
    'pardus-release'        => 'pardus',
    'system-release'        => 'amazon',
    'CloudLinux-release'    => 'CloudLinux',
);
lock_hash(%release_files);


sub new {
    my $class      = shift;
    my $keep_cache = shift || 0;
    my $self       = {
        config_dir  => DEFAULT_CONFIG_DIR,
        distro_info => undef,
        keep_cache  => $keep_cache,
    };
    bless $self, $class;
    return $self;
}


sub set_config_dir {
    my ( $self, $dir ) = @_;
    $self->{config_dir}        = $dir;
    $self->{custom_source_dir} = 1;
}

sub _read_config_dir {
    my $self = shift;
    opendir( my $dh, $self->{config_dir} )
      or confess( 'Cannot read ' . $self->{config_dir} . ': ' . $! );
    my $version_regex = qr/version$/;
    my $release_regex = qr/release$/;
    my @candidates;

    while ( readdir $dh ) {
        next if ( ( $_ eq '.' ) or ( $_ eq '..' ) );
        push( @candidates, ($_) )
          if ( ( $_ =~ $version_regex )
            or ( $_ =~ $release_regex ) );
    }

    closedir($dh);
    return \@candidates;
}

sub _osrelease_basic {
    my ( $self, $file_path ) = @_;
    my $data_ref =
      Linux::Info::Distribution::OSRelease->parse_from_file($file_path);
    $self->{distro_info} =
      Linux::Info::Distribution::BasicInfo->new( $data_ref->{id}, $file_path, );

}

sub _default_os_release {
    my $self = shift;
    return (
        File::Spec->splitpath(
            Linux::Info::Distribution::OSRelease->DEFAULT_FILE
        )
    )[-1];
}

sub _search_release_file {
    my $self           = shift;
    my $candidates_ref = $self->_read_config_dir;
    my $os_release     = $self->_default_os_release;

    foreach my $thing ( @{$candidates_ref} ) {
        my $file_path = $self->{config_dir} . '/' . $thing;

        if ( -f $file_path ) {
            if ( $os_release eq $thing ) {
                $self->_osrelease_basic($file_path);
                $self->{os_release} = 1;
                last;
            }

            if ( exists $release_files{$thing} ) {
                $self->{distro_info} =
                  Linux::Info::Distribution::BasicInfo->new(
                    ( lc $release_files{$thing} ), $file_path, );
                $self->{custom_file} = 1;
                last;
            }
        }
    }
}


sub search_distro {
    my $self = shift;

    if ( $self->{keep_cache} ) {
        return $self->{distro_info} if ( defined( $self->{distro_info} ) );
    }
    else {
        $self->{distro_info} = undef;
        delete $self->{custom_file};
        delete $self->{os_release};
    }

    if ( $self->{config_dir} eq DEFAULT_CONFIG_DIR ) {

        if ( -r Linux::Info::Distribution::OSRelease::DEFAULT_FILE ) {
            $self->_osrelease_basic(
                Linux::Info::Distribution::OSRelease::DEFAULT_FILE);
        }
        else {
            $self->_search_release_file;
        }
    }
    else {
        $self->_search_release_file;
    }

    confess 'No custom or default source file, impossible to continue'
      unless ( defined $self->{distro_info} );

    return $self->{distro_info};
}


sub has_distro_info {
    my $self = shift;
    return ( defined( $self->{distro_info} ) ) ? 1 : 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::DistributionFinder - class to search for candidate files

=head1 VERSION

version 2.18

=head2 SYNOPSIS

    use Linux::Info::DistributionFinder;
    my $finder = Linux::Info::DistributionFinder->new;
    my $info_ref = $finder->search_distro;

=head3 DESCRIPTION

This class should be used to retrieve Linux distribution information on several
candidates files.

First it tries F</etc/os-release> (since it should contain more data), then
look into other known places.

=head1 METHODS

=head2 new

Creates and returns a new instance.

An optional parameter might be passed, which is how to handle caching.

If the parameter is "true" (1), result will be cached after a call to
C<search_distro> method. If "false" (0), each call of C<search_distro> will
invalidate the cache and files will be searched and parsed.

The default value is "false" (0) and is probably what you want unless you
want to rely on the cache or using C<has_distro_info> and C<has_custom_dir>
methods.

=head2 set_config_dir

Changes the default configuration directory used by a instance.

Most useful for unit testing with mocks.

=head2 search_distro

Searches for specific files to try to determine the distribution.

Returns a instance of L<Linux::Info::Distribution::BasicInfo>.

=head2 has_distro_info

Returns "true" (1) if the instance has already cached distribution information.

Otherwise, returns "false" (0).

=head2 has_custom_dir

Returns "true" (1) if the instance is using a source directory different from
F</etc>.

Otherwise, returns "false" (0).

=head2 has_custom_file

Returns "true" (1) if the instance is using a distribution customized file (
i.e. something diferent of F</etc/os-release>).

Otherwise, returns "false" (0).

=head2 has_os_release

Returns "true" (1) if the instance is using F</etc/os-release> or a
F<os-release> located in a customized source directory (see C<has_custom_dir>).

=head1 EXPORTS

Nothing.

You can use C<Linux::Info:DistributionFinder::DEFAULT_CONFIG_DIR> to fetch
the default directory used to search for distribution information.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
