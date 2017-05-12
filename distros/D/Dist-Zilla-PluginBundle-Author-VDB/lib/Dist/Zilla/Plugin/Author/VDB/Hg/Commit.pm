#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Plugin/Author/VDB/Hg/Commit.pm
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
#pod     [Author::VDB::Hg::Commit]
#pod         file = .hgtags
#pod         file = remote
#pod         ...
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin does C<AfterRelease> role. It commits specified files to the Mercurial repository.
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Plugin::Author::VDB::Hg::Commit;

use Moose;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Commit files to repository
our $VERSION = 'v0.11.3'; # VERSION

use Path::Tiny qw{ tempfile };

with 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::ErrorLogger';
with 'Dist::Zilla::Role::Author::VDB::HgRunner';

# --------------------------------------------------------------------------------------------------

#pod =option message
#pod
#pod Commit message.
#pod
#pod =cut

has message => (
    isa         => 'Str',
    is          => 'ro',
    default     => 'post-release',
);

# --------------------------------------------------------------------------------------------------

#pod =option file
#pod
#pod =option files
#pod
#pod File name to commit. May be repeated multiple times to push changes to commit several files.
#pod
#pod =cut

has files => (
    isa         => 'ArrayRef[Str]',
    is          => 'ro',
    default     => sub { [] },
);

# --------------------------------------------------------------------------------------------------

#pod =for Pod::Coverage mvp_aliases mvp_multivalue_args
#pod
#pod =cut

sub mvp_aliases {
    return {
        'file' => 'files',
    };
};

sub mvp_multivalue_args {
    return qw{ files };
};

# --------------------------------------------------------------------------------------------------

#pod =for Pod::Coverage BUILD
#pod
#pod =cut

sub BUILD {
    my ( $self ) = @_;
    if ( $self->message eq '' ) {
        $self->abort( 'message option must not be empty' );
    };
    return;
};

# --------------------------------------------------------------------------------------------------

#pod =for Pod::Coverage after_release
#pod
#pod =cut

sub after_release {
    my ( $self ) = @_;
    my @files = grep( { $_ ne '' } @{ $self->files } );
    if ( @files ) {
        $self->run_hg( 'commit', '-m', $self->message, @files );
    };
    return;
};

# --------------------------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

1;

# --------------------------------------------------------------------------------------------------

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

Dist::Zilla::Plugin::Author::VDB::Hg::Commit - Commit files to repository

=head1 VERSION

Version v0.11.3, released on 2016-12-21 19:58 UTC.

=for test_synopsis BEGIN { die "SKIP: not a Perl code"; }

=head1 SYNOPSIS

F<dist.in> file:

    [Author::VDB::Hg::Commit]
        file = .hgtags
        file = remote
        ...

=head1 DESCRIPTION

This plugin does C<AfterRelease> role. It commits specified files to the Mercurial repository.

=head1 OPTIONS

=head2 message

Commit message.

=head2 file

=head2 files

File name to commit. May be repeated multiple times to push changes to commit several files.

=for Pod::Coverage mvp_aliases mvp_multivalue_args

=for Pod::Coverage BUILD

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
