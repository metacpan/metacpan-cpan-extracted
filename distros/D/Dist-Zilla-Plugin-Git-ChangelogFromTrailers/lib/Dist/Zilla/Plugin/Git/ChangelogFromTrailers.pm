package Dist::Zilla::Plugin::Git::ChangelogFromTrailers 0.002;

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
use List::Util                  qw{any first max uniq};
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

# The name of the last release tag: of the tags that are reachable from HEAD
# and match version_regexp, the one with the highest version.
# @returns Str|Undef  the name of the tag, or undef if no tag matches
# @throws  dies with a Git::Wrapper::Exception when git tag fails
# @example my $tag = $plugin->last_release_tag;
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

# The values of the trailers in the commits since the last release tag, in the
# order that L</Trailers> describes.  Nothing when the repository has no commit.
# @returns Str  the values, as a list
# @throws  dies with a Git::Wrapper::Exception when git tag or git log fails
# @example my @items = $plugin->items;
sub items {
    my ($self) = @_;
    my $git = $self->_git;

    # A repository with no commits has no HEAD to read a log from.
    return unless eval { $git->rev_parse( { verify => 1, quiet => 1 }, 'HEAD' ); 1 };

    my $tag = $self->last_release_tag;
    my $key = $self->trailer;

    # Git::Wrapper refuses --format in log, so RUN gives the raw lines.  Each
    # commit starts with a record separator, and a unit separator divides the
    # trailers that git reads from the whole message.
    my $log = join "\n", $git->RUN(
        log => { reverse => 1, format => "%x1e%(trailers:key=$key,valueonly,unfold)%x1f%B" },
        defined $tag ? "$tag..HEAD" : 'HEAD',
    );
    my @values;
    foreach my $commit ( grep { $_ ne q{} } split /\x1e/, $log ) {
        my ( $trailers, $message ) = split /\x1f/, $commit, 2;
        push @values, $self->trailers_in( $message // q{} ), split /\n/, $trailers;
    }
    return uniq grep { $_ ne q{} } map { s/^\s+//r =~ s/\s+\z//r } @values;
}

# The values of the trailers of L</trailer> in each paragraph of the commit
# message C<$message> that is a block of trailers, in their order.  A paragraph
# is such a block when its first line is a trailer, and each line after it is a
# trailer or continues the one above it with leading whitespace.  A continued
# trailer is joined into one line.  git reads trailers only from the last
# paragraph, so this finds those that a squash merge left above it.
# @param   message  Str  the whole commit message
# @returns Str  the values, as a list
# @example my @values = $plugin->trailers_in("Subject\n\nChangelog: A change\n\nCo-authored-by: A. Tester <tester\@test.test>");
sub trailers_in {
    my ( $self, $message ) = @_;
    my $key = lc $self->trailer;
    my @values;
    foreach my $paragraph ( split /\n[ \t]*\n/, $message ) {
        my @lines = grep { $_ ne q{} } split /\n/, $paragraph;
        next if !@lines || $lines[0] !~ m/\A[[:alnum:]][[:alnum:]-]*\s*:/;
        next if any { !m/\A(?:[[:alnum:]][[:alnum:]-]*\s*:|\s+\S)/ } @lines;
        my @trailers;
        foreach my $line (@lines) {
            if ( $line =~ m/\A\s/ ) {
                $trailers[-1] .= q{ } . ( $line =~ s/\A\s+//r );
                next;
            }
            push @trailers, $line;
        }
        foreach my $trailer (@trailers) {
            my ( $name, $value ) = $trailer =~ m/\A([[:alnum:]][[:alnum:]-]*)\s*:\s*(.*)\z/;
            push @values, $value if lc $name eq $key;
        }
    }
    return @values;
}

# Add an empty F<Changes> to the build if the repository has none, as
# L<Dist::Zilla::Role::FileGatherer> asks.
# @returns nothing
# @example $plugin->gather_files;
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

sub _changes_file {
    my ($self) = @_;
    my $name = $self->filename;
    foreach my $file ( @{ $self->zilla->files } ) {
        return $file if $file->name eq $name;
    }
    return;
}

sub _build_entry {
    my ($self) = @_;
    my @items = $self->items;
    return unless @items;
    return join q{}, $self->section_header, "\n", map { "    - $_\n" } @items;
}

# Add the entry to F<Changes> in the build, as L<Dist::Zilla::Role::FileMunger>
# asks.  If no commit has a trailer, leave it as it is.
# @returns nothing
# @throws  by log_fatal when the build has no F<Changes>
# @example $plugin->munge_files;
sub munge_files {
    my ($self) = @_;
    my $file = $self->_changes_file;
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

# Check that the release can write its entry, as
# L<Dist::Zilla::Role::BeforeRelease> asks.
# @returns nothing
# @throws  by log_fatal when no commit since the last release has a trailer, or
#   when this plugin is below C<[Git::Commit]> in F<dist.ini>
# @example $plugin->before_release;
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

    my $file    = $self->_changes_file;
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

version 0.002

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
commit message, as L<git-interpret-trailers(1)> describes, or in any other
paragraph that holds only trailers.  The plugin writes
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

git reads trailers only from the last paragraph, but a squash merge on GitHub
leaves them in an earlier one.  It moves each C<Co-authored-by> trailer of the
pull request into a paragraph of its own at the end, and it joins the messages
of the commits of the pull request into one body.  So the plugin also reads
each paragraph whose first line is a trailer, and whose every line is a trailer
or continues the one above it with leading whitespace.  A paragraph of prose
counts for nothing, although one of its lines starts with the key.

The items are in the order of their commits, the oldest first, and in the
order of the message within a commit.  A value that
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

=head2 after_release

Write F<Changes> of the build to the repository, as
L<Dist::Zilla::Role::AfterRelease> asks.  If the plugin made it, run
C<git add --intent-to-add> on it, so that C<[Git::Commit]> commits it.

Returns nothing.

Dies when F<Changes> cannot be written, and with a Git::Wrapper::Exception when
git add fails.

    $plugin->after_release;

=head2 before_release

Check that the release can write its entry, as L<Dist::Zilla::Role::BeforeRelease> asks.

Returns nothing.

Dies by log_fatal when no commit since the last release has a trailer, or when this plugin is below C<[Git::Commit]> in F<dist.ini>.

    $plugin->before_release;

=head2 gather_files

Add an empty F<Changes> to the build if the repository has none, as L<Dist::Zilla::Role::FileGatherer> asks.

Returns nothing.

    $plugin->gather_files;

=head2 items

The values of the trailers in the commits since the last release tag, in the order that L</Trailers> describes.  Nothing when the repository has no commit.

Returns Str, the values, as a list.

Dies with a Git::Wrapper::Exception when git tag or git log fails.

    my @items = $plugin->items;

=head2 last_release_tag

The name of the last release tag: of the tags that are reachable from HEAD and match version_regexp, the one with the highest version.

Returns Str or Undef, the name of the tag, or undef if no tag matches.

Dies with a Git::Wrapper::Exception when git tag fails.

    my $tag = $plugin->last_release_tag;

=head2 munge_files

Add the entry to F<Changes> in the build, as L<Dist::Zilla::Role::FileMunger> asks.  If no commit has a trailer, leave it as it is.

Returns nothing.

Dies by log_fatal when the build has no F<Changes>.

    $plugin->munge_files;

=head2 trailers_in(message)

The values of the trailers of L</trailer> in each paragraph of the commit message C<$message> that is a block of trailers, in their order.  A paragraph is such a block when its first line is a trailer, and each line after it is a trailer or continues the one above it with leading whitespace.  A continued trailer is joined into one line.  git reads trailers only from the last paragraph, so this finds those that a squash merge left above it.

=over 4

=item message - Str - the whole commit message

=back

Returns Str, the values, as a list.

    my @values = $plugin->trailers_in("Subject\n\nChangelog: A change\n\nCo-authored-by: A. Tester <tester\@test.test>");

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

=head1 CONTRIBUTORS

=for stopwords troglodyne-bot troglodyne-robot

=over 4

=item *

troglodyne-bot <troglodyne-bot@users.noreply.github.com>

=item *

troglodyne-robot <trogbot@troglodyne.net>

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
