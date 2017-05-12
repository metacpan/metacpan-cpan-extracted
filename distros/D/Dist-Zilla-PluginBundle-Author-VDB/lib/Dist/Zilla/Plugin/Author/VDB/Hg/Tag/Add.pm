#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Plugin/Author/VDB/Hg/Tag/Add.pm
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
#pod     [Author::VDB::Hg::Tag::Add]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin does C<AfterRelease> role. It tags current version in Mercurial repository (but does
#pod not commit the change!).
#pod
#pod =cut

# --------------------------------------------------------------------------------------------------

package Dist::Zilla::Plugin::Author::VDB::Hg::Tag::Add;

use Moose;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Add tag (but don't commit it) [after release]
our $VERSION = 'v0.11.3'; # VERSION

with 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::ErrorLogger';
with 'Dist::Zilla::Role::Author::VDB::HgRunner';

use Path::Tiny;

# --------------------------------------------------------------------------------------------------

#pod =option local
#pod
#pod If 1, local tag will be added.
#pod
#pod =cut

has local => (
    isa         => 'Bool',
    is          => 'ro',
    default     => 0,
);

# --------------------------------------------------------------------------------------------------

#pod =for Pod::Coverage after_release
#pod
#pod =cut

sub after_release {
    my ( $self ) = @_;
    my $root = path( $self->zilla->root );
    my $identify = $self->run_hg( 'identify', '--id', '--debug' );
    if ( @$identify != 1 or $identify->[ 0 ] !~ m{ ^ ([0-9a-f]{40}) (\+?) $ }x ) {
        $self->log_error( "Can't parse 'hg identify' output:" );
        $self->log_error( "    $_" ) for @$identify;
        $self->abort();
    };
    my ( $id, $dirty ) = ( $1, $2 );    ## no critic ( ProhibitCaptureWithoutTest )
    if ( $dirty ) {
        $self->abort( "The working directory has uncommitted changes" );
    };
    if ( $id eq '0' x 40 ) {
        $self->abort( "Oops, current changeset has null id" );
            # ^ TODO: More user-friendly error message
    };
    my $tags = $root->child( $self->local ? '.hg/localtags' : '.hgtags' );
    $self->log_debug( [
        $self->local ? "adding local tag %s" : "adding tag %s",
        $self->zilla->version
    ] );
    $tags->append( sprintf( "%s %s\n", $id, $self->zilla->version ) );
    if ( not $self->local ) {
        #   Make sure `.hgtags` file is added to repository.
        my $status = $self->run_hg( 'status', '.hgtags' );
        if ( @$status != 1 or $status->[ 0 ] !~ m{ ^ ([?M]) \s \.hgtags $ }x ) {
            $self->log_error( "Unexpected 'hg status' output:" );
            $self->log_error( [ "    $_" ] ) for @$status;
            $self->abort();
        };
        my $mark = $1;                  ## no critic ( ProhibitCaptureWithoutTest )
        if ( $mark eq '?' ) {
            $self->run_hg( 'add', '.hgtags' );
        };
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

Dist::Zilla::Plugin::Author::VDB::Hg::Tag::Add - Add tag (but don't commit it) [after release]

=head1 VERSION

Version v0.11.3, released on 2016-12-21 19:58 UTC.

=for test_synopsis BEGIN { die "SKIP: not a Perl code"; }

=head1 SYNOPSIS

F<dist.in> file:

    [Author::VDB::Hg::Tag::Add]

=head1 DESCRIPTION

This plugin does C<AfterRelease> role. It tags current version in Mercurial repository (but does
not commit the change!).

=head1 OPTIONS

=head2 local

If 1, local tag will be added.

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
