package Dist::Conformance::Source 0.004;

# ABSTRACT: Where the standards come from: the flavor files and the templates

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base -base, -signatures;

use Dist::Conformance::Schema();


has path => q{};


sub root ($self) { die( ref($self) . " does not implement root\n" ) }


sub describe ($self) { die( ref($self) . " does not implement describe\n" ) }


sub base ($self) {
    my $root = $self->root;
    return $self->path ne q{} ? $root->child( split m{/}, $self->path ) : $root;
}


sub file ( $self, $relative ) {
    Dist::Conformance::Schema::relative_path( $relative, 'the standards' );
    my $file = $self->base->child( split m{/}, $relative );
    die( "The standards at " . $self->describe . " have no $relative\n" ) if !-e $file || -d _;
    return $file->slurp;
}


sub exists_file ( $self, $relative ) {
    my $file = $self->base->child( split m{/}, $relative );
    return -e $file && !-d _;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Source - Where the standards come from: the flavor files and the templates

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Source::Directory;

    my $source = Dist::Conformance::Source::Directory->new( directory => '/bogus/standards', path => 'skills/packaging-perl' );
    my $flavor_text = $source->file('conformance/troglodyne.yml');

=head1 DESCRIPTION

A source is a directory tree of standards: flavor files under F<conformance/>,
and the templates that they name, at any path the flavor chooses.  This class
is the interface.  L<Dist::Conformance> builds one of its two
implementations from the C<source> key of F<.conformance.yml>:

=over

=item L<Dist::Conformance::Source::Git>

C<< { git => URL, ref => REF, path => PATH } >>.  A git repository, fetched
into a cache directory.

=item L<Dist::Conformance::Source::Directory>

C<< { directory => DIR, path => PATH } >>.  A directory on this machine, read
as it is.  It works offline, and the tests use it.

=back

In both, C<path> is the directory inside the tree that holds F<conformance/>.
Every path that a flavor names, such as a template, is relative to it.
L<Dist::Conformance::Flavor/THE STANDARDS REPOSITORY> describes the layout.

=head1 ATTRIBUTES

=head2 path

The directory inside the tree that the standards start from.  Default the top
of the tree.

=head1 METHODS

=head2 root

The directory of the whole tree, as a L<Mojo::File>.  A subclass must
implement it.

=head2 describe

A short description of the source for a message, such as the URL and the ref.
A subclass must implement it.

=head2 base

The directory that L</path> names, as a L<Mojo::File>.

=head2 file

C<($relative)>.  The bytes of the file at C<$relative> below L</base>.  Dies when
there is no such file, and on an absolute path or a path with a C<..>
component.

=head2 exists_file

C<($relative)>.  Whether L</file> would find C<$relative>.

=head1 WRITING A SOURCE

Subclass this module and implement L</root> and L</describe>.  L</root> is the
place to fetch, because every read goes through it.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Flavor>

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
