package Dist::Conformance::Snapshot::Tree 0.002;

# ABSTRACT: A snapshot from a tree listing and a callback that fetches one file

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Snapshot', -signatures;


has 'paths';
has 'fetch';


sub new ( $class, @args ) {
    my $self = $class->SUPER::new(@args);
    die "paths must be a hash reference of path => blob SHA\n" if ref $self->paths ne 'HASH';
    die "fetch must be a code reference\n"                     if ref $self->fetch ne 'CODE';
    return $self;
}


sub content ( $self, $path ) {
    return undef if !$self->contains($path);
    my $fetched = $self->{fetched} //= {};
    $fetched->{$path} = $self->fetch->($path) if !exists $fetched->{$path};
    return $fetched->{$path};
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Snapshot::Tree - A snapshot from a tree listing and a callback that fetches one file

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Snapshot::Tree;

    my %blobs    = ( 'CLAUDE.md' => "Load perl-slop:reading-perl first.\n" );
    my $snapshot = Dist::Conformance::Snapshot::Tree->new(
        paths => { map { $_ => Dist::Conformance::Snapshot::blob_sha( $blobs{$_} ) } keys %blobs },
        fetch => sub ($path) { $blobs{$path} },
    );

=head1 DESCRIPTION

A snapshot of a repository that is not on this machine.  The caller gives the
listing of a git tree and a sub that fetches the content of one path, for
example from the recursive tree and the contents endpoints of a forge's API.
The checks then fetch only the files that they read.

This snapshot is not writable, so an update cannot run on it.

=head1 ATTRIBUTES

=head2 paths

Required.  A hash reference from each path to its git blob SHA.  A recursive
git tree gives these as the C<path> and the C<sha> of each C<blob> entry.

=head2 fetch

Required.  A code reference that takes a path and returns its bytes.  It is
called at most once per path, and only for a path in L</paths>.

=head1 METHODS

=head2 new

Dies unless L</paths> is a hash and L</fetch> is code.

=head2 content

C<($path)>.  The bytes from L</fetch>, memoized for the life of the object;
C<undef> for a path that the tree does not list.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Snapshot>

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
