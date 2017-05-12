#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Plugin/Author/VDB/Hg/Push.pm
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
#pod     [Author::VDB::Hg::Push]
#pod         repository = default    ; This is default.
#pod         repository = remote
#pod         ...
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin does C<AfterRelease> role. It pushes changes from the current repository to the
#pod (remote) repositories. Multiple repositories can be specified.
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Plugin::Author::VDB::Hg::Push;

use Moose;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Push changes to (remote) repositories
our $VERSION = 'v0.11.3'; # VERSION

with 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::ErrorLogger';
with 'Dist::Zilla::Role::Author::VDB::HgRunner';

#pod =option repository
#pod
#pod =option repositories
#pod
#pod (Remote) repository name to push changes to. May be repeated multiple times to push changes to
#pod several repositories.
#pod
#pod =cut

has repositories => (
    isa         => 'ArrayRef[Str]',
    is          => 'ro',
    default     => sub { [ 'default' ] },
);

# --------------------------------------------------------------------------------------------------

#pod =for Pod::Coverage mvp_aliases mvp_multivalue_args
#pod
#pod =cut

sub mvp_aliases {
    return {
        'repository' => 'repositories',
    };
};

sub mvp_multivalue_args {
    return qw{ repositories };
};

# --------------------------------------------------------------------------------------------------

#pod =for Pod::Coverage after_release
#pod
#pod =cut

sub after_release {
    my ( $self ) = @_;
    for my $repo ( @{ $self->repositories } ) {
        $self->run_hg( 'push', $repo );
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

Dist::Zilla::Plugin::Author::VDB::Hg::Push - Push changes to (remote) repositories

=head1 VERSION

Version v0.11.3, released on 2016-12-21 19:58 UTC.

=for test_synopsis BEGIN { die "SKIP: not a Perl code"; }

=head1 SYNOPSIS

F<dist.in> file:

    [Author::VDB::Hg::Push]
        repository = default    ; This is default.
        repository = remote
        ...

=head1 DESCRIPTION

This plugin does C<AfterRelease> role. It pushes changes from the current repository to the
(remote) repositories. Multiple repositories can be specified.

=head1 OPTIONS

=head2 repository

=head2 repositories

(Remote) repository name to push changes to. May be repeated multiple times to push changes to
several repositories.

=for Pod::Coverage mvp_aliases mvp_multivalue_args

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
