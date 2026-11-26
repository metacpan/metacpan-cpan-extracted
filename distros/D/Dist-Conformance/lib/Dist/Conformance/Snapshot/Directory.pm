package Dist::Conformance::Snapshot::Directory 0.011;

# ABSTRACT: A snapshot of a checkout on this machine, which an update can change

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Mojo::Base 'Dist::Conformance::Snapshot', -signatures;

use File::Find();
use File::Slurper::Temp();
use Mojo::File();

use Dist::Conformance::Schema();
use Dist::Conformance::Source::Git();


has 'root';

# What git hashes: the target of a symbolic link, or the content of a file.
my sub bytes_at ($name) {
    return readlink $name if -l $name;
    return Mojo::File->new($name)->slurp;
}


sub new ( $class, @args ) {
    my $self = $class->SUPER::new(@args);
    die "root is required\n"                               if !defined $self->root;
    die( 'root ' . $self->root . " is not a directory\n" ) if !-d $self->root;
    $self->root( Mojo::File->new( $self->root ) );
    return $self;
}

# The L<Mojo::File> of C<$path> under the root.
# @param   path  Str  the path, relative to the root
# @returns InstanceOf["Mojo::File"]  the file, which may not exist
# @throws  on a path that leaves the root, as L<Dist::Conformance::Schema/"relative_path($path, $inside)"> says
# @example my $file = $snapshot->file('CLAUDE.md');
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

# Writes C<$bytes> to C<$path> through a temporary file and a rename, so that no
# reader sees half a file.  Makes the missing directories.
# @param   path   Str  the path, relative to the root
# @param   bytes  Str  the content
# @param   mode   Int  optional: the permissions, default 0644
# @returns InstanceOf["Mojo::File"]  the file that it wrote
# @throws  on a path that leaves the root, and when it cannot write the file or set its mode
# @example $snapshot->write( '.perltidyrc', "-l=400\n" );
sub write ( $self, $path, $bytes, $mode = oct 644 ) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms) -- the method of a writable snapshot, never called as the builtin
    my $file = $self->file($path);
    $file->dirname->make_path;
    File::Slurper::Temp::write_binary( "$file", $bytes );
    chmod $mode, "$file" or die("Cannot chmod $file: $!\n");
    return $file;
}

# The directory that git runs the hooks of this checkout from.  That is what
# C<git rev-parse --git-path hooks> answers in the root: F<.git/hooks>, or in a
# worktree the F<hooks> of the main checkout, unless C<core.hooksPath> names
# another directory.  A relative C<core.hooksPath> is relative to the root, so a
# C<core.hooksPath> of F<git-hooks> makes each worktree run the hooks that its
# own branch tracks.  It needs git 2.10 or later, the first whose C<--git-path>
# honors C<core.hooksPath>.
# @returns InstanceOf["Mojo::File"]|Undef  the directory, or C<undef> when the root
# has no F<.git>
# @throws  with the error of git when git finds no repository in a root that has
# a F<.git>
# @example my $hooks = $snapshot->hooks_dir;
sub hooks_dir ($self) {
    my $root = $self->root;
    return undef if !-e $root->child('.git');

    # The root decides, not a repository that the environment names.
    delete local @ENV{qw{GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR}};
    chomp( my $path = Dist::Conformance::Source::Git::git( q{-C}, "$root", qw{rev-parse --git-path hooks} ) );
    my $hooks = Mojo::File->new($path);

    # Mojo::File's to_abs resolves against the working directory, never a base.
    return $hooks->is_abs ? $hooks : $root->child($path);
}

# The bytes of the hook C<$name> that git runs now.
# @param   name  Str  the name of the hook, such as C<pre-commit>
# @returns Str|Undef  the bytes, or C<undef> when the hook or the checkout is not there
# @throws  as L</hooks_dir> does
# @example my $bytes = $snapshot->installed_hook('pre-commit');
sub installed_hook ( $self, $name ) {
    my $dir  = $self->hooks_dir // return undef;
    my $hook = $dir->child($name);
    return -e $hook ? $hook->slurp : undef;
}

# Writes the hook C<$name> into L</hooks_dir>, executable.
# @param   name   Str  the name of the hook, such as C<pre-commit>
# @param   bytes  Str  the content of the hook
# @returns InstanceOf["Mojo::File"]  the hook that it wrote
# @throws  when the name is not that of a hook, when the root is not a checkout,
# and when it cannot write the hook or make it executable
# @example $snapshot->install_hook( 'pre-commit', $bytes );
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

version 0.011

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
L<Dist::Conformance::Snapshot/"contains(path)">, L<Dist::Conformance::Snapshot/"sha(path)"> and
L<content|/"content($path)"> look at one file only.

Every path that this class takes is relative to L</root>.  It dies on an
absolute path and on a path with a C<..> component, so that a flavor cannot
make an update write outside the checkout.

=head1 ATTRIBUTES

=head2 root

Required.  The directory of the checkout.

=head1 METHODS

=head2 new(@args)

A new snapshot, whose L</root> becomes a L<Mojo::File>.

=over 4

=item args - Hash - the attributes, such as L</root>, as named arguments

=back

Returns a Dist::Conformance::Snapshot::Directory object.

Dies unless L</root> is a directory.

    my $snapshot = Dist::Conformance::Snapshot::Directory->new( root => '/bogus/checkout' );

=head2 paths

Every file and symbolic link below the root, except inside F<.git>, with its
blob SHA.  A symbolic link is hashed as git hashes it, by its target.

Returns HashRef, from each path to its blob SHA.

    my $paths = $snapshot->paths;

=head2 contains($path)

Whether C<$path> is a file or a symbolic link.

=over 4

=item path - Str - the path

=back

Returns Bool.

Dies on a path that leaves the root.

    say 'has a profile' if $snapshot->contains('.perlcriticrc');

=head2 sha($path)

The blob SHA of the one file.

=over 4

=item path - Str - the path

=back

Returns Str or undef: the SHA, or C<undef> when there is no such file.

Dies on a path that leaves the root.

    my $sha = $snapshot->sha('git-hooks/pre-commit');

=head2 content($path)

The bytes of the file.  For a symbolic link, the bytes of what it points at.

=over 4

=item path - Str - the path

=back

Returns Str or undef: the bytes, or C<undef> when there is no such file.

Dies on a path that leaves the root.

    my $text = $snapshot->content('CLAUDE.md');

=head2 writable

True.

Returns Bool.

    my $update = Dist::Conformance::Update->new( snapshot => $snapshot, dry_run => !$snapshot->writable );

=head2 file(path)

The L<Mojo::File> of C<$path> under the root.

=over 4

=item path - Str - the path, relative to the root

=back

Returns a Mojo::File object, the file, which may not exist.

Dies on a path that leaves the root, as L<Dist::Conformance::Schema/"relative_path($path, $inside)"> says.

    my $file = $snapshot->file('CLAUDE.md');

=head2 hooks_dir

The directory that git runs the hooks of this checkout from.  That is what C<git rev-parse --git-path hooks> answers in the root: F<.git/hooks>, or in a worktree the F<hooks> of the main checkout, unless C<core.hooksPath> names another directory.  A relative C<core.hooksPath> is relative to the root, so a C<core.hooksPath> of F<git-hooks> makes each worktree run the hooks that its own branch tracks.  It needs git 2.10 or later, the first whose C<--git-path> honors C<core.hooksPath>.

Returns a Mojo::File object or Undef, the directory, or C<undef> when the root has no F<.git>.

Dies with the error of git when git finds no repository in a root that has a F<.git>.

    my $hooks = $snapshot->hooks_dir;

=head2 install_hook(name, bytes)

Writes the hook C<$name> into L</hooks_dir>, executable.

=over 4

=item name - Str - the name of the hook, such as C<pre-commit>

=item bytes - Str - the content of the hook

=back

Returns a Mojo::File object, the hook that it wrote.

Dies when the name is not that of a hook, when the root is not a checkout, and when it cannot write the hook or make it executable.

    $snapshot->install_hook( 'pre-commit', $bytes );

=head2 installed_hook(name)

The bytes of the hook C<$name> that git runs now.

=over 4

=item name - Str - the name of the hook, such as C<pre-commit>

=back

Returns Str or Undef, the bytes, or C<undef> when the hook or the checkout is not there.

Dies as L</hooks_dir> does.

    my $bytes = $snapshot->installed_hook('pre-commit');

=head2 write(path, bytes, mode)

Writes C<$bytes> to C<$path> through a temporary file and a rename, so that no reader sees half a file.  Makes the missing directories.

=over 4

=item path - Str - the path, relative to the root

=item bytes - Str - the content

=item mode - Int - optional: the permissions, default 0644

=back

Returns a Mojo::File object, the file that it wrote.

Dies on a path that leaves the root, and when it cannot write the file or set its mode.

    $snapshot->write( '.perltidyrc', "-l=400\n" );

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
