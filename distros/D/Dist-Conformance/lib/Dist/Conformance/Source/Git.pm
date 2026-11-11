package Dist::Conformance::Source::Git 0.004;

# ABSTRACT: Standards fetched from a git repository into a cache directory

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Source', -signatures;

use Digest::SHA();
use IPC::Run3();
use Mojo::File();


has 'url';
has ref     => 'HEAD';
has offline => 0;
has cache   => sub {
    my $base = $ENV{XDG_CACHE_HOME} || Mojo::File->new( $ENV{HOME} // die("Neither XDG_CACHE_HOME nor HOME is set\n") )->child('.cache');
    return Mojo::File->new($base)->child('dist-conformance')->to_string;
};


sub new ( $class, @args ) {
    my $self = $class->SUPER::new(@args);
    die "url is required\n"                             if !defined $self->url || $self->url eq q{};
    die( 'The url ' . $self->url . " starts with -\n" ) if index( $self->url, q{-} ) == 0;
    die( 'The ref ' . $self->ref . " starts with -\n" ) if index( $self->ref, q{-} ) == 0;
    return $self;
}


sub clone_dir ($self) {
    return Mojo::File->new( $self->cache )->child( Digest::SHA::sha1_hex( $self->url . "\n" . $self->ref ) );
}


sub root ($self) {
    return $self->{root} //= do {
        my $dir = $self->clone_dir;
        if ( $self->offline ) {
            die( 'Offline, and there is no cached copy of ' . $self->describe, "\n" ) if !-d $dir->child('.git');
        }
        else {
            $self->fetch;
        }
        $dir;
    };
}


sub fetch ($self) {
    my $dir = $self->clone_dir;
    if ( !-d $dir->child('.git') ) {
        $dir->remove_tree;
        $dir->dirname->make_path;
        git( qw{clone --quiet --no-checkout --}, $self->url, "$dir" );
    }
    git( '-C', "$dir", qw{fetch --quiet origin}, $self->ref );
    git( '-C', "$dir", qw{checkout --quiet --force --detach FETCH_HEAD} );
    return $dir;
}


sub describe ($self) {
    return $self->url . ' at ' . $self->ref . ( $self->path ne q{} ? ' (path ' . $self->path . ')' : q{} );
}


# A clone and a fetch need the transports, the credential helpers and the
# configuration of the real git, which no CPAN module reproduces.
sub git (@arguments) {
    local $ENV{GIT_TERMINAL_PROMPT} = 0;
    my ( $out, $err ) = ( q{}, q{} );
    IPC::Run3::run3( [ 'git', @arguments ], \undef, \$out, \$err );
    my $status = $?;
    die( "git @arguments failed: " . ( $err =~ s/\s+\z//r ), "\n" ) if $status;
    return $out;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Source::Git - Standards fetched from a git repository into a cache directory

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Source::Git;

    my $source = Dist::Conformance::Source::Git->new(
        url  => 'https://forge.test.test/standards.git',
        ref  => 'main',
        path => 'skills/packaging-perl',
    );
    my $flavor = $source->file('conformance/troglodyne.yml');    # fetches first

=head1 DESCRIPTION

A tree of standards in a git repository.  The first read through L</root>
fetches the latest commit of L</ref> into a clone under L</cache>, and checks it
out.  Later reads by the same object use that checkout, so one run sees one
commit, however many files it reads.

Each URL and ref has a clone of its own, in a directory named by the SHA-1 of
the two, so two flavors at two refs of one repository do not fight over a
checkout.  The clone is a cache: deleting it costs one full clone the next time.

=head1 ATTRIBUTES

=head2 url

Required.  Anything that C<git clone> takes: a URL, or the path of a
repository on this machine.

=head2 ref

The branch, tag or commit to fetch.  Default C<HEAD>, the default branch of the
remote.

=head2 cache

The directory that holds the clones.  Default F<dist-conformance> under
C<$XDG_CACHE_HOME>, or under F<~/.cache> when that is not set.

=head2 offline

When true, L</root> fetches nothing, and uses the clone as the last fetch left
it.  Dies when there is no clone yet.

=head1 METHODS

=head2 new

Dies unless L</url> is given, and on a URL or a ref that git would take for an
option.

=head2 clone_dir

The directory of the clone of this URL and ref, as a L<Mojo::File>.

=head2 root

The checkout, after a L</fetch> unless L</offline>.  Memoized on the object.

=head2 fetch

Clones the repository if there is no clone yet, fetches L</ref>, and checks out
what it fetched, discarding any change in the checkout.  Dies with what git
said when a step fails.

=head2 describe

The URL and the ref.

=head1 FUNCTIONS

=head2 git

C<(@arguments)>.  Runs C<git> with C<@arguments>, and dies with its standard
error when it fails.  Every call to git goes through this function, so a test
can replace it.

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
