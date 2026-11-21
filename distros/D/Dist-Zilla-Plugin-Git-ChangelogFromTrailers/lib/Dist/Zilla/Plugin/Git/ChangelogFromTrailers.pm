package Dist::Zilla::Plugin::Git::ChangelogFromTrailers 0.001;

# ABSTRACT: Build the Changes entry for a release from the Changelog trailers of its commits

use 5.020;
use strict;
use warnings;
use re '/aasx';

use Moose;    ## no critic (ProhibitUnusedImports) imports has, extends and with, which the policy does not see as calls
extends 'Dist::Zilla::Plugin::NextRelease';
with 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::BeforeRelease';

use Dist::Zilla::File::InMemory ();
use Git::Wrapper                ();
use List::Util                  qw{first max uniq};
use version                     ();
use namespace::autoclean;    ## no critic (ProhibitUnusedImports) loaded for its effect, which removes the imports from the class


has trailer => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Changelog',
);


has version_regexp => (
    is      => 'ro',
    isa     => 'Str',
    default => '^v?(\d+(?:\.\d+)*(?:_\d+)?)$',
);

has _entry => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    lazy     => 1,
    init_arg => undef,
    builder  => '_build_entry',
);

has _created => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
    init_arg => undef,
);

has _changes => (
    is       => 'rw',
    isa      => 'Str',
    init_arg => undef,
);

has _git => (
    is       => 'ro',
    isa      => 'Git::Wrapper',
    lazy     => 1,
    init_arg => undef,
    default  => sub { Git::Wrapper->new( $_[0]->zilla->root->stringify ) },
);


sub last_release_tag {
    my ($self) = @_;
    my $regexp = $self->version_regexp;

    my %version_of;
    foreach my $tag ( $self->_git->tag( { merged => 'HEAD' } ) ) {
        my ($v) = $tag =~ m/$regexp/;
        next unless defined $v;
        my $parsed = eval { version->parse($v) };
        $version_of{$tag} = $parsed if defined $parsed;
    }
    return unless %version_of;

    my $highest = max values %version_of;
    return first { $version_of{$_} == $highest } sort keys %version_of;
}


sub items {
    my ($self) = @_;
    my $git = $self->_git;

    # A repository with no commits has no HEAD to read a log from.
    return unless eval { $git->rev_parse( { verify => 1, quiet => 1 }, 'HEAD' ); 1 };

    my $tag = $self->last_release_tag;
    my $key = $self->trailer;

    # Git::Wrapper refuses --format in log, so RUN gives the raw lines: one value
    # to a line, and an empty line for a commit with no trailer.
    my @values = $git->RUN(
        log => { reverse => 1, format => "%(trailers:key=$key,valueonly,unfold)" },
        defined $tag ? "$tag..HEAD" : 'HEAD',
    );
    return uniq grep { $_ ne q{} } map { s/^\s+//r =~ s/\s+\z//r } @values;
}


sub gather_files {
    my ($self) = @_;
    return if -e $self->zilla->root->child( $self->filename );

    $self->add_file(
        Dist::Zilla::File::InMemory->new(
            name    => $self->filename,
            content => sprintf( "Revision history for %s\n", $self->zilla->name ),
        )
    );
    $self->_created(1);
    return;
}

sub _build_entry {
    my ($self) = @_;
    my @items = $self->items;
    return unless @items;
    return join q{}, $self->section_header, "\n", map { "    - $_\n" } @items;
}


sub munge_files {
    my ($self) = @_;
    my $file = first { $_->name eq $self->filename } @{ $self->zilla->files };
    $self->log_fatal( [ 'failed to find %s in the distribution', $self->filename ] ) unless $file;

    my $entry = $self->_entry;
    if ( !defined $entry ) {
        $self->log( [ 'no %s trailers since the last release, so %s is unchanged', $self->trailer, $self->filename ] );
        return;
    }

    my $content = $file->content;
    $content =~ s/\n*\z/\n\n$entry/ unless $content =~ s/^(?=v?\d)/$entry\n/m;

    $self->_changes($content);
    $file->content($content);
    return;
}


sub before_release {
    my ($self) = @_;
    $self->log_fatal( [ 'no %s trailers in the commits since the last release', $self->trailer ] )
      unless defined $self->_entry;

    my @plugins = @{ $self->zilla->plugins };
    my $me      = first { $plugins[$_] == $self } 0 .. $#plugins;
    my $commit  = first { $plugins[$_]->isa('Dist::Zilla::Plugin::Git::Commit') } 0 .. $#plugins;
    $self->log_fatal('[Git::ChangelogFromTrailers] must be above [Git::Commit] in dist.ini, or the release commit does not contain Changes')
      if defined $commit && $commit < $me;
    return;
}


sub after_release {
    my ($self) = @_;
    return unless defined $self->_changes;

    my $file    = first { $_->name eq $self->filename } @{ $self->zilla->files };
    my $iolayer = sprintf ':raw:encoding(%s)', $file->encoding;
    $self->log_debug( [ 'updating contents of %s on disk', $self->update_filename ] );
    my $changes = $self->zilla->root->child( $self->update_filename );
    $changes->spew( { binmode => $iolayer }, $self->_changes );

    # Git::Commit commits only tracked files that changed, and an intent-to-add
    # entry makes the new file one of those.
    $self->_git->add( { intent_to_add => 1 }, $self->update_filename ) if $self->_created;
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::ChangelogFromTrailers - Build the Changes entry for a release from the Changelog trailers of its commits

=head1 VERSION

version 0.001

=head1 SYNOPSIS

In F<dist.ini>, above C<[Git::Commit]>:

    [Git::ChangelogFromTrailers]
    format = %v %{yyyy-MM-dd}d %P

    [Git::Commit]
    allow_dirty = Changes

Each commit that is worth a line in F<Changes> says so in a trailer:

    git commit -m 'Handle empty input' --trailer 'Changelog: Fix the frobnicator when the input is empty'

=head1 DESCRIPTION

Two branches that each add a line to the top of F<Changes> conflict when the
second one merges.  Two branches that each say what they change in their commit
messages do not.

This plugin reads the C<Changelog> trailers of the commits since the last
release tag.  A trailer is a C<Key: value> line in the last paragraph of a
commit message, as L<git-interpret-trailers(1)> describes.  The plugin writes
one entry for the trailers at the top of F<Changes> in the build.  When the
release succeeds, it writes the same entry to F<Changes> in the repository, so
that C<[Git::Commit]> commits it with the release.

The entries that are in F<Changes> already stay as they are.  The plugin adds
the new entry above the first line that starts with a version, or at the end
of a F<Changes> that has no entry yet.  If the repository has no F<Changes>,
the plugin makes one, with the line C<Revision history for> and the name of the
distribution.

The last release tag is the highest version among the tags that are reachable
from C<HEAD> and match L</version_regexp>.  If no tag matches, every commit
counts.

The plugin is a subclass of L<Dist::Zilla::Plugin::NextRelease>.  It takes the
options C<format>, C<time_zone>, C<filename>, C<update_filename> and
C<user_stash> from that plugin, with the same meaning.  Use it instead of
C<[NextRelease]>, not with it.

=head2 Trailers

The value of each trailer is the text of one item, so a commit can have more
than one.  The key does not depend on case.  A trailer that continues on the
next line is joined into one line.

The items are in the order of their commits, the oldest first.  A value that
is the same as an earlier one is left out, so a merge commit can repeat the
trailers of its branch.  A commit with no trailer adds nothing.

GitLab also reads a C<Changelog> trailer, but there the value is a category,
such as C<added>, and the subject of the commit is the text.  This plugin uses
the value as the text.

=head2 Order in dist.ini

The C<after_release> of this plugin must run before that of C<[Git::Commit]>,
or the release commit does not contain the new F<Changes>.  Dist::Zilla runs
them in the order of F<dist.ini>.  So put this plugin above C<[Git::Commit]>.
If it is below, the release stops before it starts.

=head2 The version

L<Dist::Zilla::Plugin::Git::NextVersion> gives each release the version of the
last release tag plus one.  Remove C<version> from F<dist.ini> and add:

    [Git::NextVersion]
    first_version  = 0.001
    version_regexp = ^v?(\d+\.\d+)$

Use the same C<version_regexp> for both plugins.

=head1 ATTRIBUTES

=head2 trailer

The key of the trailers to read.  The default is C<Changelog>.

=head2 version_regexp

The pattern that a tag must match to be a release tag.  The first capture group
is the version.  The default matches C<1.002> and C<v1.002>.

=head1 METHODS

=head2 last_release_tag

Return the name of the last release tag, or undef if there is none.

=head2 items

Return the values of the trailers in the commits since the last release tag, in
the order that L</Trailers> describes.

=head2 gather_files

Add an empty F<Changes> to the build if the repository has none.

=head2 munge_files

Add the entry to F<Changes> in the build.  If no commit has a trailer, leave
it as it is.

=head2 before_release

Stop the release if no commit since the last release has a trailer, or if this
plugin is below C<[Git::Commit]> in F<dist.ini>.

=head2 after_release

Write F<Changes> of the build to the repository.  If the plugin made it, run
C<git add --intent-to-add> on it, so that C<[Git::Commit]> commits it.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Plugin::NextRelease|Dist::Zilla::Plugin::NextRelease>

=item *

L<Dist::Zilla::Plugin::Git::NextVersion|Dist::Zilla::Plugin::Git::NextVersion>

=item *

L<Dist::Zilla::Plugin::Git::Commit|Dist::Zilla::Plugin::Git::Commit>

=item *

L<CPAN::Changes::Spec|CPAN::Changes::Spec>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Dist-Zilla-Plugin-Git-ChangelogFromTrailers/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
