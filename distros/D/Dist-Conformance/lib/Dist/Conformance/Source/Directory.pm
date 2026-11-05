package Dist::Conformance::Source::Directory 0.002;

# ABSTRACT: Standards read from a directory on this machine

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Source', -signatures;

use Mojo::File();


has 'directory';


sub new ( $class, @args ) {
    my $self = $class->SUPER::new(@args);
    die "directory is required\n" if !defined $self->directory;
    return $self;
}


sub root ($self) {
    my $root = Mojo::File->new( $self->directory );
    die "The standards directory $root does not exist\n" if !-d $root;
    return $root;
}


sub describe ($self) {
    return $self->directory . ( $self->path ne q{} ? ' (path ' . $self->path . ')' : q{} );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Source::Directory - Standards read from a directory on this machine

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Source::Directory;

    my $source = Dist::Conformance::Source::Directory->new( directory => '/bogus/standards' );
    my $flavor = $source->file('conformance/troglodyne.yml');

=head1 DESCRIPTION

A tree of standards that is already on this machine, such as a checkout of the
standards repository that you are editing.  Nothing is fetched, so it works
offline, and the tests use it.

=head1 ATTRIBUTES

=head2 directory

Required.  The top of the tree.

=head1 METHODS

=head2 new

Dies unless L</directory> is given.

=head2 root

L</directory>, as a L<Mojo::File>.  Dies when it is not a directory.

=head2 describe

The directory, and the path inside it.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Source>

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
