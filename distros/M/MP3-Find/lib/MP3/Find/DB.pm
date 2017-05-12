package MP3::Find::DB;

use strict;
use warnings;

use base qw(MP3::Find::Base);
use Carp;

use DBI;
use SQL::Abstract;

use MP3::Find::Util qw(get_mp3_metadata);

my $sql = SQL::Abstract->new;

my @COLUMNS = (
    [ mtime        => 'INTEGER' ],  # filesystem mtime, so we can do incremental updates
    [ FILENAME     => 'TEXT' ], 
    [ TITLE        => 'TEXT' ], 
    [ ARTIST       => 'TEXT' ], 
    [ ALBUM        => 'TEXT' ],
    [ YEAR         => 'INTEGER' ], 
    [ COMMENT      => 'TEXT' ], 
    [ GENRE        => 'TEXT' ], 
    [ TRACKNUM     => 'INTEGER' ], 
    [ VERSION      => 'NUMERIC' ],
    [ LAYER        => 'INTEGER' ], 
    [ STEREO       => 'TEXT' ],
    [ VBR          => 'TEXT' ],
    [ BITRATE      => 'INTEGER' ], 
    [ FREQUENCY    => 'INTEGER' ], 
    [ SIZE         => 'INTEGER' ], 
    [ OFFSET       => 'INTEGER' ], 
    [ SECS         => 'INTEGER' ], 
    [ MM           => 'INTEGER' ],
    [ SS           => 'INTEGER' ],
    [ MS           => 'INTEGER' ], 
    [ TIME         => 'TEXT' ],
    [ COPYRIGHT    => 'TEXT' ], 
    [ PADDING      => 'INTEGER' ], 
    [ MODE         => 'INTEGER' ],
    [ FRAMES       => 'INTEGER' ], 
    [ FRAME_LENGTH => 'INTEGER' ], 
    [ VBR_SCALE    => 'INTEGER' ],
);

my $DEFAULT_STATUS_CALLBACK = sub {
    my ($action_code, $filename) = @_;
    print STDERR "$action_code $filename\n";
};

=head1 NAME

MP3::Find::DB - SQLite database backend to MP3::Find

=head1 SYNOPSIS

    use MP3::Find::DB;
    my $finder = MP3::Find::DB->new;
    
    my @mp3s = $finder->find_mp3s(
        dir => '/home/peter/music',
        query => {
            artist => 'ilyaimy',
            album  => 'myxomatosis',
        },
        ignore_case => 1,
        db_file => 'mp3.db',
    );
    
    # you can do things besides just searching the database
    
    # create another database
    $finder->create({ db_file => 'my_mp3s.db' });
    
    # update the database by searching the filesystem
    $finder->update({
	db_file => 'my_mp3s.db',
	dirs => ['/home/peter/mp3', '/home/peter/cds'],
    });

    # or just update specific mp3s
    $finder->update({
	db_file => 'my_mp3s.db',
	files => \@filenames,
    });
    
    # and then blow it away
    $finder->destroy_db('my_mp3s.db');

=head1 REQUIRES

L<DBI>, L<DBD::SQLite>, L<SQL::Abstract>

=head1 DESCRIPTION

This is the database backend for L<MP3::Find>. The easiest way to
use it is with a SQLite database, but you can also pass in your own
DSN or database handle.

The database you use should have at least one table named C<mp3> with 
the following schema:

    CREATE TABLE mp3 (
        mtime         INTEGER,
        FILENAME      TEXT, 
        TITLE         TEXT, 
        ARTIST        TEXT, 
        ALBUM         TEXT,
        YEAR          INTEGER, 
        COMMENT       TEXT, 
        GENRE         TEXT, 
        TRACKNUM      INTEGER, 
        VERSION       NUMERIC,
        LAYER         INTEGER, 
        STEREO        TEXT,
        VBR           TEXT,
        BITRATE       INTEGER, 
        FREQUENCY     INTEGER, 
        SIZE          INTEGER, 
        OFFSET        INTEGER, 
        SECS          INTEGER, 
        MM            INTEGER,
        SS            INTEGER,
        MS            INTEGER, 
        TIME          TEXT,
        COPYRIGHT     TEXT, 
        PADDING       INTEGER, 
        MODE          INTEGER,
        FRAMES        INTEGER, 
        FRAME_LENGTH  INTEGER, 
        VBR_SCALE     INTEGER
    );

B<Note:> I'm still working out some kinks in here, so this backend
is currently not as stable as the Filesystem backend. Expect API
fluctuations for now.

B<Deprecated Methods:> C<create_db>, C<update_db>, C<sync_db>, and
C<destroy_db> have been deprecated in this release, and will be 
removed in a future release. Please switch to the new methods C<create>,
C<update>, C<sync>, and C<destory>.

=head2 Special Options

When using this backend, provide one of the following additional options
to the C<search> method:

=over

=item C<dsn>, C<username>, C<password>

A custom DSN and (optional) username and password. This gets passed
to the C<connect> method of L<DBI>.

=item C<dbh>

An already created L<DBI> database handle object.

=item C<db_file>

The name of the SQLite database file to use.

=back

=cut

# get a database handle from named arguments
sub _get_dbh {
    my $args = shift;

    # we got an explicit $dbh object
    return $args->{dbh} if defined $args->{dbh};

    # or a custom DSN
    if (defined $args->{dsn}) {
    	my $dbh = DBI->connect(
	    $args->{dsn}, 
	    $args->{username}, 
	    $args->{password}, 
	    { RaiseError => 1 },
	);
	return $dbh;
    }
    
    # default to a SQLite database
    if (defined $args->{db_file}) {
	my $dbh = DBI->connect(
	    "dbi:SQLite:dbname=$$args{db_file}",
	    '',
	    '',
	    { RaiseError => 1 },
	);
	return $dbh;
    }

    return;
}

sub _sqlite_workaround {
    # as a workaround for the 'closing dbh with active staement handles warning
    # (see http://rt.cpan.org/Ticket/Display.html?id=9643#txn-120724)
    foreach (@_) {
        $_->{RaiseError} = 0;  # don't die on error
        $_->{PrintError} = 0;  # ...and don't even say anything
        $_->{Active} = 1;
        $_->finish;
    }
}
 
=head1 METHODS

=head2 new

    my $finder = MP3::Find::DB->new(
        status_callback => \&callback,
    );

The C<status_callback> gets called each time an entry in the
database is added, updated, or deleted by the C<update> and
C<sync> methods. The arguments passed to the callback are
a status code (A, U, or D) and the filename for that entry.
The default callback just prints these to C<STDERR>:

    sub default_callback {
        my ($status_code, $filename) = @_;
        print STDERR "$status_code $filename\n";
    }

To suppress any output, set C<status_callback> to an empty sub:

    status_callback => sub {}

=head2 create

    $finder->create({
	dsn => 'dbi:SQLite:dbname=mp3.db',
	dbh => $dbh,
	db_file => 'mp3.db',
    });

Creates a new table for storing mp3 info in the database. You can provide
either a DSN (plus username and password, if needed), an already created
database handle, or just the name of an SQLite database file.

=cut

sub create {
    my $self = shift;
    my $args = shift;

    my $dbh = _get_dbh($args) or croak "Please provide a DBI database handle, DSN, or SQLite database filename";
    
    my $create = 'CREATE TABLE mp3 (' . join(',', map { "$$_[0] $$_[1]" } @COLUMNS) . ')';
    $dbh->do($create);
}

=head2 create_db (DEPRECATED)

    $finder->create_db($db_filename);

Creates a SQLite database in the file named C<$db_filename>.

=cut

# TODO: extended table for ID3v2 data
sub create_db {
    my $self = shift;
    my $db_file = shift or croak "Need a name for the database I'm about to create";
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '', {RaiseError => 1});
    my $create = 'CREATE TABLE mp3 (' . join(',', map { "$$_[0] $$_[1]" } @COLUMNS) . ')';
    $dbh->do($create);
}

=head2 update

    my $count = $finder->update({
	dsn   => 'dbi:SQLite:dbname=mp3.db',
	files => \@filenames,
	dirs  => \@dirs,
    });

Compares the files in the C<files> list plus any MP3s found by searching
in C<dirs> to their records in the database pointed to by C<dsn>. If the
files found have been updated since they have been recorded in the database
(or if they are not in the database), they are updated (or added).

Instead of a C<dsn>, you can also provide either an already created
database handle as C<dbh> or the filename of an SQLite database as C<db_file>.

=cut

# this is update_db and update_files (from Matt Dietrich) rolled into one
sub update {
    my $self = shift;
    my $args = shift;

    my $dbh = _get_dbh($args) or croak "Please provide a DBI database handle, DSN, or SQLite database filename";

    my @dirs  = $args->{dirs}
		    ? ref $args->{dirs} eq 'ARRAY'
			? @{ $args->{dirs} }
			: ($args->{dirs})
		    : ();

    my @files  = $args->{files}
		    ? ref $args->{files} eq 'ARRAY' 
			? @{ $args->{files} }
			: ($args->{files})
		    : ();
    
    my $status_callback = $self->{status_callback} || $DEFAULT_STATUS_CALLBACK;

    my $mtime_sth = $dbh->prepare('SELECT mtime FROM mp3 WHERE FILENAME = ?');
    my $insert_sth = $dbh->prepare(
        'INSERT INTO mp3 (' . 
            join(',', map { $$_[0] } @COLUMNS) .
        ') VALUES (' .
            join(',', map { '?' } @COLUMNS) .
        ')'
    );
    my $update_sth = $dbh->prepare(
        'UPDATE mp3 SET ' . 
            join(',', map { "$$_[0] = ?" } @COLUMNS) . 
        ' WHERE FILENAME = ?'
    );
    
    my $count = 0;  # the number of records added or updated
    my @mp3s;       # metadata for mp3s found

    # look for mp3s using the filesystem backend if we have dirs to search in
    if (@dirs) {
	require MP3::Find::Filesystem;
	my $finder = MP3::Find::Filesystem->new;
	unshift @mp3s, $finder->find_mp3s(dir => \@dirs, no_format => 1);
    }

    # get the metadata on specific files
    unshift @mp3s, map { get_mp3_metadata({ filename => $_ }) } @files;

    # check each file against its record in the database
    for my $mp3 (@mp3s) {	
        # see if the file has been modified since it was first put into the db
        $mp3->{mtime} = (stat($mp3->{FILENAME}))[9];
        $mtime_sth->execute($mp3->{FILENAME});
        my $records = $mtime_sth->fetchall_arrayref;
        
        warn "Multiple records for $$mp3{FILENAME}\n" if @$records > 1;
        
        if (@$records == 0) {
	    # we are adding a record
            $insert_sth->execute(map { $mp3->{$$_[0]} } @COLUMNS);
            $status_callback->(A => $$mp3{FILENAME});
            $count++;
        } elsif ($mp3->{mtime} > $$records[0][0]) {
            # the mp3 file is newer than its record
            $update_sth->execute((map { $mp3->{$$_[0]} } @COLUMNS), $mp3->{FILENAME});
            $status_callback->(U => $$mp3{FILENAME});
            $count++;
        }
    }
    
    # SQLite buggy driver
    _sqlite_workaround($mtime_sth, $insert_sth, $update_sth);
     
    return $count;
}

=head2 update_db (DEPRECATED)

    my $count = $finder->update_db($db_filename, \@dirs);

Searches for all mp3 files in the directories named by C<@dirs>
using L<MP3::Find::Filesystem>, and adds or updates the ID3 info
from those files to the database. If a file already has a record
in the database, then it will only be updated if it has been modified
since the last time C<update_db> was run.

=cut

sub update_db {
    my $self = shift;
    my $db_file = shift or croak "Need the name of the database to update";
    my $dirs = shift;
    
    my $status_callback = $self->{status_callback} || $DEFAULT_STATUS_CALLBACK;
    
    my @dirs = ref $dirs eq 'ARRAY' ? @$dirs : ($dirs);
    
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '', {RaiseError => 1});
    my $mtime_sth = $dbh->prepare('SELECT mtime FROM mp3 WHERE FILENAME = ?');
    my $insert_sth = $dbh->prepare(
        'INSERT INTO mp3 (' . 
            join(',', map { $$_[0] } @COLUMNS) .
        ') VALUES (' .
            join(',', map { '?' } @COLUMNS) .
        ')'
    );
    my $update_sth = $dbh->prepare(
        'UPDATE mp3 SET ' . 
            join(',', map { "$$_[0] = ?" } @COLUMNS) . 
        ' WHERE FILENAME = ?'
    );
    
    # the number of records added or updated
    my $count = 0;
    
    # look for mp3s using the filesystem backend
    require MP3::Find::Filesystem;
    my $finder = MP3::Find::Filesystem->new;
    for my $mp3 ($finder->find_mp3s(dir => \@dirs, no_format => 1)) {
        # see if the file has been modified since it was first put into the db
        $mp3->{mtime} = (stat($mp3->{FILENAME}))[9];
        $mtime_sth->execute($mp3->{FILENAME});
        my $records = $mtime_sth->fetchall_arrayref;
        
        warn "Multiple records for $$mp3{FILENAME}\n" if @$records > 1;
        
        if (@$records == 0) {
            $insert_sth->execute(map { $mp3->{$$_[0]} } @COLUMNS);
            $status_callback->(A => $$mp3{FILENAME});
            $count++;
        } elsif ($mp3->{mtime} > $$records[0][0]) {
            # the mp3 file is newer than its record
            $update_sth->execute((map { $mp3->{$$_[0]} } @COLUMNS), $mp3->{FILENAME});
            $status_callback->(U => $$mp3{FILENAME});
            $count++;
        }
    }
    
    # SQLite buggy driver
    _sqlite_workaround($mtime_sth, $insert_sth, $update_sth);
    
    return $count;
}

=head2 sync

    my $count = $finder->sync({ dsn => $DSN });

Removes entries from the database that refer to files that no longer
exist in the filesystem. Returns the count of how many records were
removed.

=cut

sub sync {
    my $self = shift;
    my $args = shift;

    my $dbh = _get_dbh($args) or croak "Please provide a DBI database handle, DSN, or SQLite database filename";
    
    my $status_callback = $self->{status_callback} || $DEFAULT_STATUS_CALLBACK;

    my $select_sth = $dbh->prepare('SELECT FILENAME FROM mp3');
    my $delete_sth = $dbh->prepare('DELETE FROM mp3 WHERE FILENAME = ?');
    
    # the number of records removed
    my $count = 0;
    
    $select_sth->execute;
    while (my ($filename) = $select_sth->fetchrow_array) {
        unless (-e $filename) {
            $delete_sth->execute($filename);
            $status_callback->(D => $filename);
            $count++;
        }
    }
    
    # SQLite buggy driver
    _sqlite_workaround($select_sth, $delete_sth);
    
    return $count;    
}

=head2 sync_db (DEPRECATED)

    my $count = $finder->sync_db($db_filename);

Removes entries from the database that refer to files that no longer
exist in the filesystem. Returns the count of how many records were
removed.

=cut

sub sync_db {
    my $self = shift;
    my $db_file = shift or croak "Need the name of the databse to sync";

    my $status_callback = $self->{status_callback} || $DEFAULT_STATUS_CALLBACK;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", '', '', {RaiseError => 1});
    my $select_sth = $dbh->prepare('SELECT FILENAME FROM mp3');
    my $delete_sth = $dbh->prepare('DELETE FROM mp3 WHERE FILENAME = ?');
    
    # the number of records removed
    my $count = 0;
    
    $select_sth->execute;
    while (my ($filename) = $select_sth->fetchrow_array) {
        unless (-e $filename) {
            $delete_sth->execute($filename);
            $status_callback->(D => $filename);
            $count++;
        }
    }
    
    return $count;    
}

=head2 destroy

    $finder->destroy({ db_file => $filename });

Permanantly removes the database. Unlike the other utility methods,
this one can only act on SQLite C<db_file> filenames, and not DSNs
or database handles.

=cut

sub destroy {
    my $self = shift;
    my $args = shift;

    # XXX: this method only knows how to deal with SQLite files;
    # is there a way to DROP a database given a $dbh?

    my $db_file = $args->{db_file} or croak "Need a db_file argument";

    # actually delete the thing
    unlink $db_file;
}

=head2 destroy_db (DEPRECATED)

    $finder->destroy_db($db_filename);

Permanantly removes the database.

=cut

sub destroy_db {
    my $self = shift;
    my $db_file = shift or croak "Need the name of a database to destroy";
    unlink $db_file;
}


sub search {
    my $self = shift;
    my ($query, $dirs, $sort, $options) = @_;
    
    croak 'Need a database name to search (set "db_file" in the call to find_mp3s)' unless $$options{db_file};
    
    my $dbh = _get_dbh($options);
    
    # use the 'LIKE' operator to ignore case
    my $op = $$options{ignore_case} ? 'LIKE' : '=';
    
    # add the SQL '%' wildcard to match substrings
    unless ($$options{exact_match}) {
        for my $value (values %$query) {
            $value = [ map { "%$_%" } @$value ];
        }
    }

    my ($where, @bind) = $sql->where(
        { map { $_ => { $op => $query->{$_} } } keys %$query },
        ( @$sort ? [ map { uc } @$sort ] : () ),
    );
    
    my $select = "SELECT * FROM mp3 $where";
    
    my $sth = $dbh->prepare($select);
    $sth->execute(@bind);
    
    my @results;
    while (my $row = $sth->fetchrow_hashref) {
        push @results, $row;
    }
    
    return @results;
}

# module return
1;

=head1 TODO

Store/search ID3v2 tags

Driver classes to handle database dependent tasks?

=head1 SEE ALSO

L<MP3::Find>, L<MP3::Find::Filesystem>, L<mp3db>

=head1 AUTHOR

Peter Eichman <peichman@cpan.org>

=head1 THANKS

Thanks to Matt Dietrich <perl@rainboxx.de> for suggesting having an 
option to just update specific files instead of doing a (longer) full
search.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 by Peter Eichman. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
