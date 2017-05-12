#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Plugin/Author/VDB/Hg/Tag/Check.pm
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
#pod     [Author::VDB::Hg::Tag::Check]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin does C<BeforeRelease> role. It makes sure the version to release is not yet tagged in
#pod Mercurial repository (i. e. there is no tag the same as the current version). If version is already
#pod tagged, the plugin aborts release.
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Plugin::Author::VDB::Hg::Tag::Check;

use Moose;
use autodie ':all';
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Make sure tag doesn't exist yet
our $VERSION = 'v0.11.3'; # VERSION

with 'Dist::Zilla::Role::BeforeRelease';
with 'Dist::Zilla::Role::ErrorLogger';
with 'Dist::Zilla::Role::Author::VDB::HgRunner';

#pod =for Pod::Coverage before_release
#pod
#pod =cut

sub before_release {
    my ( $self ) = @_;
    my $version = $self->zilla->version;
    my $tags = $self->run_hg( 'tags' );
    if ( grep( { $_ =~ m{ ^ \Q$version\E \s }x } @$tags ) ) {
        $self->abort( [ "Tag '%s' already exists", $version ] );
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

Dist::Zilla::Plugin::Author::VDB::Hg::Tag::Check - Make sure tag doesn't exist yet

=head1 VERSION

Version v0.11.3, released on 2016-12-21 19:58 UTC.

=for test_synopsis BEGIN { die "SKIP: not a Perl code"; }

=head1 SYNOPSIS

F<dist.in> file:

    [Author::VDB::Hg::Tag::Check]

=head1 DESCRIPTION

This plugin does C<BeforeRelease> role. It makes sure the version to release is not yet tagged in
Mercurial repository (i. e. there is no tag the same as the current version). If version is already
tagged, the plugin aborts release.

=for Pod::Coverage before_release

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
