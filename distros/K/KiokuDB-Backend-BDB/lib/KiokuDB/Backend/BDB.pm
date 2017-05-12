#!/usr/bin/perl

package KiokuDB::Backend::BDB;
use Moose;

use Carp qw(croak);

use Scalar::Util qw(weaken);
use MooseX::Types::Path::Class qw(Dir);

use BerkeleyDB qw(DB_NOOVERWRITE DB_KEYEXIST DB_NOTFOUND);

use KiokuDB::Backend::BDB::Manager;

use namespace::clean -except => 'meta';

# TODO use a secondary DB to keep track of the root set
# integrate with the Search::GIN bdb backend for additional secondary indexing

# this will require storing GIN extracted data in the database, too

# also port Search::GIN's Data::Stream::Bulk/BDB cursor code
# this should be generic (work with both c_get and c_pget, and the various
# flags)

our $VERSION = "0.15";

with qw(
    KiokuDB::Backend
    KiokuDB::Backend::Serialize::Delegate
    KiokuDB::Backend::Role::Clear
    KiokuDB::Backend::Role::TXN
    KiokuDB::Backend::Role::TXN::Nested
    KiokuDB::Backend::Role::Scan
    KiokuDB::Backend::Role::Query::Simple::Linear
    KiokuDB::Backend::Role::Concurrency::POSIX
);

has manager => (
    isa => "KiokuDB::Backend::BDB::Manager",
    is  => "ro",
    coerce => 1,
    required => 1,
    #handles => "KiokuDB::Backend::TXN",
);

sub new_from_dsn_params {
    my ( $self, %args ) = @_;

    my %manager = %args;

    if ( my $dir = delete $args{dir} ) {
        $manager{home} = $dir;
    }

    $self->new(manager => \%manager, %args);
}

sub txn_begin { shift->manager->txn_begin(@_) }
sub txn_commit { shift->manager->txn_commit(@_) }
sub txn_rollback { shift->manager->txn_rollback(@_) }
sub txn_do { shift->manager->txn_do(@_) }

has primary_db => (
    is      => 'ro',
    isa     => 'Object',
    lazy_build => 1,
);

sub BUILD { shift->primary_db } # early

sub _build_primary_db {
    my $self = shift;

    $self->manager->open_db("objects", class => "BerkeleyDB::Hash");
}

sub delete {
    my ( $self, @ids_or_entries ) = @_;

    my @uids = map { ref($_) ? $_->id : $_ } @ids_or_entries;

    my $primary_db = $self->primary_db;
    foreach my $id ( @uids ) {
        if ( my $ret = $primary_db->db_del($id) ) {
            die $ret;
        }
    }

    return;
}

sub insert {
    my ( $self, @entries ) = @_;

    my $primary_db = $self->primary_db;

    foreach my $entry ( @entries ) {
        my $ret = $primary_db->db_put(
            $entry->id => $self->serialize($entry),
            ( $entry->has_prev ? () : DB_NOOVERWRITE ),
        );

        if ( $ret ) {
            if ( $ret == DB_KEYEXIST ) {
                croak "Entry " . $entry->id . " already exists in the database";
            } else {
                die $ret;
            }
        }
    }
}

sub get {
    my ( $self, @uids ) = @_;

    my ( $var, @ret );

    my $primary_db = $self->primary_db;

    foreach my $uid ( @uids ) {
        my $ret = $primary_db->db_get($uid, $var);
        if ( $ret == 0 ) {
            push @ret, $var;
        } elsif ( $ret == DB_NOTFOUND ) {
            return;
        } else {
            die $ret;
        }
    }

    return map { $self->deserialize($_) } @ret;
}

sub exists {
    my ( $self, @ids ) = @_;

    my $primary_db = $self->primary_db;

    my $v;

    my @exists;

    foreach my $id ( @ids ) {
        my $ret = $primary_db->db_get($id, $v);

        if ( $ret == 0 ) {
            push @exists, 1;
        } elsif ( $ret == DB_NOTFOUND ) {
            push @exists, 0;
        } else {
            die $ret;
        }
    }

    return @exists;
}

sub clear {
    my $self = shift;

    my $count = 0;

    $self->primary_db->truncate($count);

    return $count;
}

sub all_entries {
    my $self = shift;

    $self->manager->cursor_stream(
        db => $self->primary_db,
        values => 1,
    )->filter(sub {[ map { $self->deserialize($_) } @$_ ]});
}

sub all_entry_ids {
    my $self = shift;

    $self->manager->cursor_stream(
        db => $self->primary_db,
        keys => 1,
    );
}

# sub root_entries { } # secondary index?

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuDB::Backend::BDB - L<BerkeleyDB> backend for L<KiokuDB>.

=head1 SYNOPSIS

    KiokuDB->connect( "bdb:dir=/path/to/storage", create => 1 );

=head1 DESCRIPTION

This is a L<BerkeleyDB> based backend for L<KiokuDB>.

It is the best performing backend for most tasks, and is very feature complete
as well.

The L<KiokuDB::Backend::BDB::GIN> subclass provides searching support using
L<Search::GIN>.

=head1 ATTRIBUTES

=over 4

=item manager

The L<BerkeleyDB::Manager> instance that opens up the L<BerkeleyDB> databases.

This will be coerced from a hash reference too, so you can do something like:

    KiokuDB::Backend::BDB->new(
        manager => {
            home => "/path/to/storage",
            create => 1,
            transactions => 0,
        },
    );

to control the various parameters.

WHen using C<connect> all the parameters are passed through to the manager as
well:

    KiokuDB->connect(
        'bdb:dir=foo',
        create => 1,
        transactions => 0,
    );

=head1 LOG FILES AND BACKUPS

Berkeley DB has extensive support for backup archival and recovery.

Unfortunately the default settings also mean that log files accumilate unless
they are cleaned up.

If you are interested in creating backups look into the C<db_hotback> or
C<db_archive> utilities.

=head2 Using BerkeleyDB's backup/recovery facilities

Read the Berkeley DB documentation on recovery procedures:
L<http://www.oracle.com/technology/documentation/berkeley-db/db/ref/transapp/recovery.html>

Depending on what type of recovery scenarios you wish to protect yourself from,
set up some sort of cron script to routinely back up the data.

=head3 Checkpointing

In order to properly back up the directory log files need to be checkpointed.
Otherwise log files remain in use if the environment is still open and cannot
be backed up.

L<BerkeleyDB::Manager> sets C<auto_checkpoint> by default, causing checkpoints
to happen if enough data has been written after every top level C<txn_commit>.

You can disable that flag and run the C<db_checkpoint> utility from cron, or
let it run in the background.

More information about checkpointing can be found here:
L<http://www.oracle.com/technology/documentation/berkeley-db/db/ref/transapp/checkpoint.html>

Information about the C<db_checkpoint> utility can be found here:
L<http://www.oracle.com/technology/documentation/berkeley-db/db/utility/db_checkpoint.html>

=head3 C<db_archive>

C<db_archive> can be used to list unused log files. You can copy these log
files to backup media and then remove them.

L<http://www.oracle.com/technology/documentation/berkeley-db/db/utility/db_archive.html>

Using C<db_archive> and cleaning files yourself is recommended for catastrophic
recovery purposes.

=head3 C<db_hotbackup>

If catastrophic recovery protection is not necessary you can create hot
backups instead of full ones.

Running the following command from cron is an easy way to have maintain a
backup directory with and clean your log files:

    db_hotbackup -h /path/to/storage -b /path/to/backup -u -c

This command will checkpoint the logs, and then copy or move all the files to
the backup directory, overwriting previous copies of the logs in that
directory. Then it runs C<db_recover> in catastrophic recovery mode in the
backup directory, bringing the data up to date.

This is essentially C<db_checkpoint>, C<db_archive> and log file cleanup all
rolled into one command. You can write your own hot backup utililty using
C<db_archive> and C<db_recover> if you want catastrophic recovery ability.

L<http://www.oracle.com/technology/documentation/berkeley-db/db/utility/db_hotbackup.html>

=head2 Automatically cleaning up log files

If you don't need recovery support at all you can specify C<log_auto_remove> to
L<BerkeleyDB::Manager>

    KiokuDB->connect( "bdb:dir=foo", log_auto_remove => 1 );

This instructs Berkeley DB to clean any log files that are no longer in use in
an active transaction. Backup snapshots can still be made but catastrophic
recovery is impossilbe.

=back

=head1 VERSION CONTROL

L<http://github.com/nothingmuch/kiokudb-backend-bdb>

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

    Copyright (c) 2008, 2009 Yuval Kogman, Infinity Interactive. All
    rights reserved This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut

