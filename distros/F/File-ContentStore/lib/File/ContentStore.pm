package File::ContentStore;
$File::ContentStore::VERSION = '1.000';
use 5.014;

use Carp qw( croak );
use Types::Standard qw( slurpy Object Bool Str ArrayRef CodeRef );
use Types::Path::Tiny qw( Dir File );
use Type::Params qw( compile );
use Digest;

use Moo;
use namespace::clean;

has path => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

has digest => (
    is      => 'ro',
    isa     => Str,
    default => 'SHA-1',
);

has parts => (
    is => 'lazy',
    builder =>
      sub { int( length( Digest->new( shift->digest )->hexdigest ) / 32 ) },
    init_arg => undef,
);

has check_for_collisions => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
    default  => 1,
);

has make_read_only => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
    default  => 1,
);

has file_callback => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

# if a single non-hashref argument is given, assume it's 'path'
sub BUILDARGS {
    my $class = shift;
    scalar @_ == 1
      ? ref $_[0] eq 'HASH'
          ? { %{ $_[0] } }
          : { path => $_[0] }
      : @_ % 2 ? Carp::croak(
            "The new() method for $class expects a hash reference or a"
          . " key/value list. You passed an odd number of arguments" )
      : {@_};
}

sub BUILD {
    Digest->new( shift->digest );    # dies if 'digest' is not installed
}

my $BUFF_SIZE = 1024 * 32;
my $DIGEST_OPTS = { chunk_size => $BUFF_SIZE };

sub link_file {
    state $check = compile( Object, File );
    my ( $self, $file ) = $check->(@_);

    # compute content file name
    my $digest = $file->digest( $DIGEST_OPTS, $self->digest );
    my $content =
      $self->path->child(
        map( { substr $digest, 2 * $_, 2 } 0 .. $self->parts - 1 ),
        substr( $digest, 2 * $self->parts ) );

    $self->file_callback->( $file, $digest, $content )
       if $self->has_file_callback;

    # check for collisions
    if( -e $content && $self->check_for_collisions ) {
        croak "Collision found for $file and $content: size differs"
           if -s $file != -s $content;

        my @buf;
        my @fh = map $_->openr_raw, $file, $content;
        while( $fh[0]->sysread( $buf[0], $BUFF_SIZE ) ) {
            $fh[1]->sysread( $buf[1], $BUFF_SIZE );
            croak "Collision found for $file and $content: content differs"
                 if $buf[0] ne $buf[1];
        }
    }

    # link both files
    $content->parent->mkpath;
    my ( $old, $new ) = -e $content ? ( $content, $file ) : ( $file, $content );

    return if $old eq $new;    # do not link a file to itself
    unlink $new if -e $new;
    link $old, $new or croak "Failed linking $new to to $old: $!";
    chmod 0444, $old if $self->make_read_only;

    return $content;
}

sub link_dir {
    state $check = compile( Object, slurpy ArrayRef[Dir] );
    my ( $self, $dirs ) = $check->(@_);

    $_->visit( sub { $self->link_file($_) if -f }, { recurse => 1 } )
      for @$dirs;
}

sub fsck {
    my ($self) = @_;
    $self->path->visit(
        sub {
            my ( $path, $state ) = @_;

            if ( -d $path ) {

                # empty directory
                push @{ $state->{empty} }, $path unless $path->children;
            }
            else {

                # orphan content file
                push @{ $state->{orphan} }, $path
                  if $path->stat->nlink == 1;

                # content does not match name
                my $digest = $path->digest( $DIGEST_OPTS, $self->digest );
                push @{ $state->{corrupted} }, $path
                  if $digest ne $path->relative( $self->path ) =~ s{/}{}gr;
            }
        },
        { recurse => 1 },
    );
}

1;

__END__

=for Pod::Coverage
BUILD
BUILDARGS
has_file_callback

=head1 NAME

File::ContentStore - A store for file content built with hard links

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    use File:::ContentStore;

    # the 'path' argument is expected to exist
    my $store = File:::ContentStore->new( path => "$ENV{HOME}/.photo_content" );
    $store->link_dir( @collection_of_photo_directories );

=head1 DESCRIPTION

This module manages a I<content store> as a collection of hard links
to a set of files. The files in the content store are named after the
digest of the content in the file.

When linking a new file to the content store, a hard link is created
to the file, named after the digest of the content. When a file which
content is already in the store is linked in, the file is hard linked
to the content file in the store.

=head2 Example and detailed operation

For a more complete definition of a hard link, see
L<https://en.wikipedia.org/wiki/Hard_link>.

Assuming we have directory containing the following files: F<file1>
(inode 123456), F<file2> (inode 456789) and F<file3> (inode 789012,
content identical to F<file1>). In the examples below, files are
sorted by inode.

After linking F<file1> into the content store, we have the following:

    Directory                Content store
    ---------                -------------
    [123456] file1           [123456] d4/1d/8cd98f00b279d1c00998ecf8427e
    [456789] file2           [456789] 8a/80/52e7a4f99c54b966a74144fe5761
    [789012] file3

After linking F<file2>:

    Directory                Content store
    ---------                -------------
    [123456] file1           [123456] d4/1d/8cd98f00b279d1c00998ecf8427e
    [456789] file2           [456789] 8a/80/52e7a4f99c54b966a74144fe5761
    [789012] file3

And finally, after linking F<file3>, we have this:

    Directory                Content store
    ---------                -------------
    [123456] file1           [123456] d4/1d/8cd98f00b279d1c00998ecf8427e
    [123456] file3
    [456789] file2           [456789] 8a/80/52e7a4f99c54b966a74144fe5761

i.e. the inode that was holding the content of F<file3> is lost, and the
name now points to the same inode as F<file1> and its content file.

F<file1> and F<file3> are now hard linked (or aliased) together, so any
change done to one of them will in fact be done to both. Note also that
the disk space taken by duplicated extra files is regained when they
are linked through the content store.

If the goal is deduplication and hard-linking of identical files, once
all the files have been linked through the content store, the content
store is not needed any more, and can be deleted.

=head1 ATTRIBUTES

=head2 path

The location of the directory where the content files are store.
(Required.)

=head2 digest

The algorithm used to compute the content digest.
(Default: C<SHA-1>.)

Any string that is suitable for passing to the L<Digest> module
constructor is valid. The choice of a digest is a compromise between
speed and risk of collisions.

=head2 parts

This internal attribute describes in how many parts (i.e. sub-directories)
the content filename is split. It is computed automatically from L<digest>.

For example, the empty file would be linked to:

    # digest = MD4, parts = 1
    31/d6cfe0d16ae931b73c59d7e0c089c0

    # digest = MD5, parts = 1
    d4/1d8cd98f00b204e9800998ecf8427e

    # digest = SHA-1, parts = 1
    da/39a3ee5e6b4b0d3255bfef95601890afd80709

    # digest = SHA-256, parts = 2
    e3/b0/c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

=head2 check_for_collisions

When this boolean attribute is set to true, any time the content file
for a file linked into the store already exists, the files will be
compared for equality before linking them. This prevents data loss in
case of collisions.

The default is true to avoid data loss.

If a collision is detected, the solution is to upgrade the digest to a
stronger one.

    # create a MD5 store
    my $md5_store = File::ContentStore->( path => $old, digest => 'MD5' );

    # expose a collision
    $old_store->link_file($file);    # dies

    # create a new SHA-1 store
    my $sha1_store = File::ContentStore->new( path => $new, digest => 'SHA-1' );

    # link the old content to in the new store
    # the files that were linked to the old store will be linked to the new one
    $sha1_store->link_dir( $md5_store->path );
    $sha1_store->link_file( $file->path );    # success!

    $md5_store->path->remove_tree;            # delete the old content store

=head2 make_read_only

When this attribute is set to a true value, a L<perlfunc/chmod> to
read-only permissions is performed on the content files (and therefore
the linked files, since permissions are an attribute of the inode).

The default is true, to avoid unwittingly modifying linked files that
were identical unbeknownst to the user.

=head2 file_callback

This optional coderef is called by L</link_file> when linking a file into
the store. This is useful for providing user feedback when processing
large directories. The callback receives three arguments: the file, its
digest and the content file (files are passed as L<Path::Tiny> objects).

Usage example:

    File::ContentStore->new(
        path          => $dir,
        file_callback => sub {
            my ( $file, $digest, $content ) = @_;
            print STDERR "Linking $file ($digest) to $content\n";
        }
    );

=head1 METHODS

=head2 new

Constructor. See L</ATTRIBUTES> for valid attributes.

=head2 link_file

    $store->link_file($file);

Link a single file into the content store.

=head2 link_dir

    $store->link_dir(@dirs);

Recursively link all the files under the given directories.

=head2 fsck

Runs a consistency check on the content store (i.e. the files under
L<path>), and returns a hash reference containing all the errors found.
If no error is found, the hash reference is empty.

The types of errors found are:

=over 4

=item empty

An array reference containing all the empty directories under L<path>.

=item orphan

An array references containing L<Path::Tiny> objects pointing to the
content files with no alias (i.e. not linked to any file outside of the
content store).

=item corrupted

An arrary reference of all content files for which the name does not
match the digest of their content.

=back

=head1 SEE ALSO

Other modules suitable for finding duplicated files:
L<File::Find::Duplicates>, L<File::Same>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>.

=head1 COPYRIGHT

Copyright 2018 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
