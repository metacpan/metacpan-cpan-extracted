#!/usr/bin/perl

package KiokuDB::Backend::Files;
use Moose;

use Carp qw(croak);

use JSON;

use File::Spec;
use File::Path qw(remove_tree make_path);

use Directory::Transactional;

use Data::Stream::Bulk::Util qw(bulk);

use MooseX::Types::Path::Class qw(Dir File);

sub _file_to_id_stream; # cleanup

use namespace::clean -except => 'meta';

our $VERSION = "0.06";

with qw(
    KiokuDB::Backend
    KiokuDB::Backend::Serialize::Delegate
    KiokuDB::Backend::Role::Clear
    KiokuDB::Backend::Role::Scan
    KiokuDB::Backend::Role::Query::Simple::Linear
    KiokuDB::Backend::Role::TXN
    KiokuDB::Backend::Role::TXN::Nested
    KiokuDB::Backend::Role::Concurrency::POSIX
);

sub BUILD {
    my $self = shift;

    unless ( $self->create ) {
        my $dir = $self->dir;
        $dir->open || croak("$dir: $!");
    }
}

has dir => (
    isa => Dir,
    is  => "ro",
    required => 1,
    coerce   => 1,
);

has create => (
    isa => "Bool",
    is  => "ro",
    default => 0,
);

has object_dir => (
    isa => "Str",
    is  => "ro",
    default => "all",
);

has root_set_dir => (
    isa => "Str",
    is  => "ro",
    default => "root",
);

has trie => (
    isa => "Bool",
    is  => "ro",
    default => 0,
);

# how many hex nybbles per trie level
has trie_nybbles => (
    isa => "Int",
    is  => "rw",
    default => 3, # default 4096 entries per level
);

# /dec/afb/decafbad
has trie_levels => (
    isa => "Int",
    is  => "rw",
    default => 2,
);

has _txn_manager => (
    isa => "Directory::Transactional",
    is  => "ro",
    lazy_build => 1,
);

for (qw(nfs global_lock auto_commit)) {
    has $_ => (
        isa => "Bool",
        is  => "ro",
        predicate => "has_$_",
    );
}

sub _build__txn_manager {
    my $self = shift;

    Directory::Transactional->new(
        root => $self->dir,
        ( $self->has_nfs         ? ( nfs         => $self->nfs         ) : () ),
        ( $self->has_global_lock ? ( global_lock => $self->global_lock ) : () ),
        ( $self->has_auto_commit ? ( auto_commit => $self->auto_commit ) : () ),
    );
}

sub txn_do { shift->_txn_manager->txn_do(@_) }
sub txn_begin { shift->_txn_manager->txn_begin(@_) }
sub txn_commit { shift->_txn_manager->txn_commit(@_) }
sub txn_rollback { shift->_txn_manager->txn_rollback(@_) }

sub get {
    my ( $self, @uids ) = @_;

    my $t = $self->_txn_manager->_auto_txn;

    local $@;
    return eval { map { $self->get_entry($_) } @uids };
}

sub insert {
    my ( $self, @entries ) = @_;

    # in case we're not in a transaction, make sure it's scoped for the entire insert
    my $t = $self->_txn_manager->_auto_txn;

    # we sort so that locks are taken in a consistent order, reducing chance of deadlocks
    foreach my $entry ( sort { $a->id cmp $b->id } @entries ) {
        $self->insert_entry($entry);
    }
}

sub delete {
    my ( $self, @ids_or_entries ) = @_;

    my @uids = map { ref($_) ? $_->id : $_ } @ids_or_entries;

    my $t = $self->_txn_manager;

    my $g = $t->_auto_txn;

    foreach my $uid ( @uids ) {
        foreach my $file ( $self->object_file($uid), $self->root_set_file($uid) ) {
            $t->unlink($file);
        }
    }

    return;
}

sub exists {
    my ( $self, @uids ) = @_;

    my $t = $self->_txn_manager;

    my $g = $t->_auto_txn;

    map { $t->exists($self->object_file($_)) } @uids;
}

sub get_entry {
    my ( $self, $uid ) = @_;

    my $fh = $self->open_entry($uid);

    return $self->serializer->deserialize_from_stream($fh);
}

sub open_entry {
    my ( $self, $id ) = @_;

    $self->_txn_manager->openr( $self->object_file($id) );
}

sub insert_entry {
    my ( $self, $entry ) = @_;

    my $id = $entry->id;

    my $file = $self->object_file($id);

    my $t = $self->_txn_manager;

    $t->lock_path_write($file);

    if ( not($entry->has_prev) and $t->exists($file) ) {
        # this is a new entry
        croak "Entry $id already exists";
    }

    my $fh = $t->openw($file);

    $self->serializer->serialize_to_stream($fh, $entry);

    close $fh || croak "Couldn't store: $!";

    my $root_file = $self->root_set_file($id);

    if ( $entry->root ) {
        # just create a file with the same name... this used to be a hardlink
        # but that doesn't play nice with Directory::Transactional
        # maybe it will return eventually
        $t->openw($root_file);
    } else {
        $t->unlink($root_file);
    }
}

sub _trie_path {
    my ( $self, @path ) = @_;

    return File::Spec->catfile(@path) unless $self->trie;

    my $uid = pop @path;

    my $id_hex = unpack("H*", $uid);

    my $nyb = $self->trie_nybbles;

    for ( 1 .. $self->trie_levels ) {
        push @path, substr($id_hex, 0, $nyb, '');
    }

    File::Spec->catfile( @path, $uid );
}

sub object_file {
    my ( $self, $uid ) = @_;

    $self->_trie_path( $self->object_dir, $uid);
}

sub root_set_file {
    my ( $self, $uid ) = @_;

    $self->_trie_path( $self->root_set_dir, $uid );
}

sub clear {
    my $self = shift;

    my $m = $self->_txn_manager;

    my $stream = $m->file_stream( only_files => 1 );

    while ( my $block = $stream->next ) {
        $m->unlink($_) for @$block;
    }
}

sub all_entry_files {
    my $self = shift;

    $self->_txn_manager->file_stream( only_files => 1, dir => $self->object_dir );
}

sub root_entry_files {
    my $self = shift;

    $self->_txn_manager->file_stream( only_files => 1, dir => $self->root_set_dir );
}

sub _file_to_id_stream {
    my $stream = shift;

    $stream->filter(sub {[
        map {
            my ( undef, undef, $file ) = File::Spec->splitpath($_);
            $file;
        } @$_
    ]});
}

sub all_entry_ids {
    my $self = shift;

    _file_to_id_stream($self->all_entry_files);
}

sub root_entry_ids {
    my $self = shift;

    _file_to_id_stream($self->root_entry_files);
}

sub all_entries {
    my $self = shift;

    my $ser = $self->serializer;
    my $t = $self->_txn_manager;

    my $stream = $self->all_entry_files;

    $stream->filter(sub { [ map { $ser->deserialize_from_stream($t->openr($_)) } @$_ ]});
}

# FIXME when we're no longer using empty files this should be fixed
sub root_entries {
    my $self = shift;
    $self->root_entry_ids->filter(sub{[ $self->get(@$_) ]});
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuDB::Backend::Files - One file per object backend

=head1 SYNOPSIS

    KiokuDB->connect(
        "files:dir=path/to/data",
        serializer => "yaml", # defaults to storable
    );

=head1 DESCRIPTION

This backend provides a file based backend using L<Directory::Transactional> to
provide ACID semantics.

This is one of the slower backends, and the support for searching is very
limited (only a linear scan is supported), but it is suitable for small, simple
projects.

=head1 ATTRIBUTES

=over 4

=item dir

The directory for the backend.

=item create

If true (defaults to false) the directories will be created at instantiation time.

=item object_dir

Defaults to C<all>.

=item root_set_dir

Defaults C<root>.

Root set entries are symlinked into this directory as well.

=item trie

If true (defaults to false) instead of one flat hierarchy, the files will be
put in subdirectories based on their IDs. This is useful if your file system is
limited and you have lots of entries in the database.

=item trie_nybbles

How many hex nybbles to take off of the ID. Defaults to 3, which means up to
4096 subdirectories per directory.

=item trie_levels

How many subdirectories to use.

Defaults to 2.

=back

=head1 VERSION CONTROL

L<http://github.com/nothingmuch/kiokudb-backend-files>

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

    Copyright (c) 2008, 2009 Yuval Kogman, Infinity Interactive. All
    rights reserved This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut
