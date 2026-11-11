package Dist::Conformance::Snapshot 0.004;

# ABSTRACT: What a check can read of a repository: its paths, their blob SHAs and their contents

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base -base, -signatures;

use Digest::SHA();


sub paths ($self) { die( ref($self) . " does not implement paths\n" ) }


sub content ( $self, $ ) { die( ref($self) . " does not implement content\n" ) }


sub contains ( $self, $path ) { return exists $self->paths->{$path} }


sub sha ( $self, $path ) { return $self->paths->{$path} }


sub under ( $self, $directory ) {
    my $prefix = "$directory/";
    my @inside = sort map { substr $_, length $prefix } grep { index( $_, $prefix ) == 0 } keys %{ $self->paths };
    return @inside;
}


sub writable ($) { return 0 }


sub blob_sha ($bytes) {
    return Digest::SHA::sha1_hex( 'blob ' . length($bytes) . "\0" . $bytes );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Snapshot - What a check can read of a repository: its paths, their blob SHAs and their contents

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Snapshot::Directory;

    my $snapshot = Dist::Conformance::Snapshot::Directory->new( root => '/bogus/checkout' );
    say 'has a profile' if $snapshot->contains('.perlcriticrc');
    say $snapshot->sha('git-hooks/pre-commit') // 'no hook';
    my $text = $snapshot->content('CLAUDE.md');

=head1 DESCRIPTION

A check never touches a repository directly.  It reads a snapshot, which
answers two questions: which paths exist, each with its git blob SHA, and what
the content of one path is.  So the same check runs against a local checkout,
through L<Dist::Conformance::Snapshot::Directory>, and against a repository
that only an API can reach, through L<Dist::Conformance::Snapshot::Tree>.

This class is the interface.  A subclass implements L</paths> and L</content>;
everything else here is built on those two.  A snapshot that a check can also
change is I<writable>: L<Dist::Conformance::Snapshot::Directory> is the only one,
and it adds C<write> and C<install_hook>.

Paths are relative to the root of the repository, with C</> between the
components, as git writes them.  A snapshot lists files and symbolic links, not
directories.

=head1 METHODS

=head2 paths

Returns a hash reference from each path to its git blob SHA, in lowercase hex.
A subclass must implement it.

=head2 content

C<($path)>.  Returns the bytes of the file at C<$path>, or C<undef> if the
snapshot has no such path.  A subclass must implement it.

=head2 contains

C<($path)>.  Whether the snapshot has a file at C<$path>.

=head2 sha

C<($path)>.  The git blob SHA of C<$path>, or C<undef>.

=head2 under

C<($directory)>.  The paths inside C<$directory>, at any depth, relative to it
and sorted.

=head2 writable

Whether a check can change this snapshot.  False here.

=head1 FUNCTIONS

=head2 blob_sha

C<($bytes)>.  The SHA that git gives a blob with this content, the same as
C<git hash-object> prints.  So a check can compare a template with a file in a
snapshot that it never downloaded.

=head1 WRITING A SNAPSHOT

Subclass this module, and implement L</paths> and L</content>.  Both can be
lazy, and both can memoize, because a snapshot describes one moment of one
repository.  L</contains> and L</sha> call L</paths>.  If listing every path costs
much more than looking at one, override them as well.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Snapshot::Directory>

=item *

L<Dist::Conformance::Snapshot::Tree>

=item *

L<Dist::Conformance::Check>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Dist-Conformance/issues>

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
