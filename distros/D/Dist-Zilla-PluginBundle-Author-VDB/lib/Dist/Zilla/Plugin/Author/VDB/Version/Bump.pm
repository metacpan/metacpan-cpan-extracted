#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Plugin/Author/VDB/Version/Bump.pm
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Dist-Zilla-PluginBundle-Author-VDB.
#
#   perl-Dist-Zilla-PluginBundle-Author-VDB is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-PluginBundle-Author-VDB is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-PluginBundle-Author-VDB. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for test_synopsis BEGIN { die "SKIP: not a Perl code"; }
#pod
#pod =head1 SYNOPSIS
#pod
#pod F<dist.in> file:
#pod
#pod     ; version = v0.3.1      ; *Should **not** be used.*
#pod     ...
#pod     [Author::VDB::Version::Read]
#pod         file = VERSION
#pod     ...
#pod     [Author::VDB::Version::Bump]
#pod         file = VERSION
#pod
#pod F<VERSION> file:
#pod
#pod     v0.3.1
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin does C<AfterRelease> role. It bumps version in the specified file by incrementing alpha
#pod component. For example, version C<v0.7.1> is bumped to C<v0.7.1_01>, then to C<v0.7.1_02>, etc.
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Plugin::Author::VDB::Version::Bump;

use Moose;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Bump version after release
our $VERSION = 'v0.11.3'; # VERSION

with 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::ErrorLogger' => { -version => 'v0.9.0' };
    # ^ We need `ErrorLogger` to throw an exception, not plain string.

use Path::Tiny;
use Perl::Version;
use Try::Tiny;

# --------------------------------------------------------------------------------------------------

#pod =option file
#pod
#pod Name of file to bump version in. Default value is C<VERSION>. Specifying an empty file disables
#pod the plugin.
#pod
#pod =cut

has 'file' => (
    isa         => 'Str',
    is          => 'ro',
    lazy        => 1,
    default     => 'VERSION',
);

has _file => (
    isa         => 'Path::Tiny',
    is          => 'ro',
    init_arg    => undef,
    lazy        => 1,
    default     => sub {
        my ( $self ) = @_;
        my $path = path( $self->file );
        if ( $path->is_absolute ) {
            $self->abort( [ "Bad version file '%s': absolute path is not allowed", $self->file ] );
        };
        return $path->absolute( $self->zilla->root );
    },
);

# --------------------------------------------------------------------------------------------------

#pod =for Pod::Coverage after_release
#pod
#pod =cut

sub after_release {
    my ( $self ) = @_;
    if ( $self->file ) {
        my $version = Perl::Version->new( $self->zilla->version );
        $version->inc_alpha();
        try {
            $self->_file->append( { truncate => 1 }, "$version\n" );
                # `append` is not atomic but keeps file mode intact.
        } catch {
            my $ex = $_;
            my $class = blessed( $ex ) || '';
            if ( 0 ) {
            } elsif ( $class eq 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' ) {
                # All the messages are aready logged, just rethrow the exception.
                die $ex;                ## no critic ( RequireCarping )
            } elsif ( blessed( $ex ) eq 'Try::Tiny::Error' ) {
                chomp( my $em = "$ex" );
                $self->log_debug( $em );
                $self->abort( [ "Can't write version file '%s': %s", $self->file, $ex->{ err } ] );
            } else {
                $self->abort( $ex );
            };
        };
        $self->log_debug( [ 'next release version will be %s', "$version" ] );
    } else {
        $self->log_debug( 'no version file specified' );
    };
    return;
};

# --------------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

1;

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::VDB::Version::Bump - Bump version after release

=head1 VERSION

Version v0.11.3, released on 2016-12-21 19:58 UTC.

=for test_synopsis BEGIN { die "SKIP: not a Perl code"; }

=head1 SYNOPSIS

F<dist.in> file:

    ; version = v0.3.1      ; *Should **not** be used.*
    ...
    [Author::VDB::Version::Read]
        file = VERSION
    ...
    [Author::VDB::Version::Bump]
        file = VERSION

F<VERSION> file:

    v0.3.1

=head1 DESCRIPTION

This plugin does C<AfterRelease> role. It bumps version in the specified file by incrementing alpha
component. For example, version C<v0.7.1> is bumped to C<v0.7.1_01>, then to C<v0.7.1_02>, etc.

=head1 OPTIONS

=head2 file

Name of file to bump version in. Default value is C<VERSION>. Specifying an empty file disables
the plugin.

=for Pod::Coverage after_release

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
