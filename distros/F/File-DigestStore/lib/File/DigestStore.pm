package File::DigestStore;
{
  $File::DigestStore::DIST = 'File-DigestStore';
}
{
  $File::DigestStore::VERSION = '1.008';
}
# ABSTRACT: Digested hierarchical storage of files
use Algorithm::Nhash;
use Digest;
use MooseX::Types -declare => [qw/ OctalMode /];
use MooseX::Types::Moose qw/ Int Str Value /;
use MooseX::Types::Path::Class;
use Moose::Util::TypeConstraints;
use Moose;
use Path::Class qw/ dir file /;
use IO::File;
use Sys::Hostname;
my $hostname = hostname;

subtype OctalMode, as Int, where { not /^0\d/ };
coerce OctalMode, from Str, via { oct $_ };

has root      => (is => 'ro', isa => 'Path::Class::Dir', coerce => 1, required => 1);
has levels    => (is => 'ro', isa => Str, default => '8,256');
has algorithm => (is => 'ro', isa => Str, default => 'SHA-512');
has dir_mask  => (is => 'ro', isa => OctalMode, coerce => 1, default => '0777');
has file_mask => (is => 'ro', isa => OctalMode, coerce => 1, default => '0666');
has layers    => (is => 'ro', isa => Str, default => ':raw');

# private attribute
has nhash => ( is => 'ro', isa => 'Algorithm::Nhash', lazy_build => 1 );



sub store_path {
    my($self, $path) = @_;

    confess "Can't store an undefined filename"
        unless defined $path;

    return $self->store_string($self->_readfile($path));
}


sub store_string {
    my($self, $string) = @_;

    confess "Can't store an undefined string"
        unless defined $string;
    confess "Can't store a reference"
        if ref $string;

    my $digester = Digest->new($self->algorithm);
    $digester->add($string);
    my $digest = $digester->hexdigest;
    my $path = $self->_digest2path($digest);

    unless(-e $path) {          # skip rewrite if the file already exists
        my $parent = $path->dir;
        $parent->mkpath(0, $self->dir_mask)
            unless -d $parent;

        $self->_writefile($path, $string);
    }
    return wantarray ? ($digest, length $string) : $digest;
}


sub fetch_path {
    my($self, $digest) = @_;

    confess "Can't fetch an undefined ID"
        unless defined $digest;

    my $path = $self->_digest2path($digest);
    return unless -f $path;
    return $path;
}


sub fetch_string {
    my($self, $digest) = @_;

    confess "Can't fetch an undefined ID"
        unless defined $digest;

    my $path = $self->_digest2path($digest);
    return unless -f $path;
    return $self->_readfile($path);
}


sub exists {
    my($self, $digest) = @_;

    confess "Can't check an undefined ID"
        unless defined $digest;

    my $path = $self->_digest2path($digest);
    return -f $path;
}


sub delete {
    my($self, $digest) = @_;

    confess "Can't delete an undefined ID"
        unless defined $digest;

    my $path = $self->_digest2path($digest);
    unless(unlink $path) {
        confess "Can't unlink $path: $!"
            unless $!{ENOENT};
        return;
    }
    return 1;
}


sub fetch_file {
    Carp::cluck "Deprecated fetch_file() called"
          unless our $deprecated++;
    goto &fetch_path;
}


my $deprecated_called;

sub store_file {
    Carp::cluck "Deprecated store_file() called"
        unless our $deprecated++;
    goto &store_path;
}


sub _build_nhash {
    my($self) = shift;

    my @buckets = split /,/, $self->levels;
    # bail if there are no storage levels; it's not terribly useful and
    # Algorithm::Nhash::nhash() doesn't return an empty path in this case.
    confess "At least one storage level is required"
        unless @buckets;

    return Algorithm::Nhash->new(@buckets);
}


sub _digest2path {
    my($self, $digest) = @_;

    return file(
        $self->root,
        $self->nhash->nhash($digest),
        $digest,
    );
};


sub _readfile {
    my($self, $path) = @_;

    my $fh = IO::File->new($path, 'r')
        or confess "Can't read $path: $!";
    $fh->binmode($self->layers);
    local $/;
    # prepending "" covers the case of an empty file, otherwise we'd get undef
    return "".<$fh>;
};


sub _writefile {
    my($self, $path, $string) = @_;

    my $unique = file($path->dir, $path->basename.".$hostname.$$");
    my $mode = O_WRONLY | O_CREAT | O_EXCL;
    my $fh = IO::File->new($unique, $mode, $self->{file_mask})
        or die "Can't create $unique: $!";
    $fh->binmode($self->layers);
    print $fh $string;
    $fh->close;

    rename $unique, $path
        or die "Could not rename $unique to $path: $!";
};


1;

__END__
=pod

=head1 NAME

File::DigestStore - Digested hierarchical storage of files

=head1 VERSION

version 1.008

=head1 SYNOPSIS

 my $store = File::DigestStore->new( root => '/var/lib/digeststore' );

 # stores the file and returns a short-ish ID
 my $id = $store->store_path('/etc/motd');
 # Will output a hex string like '110fe...'
 print "$id\n";
 # returns a filename that has the same contents as the stored file
 my $path = $store->fetch_file($id);
 # Will return something like '/var/lib/digeststore/1/2/110fe...'
 print "$path\n";

=head1 DESCRIPTION

This module is used to take large files (or strings) and store them on disk
with a name based on the hashed file contents, returning said hash. This
hash is much shorter than the data and is much more easily stored in a
database than the original file. Because of the hashing, only a single copy
of the data will be stored on disk no matter how many times one calls
store_path() or store_string().

=head1 BACKEND STORAGE

The backend data store should be considered opaque as far as your Perl
program is concerned, but it actually consists of the files hashed and then
stored in a multi-level directory structure for fast access. Files are never
moved around the tree so if the stash is particularly large, you can place
subtrees on their own filesystem if required. Directories are created
on-demand and so do not need to be pre-created.

The file's name is just the hash of the file's contents, and the file's
directory is the result of applying the nhash algorithm to the hash. Thus,
replacing the nhash object with another class that provides a nhash() method
allows you to fine-tune the directory layout.

=head1 MOOSE FIELDS

=head2 root (required)

The base directory that is used to store the files. This will be created if
it does not exist, and the stashed files stored underneath it.

=head2 levels (optional, default "8,256")

The number of directory entries in each level of the tree. For example,
"8,256" means that the top-level will have eight directories (called "0"
through "7") and each of those directories will have 256 sub-directories.
The stashed data files appear under those.

=head2 algorithm (optional, default "SHA-512")

The digest algorithm used to hash the files. This is passed to
C<< Digest->new() >>. The file's content is hashed and then stored using that
name, so you should select an algorithm that does not generate collisions.

=head2 dir_mask (optional, default 0777)

The directory creation mask for the stash directories. This is merged with
your umask so the default is usually fine.

As a special case, this will also treat strings starting with a zero as an
octal number. This is helpful when you are using Catalyst::Model::Adaptor on
this class and wish to change the mask in the application configuration
file.

=head2 file_mask (optional, default 0666)

The file creation mask for the stashed files. This is merged with your umask
setting so the default is usually fine.

This has the same special-casing for strings as dir_mask.

=head2 layers (optional, default ":raw")

The PerlIO layer to use when storing and retrieving data. Note that while
this could be used to set the encoding for string I/O (e.g. with
store_string()), the Digest algorithms expect your strings to be sequences
of octets. This is mainly here for if you wish to use a layer that performs
transparent compression.

=head1 PRIVATE MOOSE FIELDS

=head2 nhash (optional, builds an Algorithm::Nhash based on I<levels>)

This is the internal Algorithm::Nhash object used to convert a file's hash
into subdirectories.

=head1 METHODS

=head2 new

 my $store = File::DigestStore->new( root => '/var/lib/digeststore' );

This creates a handle to a new digested storage area. Arguments are given to
it to define the layout of the storage area. See "MOOSE FIELDS" above for
the available options.

=head2 store_path

 my $id = $store->store_path('/etc/motd');

 my ($id, $size) = $store->store_path('/etc/passwd');

This copies the file's contents into the stash. In scalar context it returns
the file's ID. In list context it returns an (ID, file size) tuple. (The
latter saves you having to stat() your file.)

=head2 store_string

 my $id = $store->store_string('Hello, world');

This copies the string's contents into the stash. In scalar context it
returns the file's ID. In list context it returns an (ID, string length)
tuple.

=head2 fetch_path

 my $path = $store->fetch_path($id);

Given an ID, will return the path to the stashed copy of the file, or undef
if no file with that ID has ever been stored. Note that the path refers to
the master copy of the file within the stash and you must not modify it.

=head2 fetch_string

 my $string = $store->fetch_string($id);

Given an ID, will return the string which was previously stashed to that ID
or undef if no string with that ID has ever been stored.

=head2 exists

 if($store->exists($id)) {
    # ...
 }

Returns true if anything is stashed with the given ID, otherwise false.

=head2 delete (new in 1.007)

 $store->delete($id);

Removes the data stashed with the given ID and returns true if it existed or
false if it did not.

=head1 DEPRECATED METHODS

=head2 fetch_file

fetch_path was originally called this, but the name is inappropriate since
it implies that it fetches the file rather than just the file's name.

=head2 store_file

store_path was originally called this, but the name is inappropriate since
it implies that the parameter was the file rather than the file's name.

=head1 PRIVATE METHODS

These methods are I<private> and not for end-users; the API may change
without notice. If you use them and stuff breaks, it's your own fault.

=head2 _build_nhash

=head2 _digest2path

=head2 _readfile

=head2 _writefile

=head1 BUGS

This does not provide any means to check for hash collisions.

You cannot provide a hashing algorithm that is not a Digest::* derivative.

=head1 SEE ALSO

File::HStore implements a similar idea.

=head1 AUTHOR

Peter Corlett <abuse@cabal.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Peter Corlett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

