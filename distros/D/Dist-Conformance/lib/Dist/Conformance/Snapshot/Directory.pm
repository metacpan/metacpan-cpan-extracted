package Dist::Conformance::Snapshot::Directory 0.004;

# ABSTRACT: A snapshot of a checkout on this machine, which an update can change

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Snapshot', -signatures;

use File::Find();
use File::Slurper::Temp();
use Mojo::File();

use Dist::Conformance::Schema();


has 'root';

# What git hashes: the target of a symbolic link, or the content of a file.
my sub bytes_at ($name) {
    return readlink $name if -l $name;
    return Mojo::File->new($name)->slurp;
}

# Mojo::File's to_abs resolves against the working directory, never a base.
my sub relative_to ( $path, $base ) {
    my $file = Mojo::File->new($path);
    return $file->is_abs ? $file : $base->child($path);
}


sub new ( $class, @args ) {
    my $self = $class->SUPER::new(@args);
    die "root is required\n"                               if !defined $self->root;
    die( 'root ' . $self->root . " is not a directory\n" ) if !-d $self->root;
    $self->root( Mojo::File->new( $self->root ) );
    return $self;
}


sub file ( $self, $path ) {
    Dist::Conformance::Schema::relative_path( $path, 'the checkout' );
    return $self->root->child( split m{/}, $path );
}


sub paths ($self) {
    my $root = $self->root;
    my %paths;
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                my $name = $File::Find::name;
                if ( $_ =~ m{(?:\A|/)[.]git\z} ) {
                    $File::Find::prune = 1;
                    return;
                }
                return if !-l $name && -d _;
                my $relative = Mojo::File->new($name)->to_rel($root)->to_string;
                $paths{$relative} = Dist::Conformance::Snapshot::blob_sha( bytes_at($name) );
            },
        },
        "$root",
    );
    return \%paths;
}


sub contains ( $self, $path ) {
    my $file = $self->file($path);
    return -l $file || ( -e _ && !-d _ );
}


sub sha ( $self, $path ) {
    return undef if !$self->contains($path);
    return Dist::Conformance::Snapshot::blob_sha( bytes_at( $self->file($path) ) );
}


sub content ( $self, $path ) {
    my $file = $self->file($path);
    return undef if !-e $file || -d _;
    return $file->slurp;
}


sub writable ($) { return 1 }


sub write ( $self, $path, $bytes, $mode = oct 644 ) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms) -- the method of a writable snapshot, never called as the builtin
    my $file = $self->file($path);
    $file->dirname->make_path;
    File::Slurper::Temp::write_binary( "$file", $bytes );
    chmod $mode, "$file" or die("Cannot chmod $file: $!\n");
    return $file;
}


sub hooks_dir ($self) {
    my $dot_git = $self->root->child('.git');
    return $dot_git->child('hooks') if -d $dot_git;
    return undef                    if !-e $dot_git;
    my ($gitdir) = $dot_git->slurp =~ m{\Agitdir:\ *(.+?)\s*\z};
    return undef if !defined $gitdir;
    $gitdir = relative_to( $gitdir, $self->root );
    my $common = $gitdir->child('commondir');
    return $gitdir->child('hooks') if !-e $common;
    ( my $relative = $common->slurp ) =~ s/\s+\z//;
    return relative_to( $relative, $gitdir )->child('hooks');
}


sub installed_hook ( $self, $name ) {
    my $dir  = $self->hooks_dir // return undef;
    my $hook = $dir->child($name);
    return -e $hook ? $hook->slurp : undef;
}


sub install_hook ( $self, $name, $bytes ) {
    die "$name is not a hook name\n" if $name !~ m{\A[[:lower:]][[:lower:]-]*\z};
    my $dir = $self->hooks_dir // die( $self->root . " is not a git checkout\n" );
    $dir->make_path;
    my $hook = $dir->child($name);
    File::Slurper::Temp::write_binary( "$hook", $bytes );
    chmod oct 755, "$hook" or die("Cannot chmod $hook: $!\n");
    return $hook;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Snapshot::Directory - A snapshot of a checkout on this machine, which an update can change

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use 5.040;
    use Dist::Conformance::Snapshot::Directory;

    my $snapshot = Dist::Conformance::Snapshot::Directory->new( root => '/bogus/checkout' );
    $snapshot->write( '.perltidyrc', "-l=400\n" );
    $snapshot->write( 'git-hooks/pre-commit', "#!/bin/sh\n", 0755 );
    $snapshot->install_hook( 'pre-commit', "#!/bin/sh\n" );

=head1 DESCRIPTION

The working tree of a checkout, as it is on disk now: not the index, and not a
commit.  Nothing is cached, so a check that runs after an update sees what the
update wrote.

L</paths> walks the whole tree except each F<.git>, and hashes every file.
L<Dist::Conformance::Snapshot/contains>, L<Dist::Conformance::Snapshot/sha> and
L</content> look at one file only.

Every path that this class takes is relative to L</root>.  It dies on an
absolute path and on a path with a C<..> component, so that a flavor cannot
make an update write outside the checkout.

=head1 ATTRIBUTES

=head2 root

Required.  The directory of the checkout.

=head1 METHODS

=head2 new

Dies unless L</root> is a directory.

=head2 file

C<($path)>.  The L<Mojo::File> of C<$path> under the root.  Dies on a path
that leaves the root.

=head2 paths

Every file and symbolic link below the root, except inside F<.git>, with its
blob SHA.  A symbolic link is hashed as git hashes it, by its target.

=head2 contains

C<($path)>.  Whether C<$path> is a file or a symbolic link.

=head2 sha

C<($path)>.  The blob SHA of the one file, or C<undef>.

=head2 content

C<($path)>.  The bytes of the file, or C<undef>.  For a symbolic link, the
bytes of what it points at.

=head2 writable

True.

=head2 write

C<($path, $bytes, $mode)>.  Writes C<$bytes> to C<$path> through a temporary
file and a rename, so that no reader sees half a file.  Makes the missing
directories.  C<$mode> defaults to 0644.

=head2 hooks_dir

The directory that git runs the hooks of this checkout from, or C<undef> when
the root is not a checkout.  In a worktree that is the F<hooks> of the main
checkout.  C<core.hooksPath> is not read.

=head2 installed_hook

C<($name)>.  The bytes of the hook C<$name> that git runs now, or C<undef>.

=head2 install_hook

C<($name, $bytes)>.  Writes the hook C<$name> into L</hooks_dir>, executable.
Dies when the root is not a checkout.

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
