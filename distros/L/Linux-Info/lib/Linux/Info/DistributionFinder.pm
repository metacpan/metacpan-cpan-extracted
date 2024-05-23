package Linux::Info::DistributionFinder;

use warnings;
use strict;
use Hash::Util qw(lock_hash);
use Carp       qw(confess);
use Class::XSAccessor setters => { set_config_dir => 'config_dir', };
use File::Spec;
use constant DEFAULT_CONFIG_DIR => '/etc';

use Linux::Info::Distribution::OSRelease;

our $VERSION = '2.11'; # VERSION

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
        config_dir   => DEFAULT_CONFIG_DIR,
        release_info => undef,
        keep_cache   => $keep_cache
    };
    bless $self, $class;
    return $self;
}


sub _config_dir {
    my $self = shift;
    opendir( my $dh, $self->{config_dir} )
      or confess( 'Cannot read ' . $self->{config_dir} . ': ' . $! );
    my $version_regex = qr/version$/;
    my $release_regex = qr/release$/;
    my @candidates;
    my $unwanted = (
        File::Spec->splitpath(
            Linux::Info::Distribution::OSRelease->DEFAULT_FILE
        )
    )[-1];

    while ( readdir $dh ) {
        next if ( ( $_ eq '.' ) or ( $_ eq '..' ) );
        push( @candidates, ($_) )
          if (
            ( $_ =~ $version_regex )
            or (    ( $_ ne $unwanted )
                and ( $_ =~ $release_regex ) )
          );
    }

    closedir($dh);
    return \@candidates;
}

# TODO: should return a well known data structure
sub _search_release_file {
    my $self           = shift;
    my $candidates_ref = $self->_config_dir;

    foreach my $thing ( @{$candidates_ref} ) {
        my $file_path = $self->{config_dir} . '/' . $thing;

        if ( ( exists $release_files{$thing} ) and ( -f $file_path ) ) {
            $self->{release_info} = {
                id            => ( lc $release_files{$thing} ),
                file_to_parse => ($file_path),
            };
            last;
        }
    }
}


sub search_distro {
    my $self       = shift;
    my $os_release = shift || Linux::Info::Distribution::OSRelease->new;

    if ( $self->{keep_cache} ) {
        return $self->{release_info} if ( defined( $self->{release_info} ) );
    }
    else {
        $self->{release_info} = undef;
    }

    if ( $self->{config_dir} eq DEFAULT_CONFIG_DIR ) {
        if ( -r $os_release->get_source ) {
            $self->{release_info} = $os_release->parse;
        }
        else {
            $self->_search_release_file;
        }
    }
    else {
        $self->_search_release_file;
    }

    return $self->{release_info};
}


sub has_distro_info {
    my $self = shift;
    return ( defined( $self->{release_info} ) ) ? 1 : 0;
}


sub has_custom {
    my $self = shift;

    if (    ( defined( $self->{release_info} ) )
        and ( exists $self->{release_info}->{file_to_parse} )
        and ( defined $self->{release_info}->{file_to_parse} ) )
    {
        return 1;
    }

    return 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::DistributionFinder - class to search for candidate files

=head1 VERSION

version 2.11

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
want to rely on the cache or using C<has_distro_info> and C<has_custom>
methods.

=head2 set_config_dir

Changes the default configuration directory used by a instance.

Most useful for unit testing with mocks.

=head2 search_distro

Search and return the Linux distribution information.

The returned value might be one generated by
L<Linux::Info::Distribution::OSRelease> C<parse> method, if there is a
F</etc/os-release> file available.

If not, a custom distribution file will be attempted and the returned value
will be a hash reference with the following structure:

    {
        id => 'someid',
        file_to_parse => '/etc/foobar_version',
    }

Since the file needs to be parsed to retrieve all available information,
this file will need to be parsed by a L<Linux::Info::Distribution::Custom>
subclasses.

=head2 has_distro_info

Returns "true" (1) if the instance has already cached distribution information.

Otherwise, returns "false" (0).

=head2 has_custom

Returns "true" (1) if the instance has cached distribution information
retrieved from a custom file.

Otherwise, returns "false" (0).

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
