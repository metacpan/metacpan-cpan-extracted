# most of this was sponsored by socialflow.com

package File::Tree::Snapshot;
use Moo;
use File::Path;
use File::Basename;

our $VERSION = '0.000001';
$VERSION = eval $VERSION;

has storage_path => (is => 'ro', required => 1);

has allow_empty => (is => 'ro');

sub file { join '/', (shift)->storage_path, @_}

sub open {
    my ($self, $mode, $file, %opt) = @_;
    $file = $self->file($file)
        unless $opt{is_absolute};
    $self->_mkpath(dirname $file)
        if $opt{mkpath};
    open my $fh, $mode, $file
        or die "Unable to write '$file': $!\n";
    return $fh;
}

sub _mkpath {
    my ($self, $dir) = @_;
    mkpath($dir, { error => \(my $err) });
    if (@$err) {
        warn "Error while attempting to create '$dir': $_\n"
            for map { (values %$_) } @$err;
    }
    return 1;
}

sub _exec {
    my ($self, $cmd) = @_;
    system($cmd) and die "Error during ($cmd)\n";
    return 1;
}

sub _git_exec {
    my ($self, @cmd) = @_;
    my $path = $self->storage_path;
    #local $ENV{GIT_DIR} = "$path/.git";
    return $self->_exec(
        sprintf q{cd %s && git %s},
            $path,
            join ' ', @cmd,
    );
}

sub create {
    my ($self) = @_;
    my $path = $self->storage_path;
    $self->_mkpath($path);
    $self->_git_exec('init');
    CORE::open my $fh, '>', "$path/.gitignore"
      or die "Unable to write .gitignore in '$path': $!\n";
    $self->_git_exec('add', '.gitignore');
    $self->_git_exec('commit', '-m', '"Initial commit"');
    return 1;
}

sub _has_changes {
    my ($self) = @_;
    my $path = $self->storage_path;
    my $cmd = qq{cd $path && git status --porcelain};
    CORE::open my $handle, '-|', $cmd
      or die "Unable to find changes in ($cmd): $!\n";
    my @changes = <$handle>;
    return scalar @changes;
}

sub commit {
    my ($self) = @_;
    $self->_git_exec('add .');
    unless ($self->_has_changes) {
        print "No changes\n";
        return 1;
    }
    $self->_git_exec('commit',
        '--all',
        ($self->allow_empty ? '--allow-empty' : ()),
        '-m' => sprintf('"Updated on %s"', scalar localtime),
    );
    return 1;
}

sub reset {
    my ($self) = @_;
    $self->_git_exec('add .');
    return 1
        unless $self->_has_changes;
    $self->_git_exec('checkout -f');
    return 1;
}

sub exists {
    my ($self) = @_;
    return -e join '/', $self->storage_path, '.git';
}

sub find_files {
    my ($self, $ext, @path) = @_;
    my $root = $self->file(@path);
    my @files = `find $root -name '*.$ext' -type f`;
    chomp @files;
    return @files;
}

1;

=head1 NAME

File::Tree::Snapshot - Snapshot files in a git repository

=head1 SYNOPSIS

    use File::Tree::Snapshot;

    my $tree = File::Tree::Snapshot->new(
        storage_path => '/path/to/tree',
    );

    $tree->create
        unless $tree->exists;

    # modify files, see methods below

    $tree->commit;
    # or
    $tree->reset;

=head1 DESCRIPTION

This module manages snapshots of file system trees by wrapping the C<git>
command line interface. It currently only manages generating the snapshots.

The directories are standard Git repositories and can be accessed in the
usual ways.

=head1 ATTRIBUTES

=head2 storage_path

The path to the tree that should hold the files that are snapshot. This
attribute is required.

=head2 allow_empty

If this attribute is set to true, commits will be created even if no changes
were registered.

=head1 METHODS

=head2 new

    my $tree = File::Tree::Snapshot->new(%attributes);

Constructor. See L</ATTRIBUTES> for possible parameters.

=head2 file

    my $path = $tree->file(@relative_path_parts_to_file);

Takes a set of path parts and returns the path to the file inside the
storage.

=head2 open

    my $fh = $tree->open($mode, $file, %options);

Opens a file within the storage. C<$mode> is passed straight to
L<perlfunc/open>. The C<$file> is a relative path inside the storage.

Possible options are:

=over

=item * C<is_absolute>

If set to true the C<$file> will be assumed to already be an absolute
path as returned by L</file>, instead of a path relative to the storage.

=item * C<mkpath>

Create the path to the file if it doesn't already exist.

=back

=head2 create

    $tree->create;

Create the directory (if it doesn't exist yet) and initialize it as a
Git repository.

=head2 exists

    my $does_exist = $tree->exists;

Returns true if the storage is an initialized Git repository.

=head2 commit

Will commit the changes made to the tree to the Git repository.

=head2 reset

Rolls back the changes since the last snapshot.

=head1 AUTHOR

 phaylon - Robert Sedlacek (cpan:PHAYLON) <r.sedlacek@shadowcat.co.uk>

=head1 CONTRIBUTORS

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 SPONSORS

The development of this module was sponsored by L<http://socialflow.com/>.

=head1 COPYRIGHT

Copyright (c) 2012 the File::Tree::Snapshot L</AUTHOR>, L</CONTRIBUTORS>
and L</SPONSORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
