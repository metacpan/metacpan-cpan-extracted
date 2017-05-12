#===============================================================================
#         FILE:  Games::Go::AGA::TDListDB
#     ABSTRACT:  an SQL object for holding AGA TDList data
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#      CREATED:  12/02/2010 08:51:22 AM PST
#===============================================================================

use 5.010;
use strict;
use warnings;

package Games::Go::AGA::TDListDB;

use open qw( :utf8 :std );  # UTF8 for all files and STDIO
use IO::Handle;     # for autoflush
use DBI;
use Readonly;
use Try::Tiny;
use POSIX ":sys_wait_h";
use LWP::UserAgent;
use LWP::Protocol::https;
use Games::Go::AGA::Parse::TDList;
use Games::Go::AGA::Parse::Util qw( is_Rating );
use Readonly;

our $VERSION = '0.048'; # VERSION

Readonly my $BUF_MAX  => 4096;

# list the names of the default database field index subroutines, in order
my @_column_names = (qw(
    last_name
    first_name
    id
    membership
    rank
    date
    club
    state
    extra
));
my %_column_idx = (
    last_name  => 0,
    first_name => 1,
    id         => 2,
    membership => 3,
    rank       => 4,
    date       => 5,
    club       => 6,
    state      => 7,
    extra      => 8,
);

# list of default column names
sub column_idx {
    my ($self, $which) = @_;

    if (@_ >= 2) {
        return $_column_idx{lc $which};
    }
    return wantarray
        ?  @_column_names
        : \@_column_names;
}

Readonly my @columns => (
    {last_name  => 'VARCHAR(256)',             },
    {first_name => 'VARCHAR(256)',             },
    {id         => 'VARCHAR(256) NOT NULL PRIMARY KEY', },
    {membership => 'VARCHAR(256)',             },
    {rank       => 'VARCHAR(256)',             },
    {date       => 'VARCHAR(256)',             },
    {club       => 'VARCHAR(256)',             },
    {state      => 'VARCHAR(256)',             },
    {extra      => 'VARCHAR(256)',             },
);

my %pre_defaults = (
    url                    => 'https://www.usgo.org/ratings/TDListN.txt',
    dbdname                => 'tdlistdb.sqlite',
    table_name             => 'tdlist',
    extra_columns          => [],
    extra_columns_callback => sub { return () },
    max_update_errors      => 10,
    raw_filename           => 'TDList.txt',
    verbose                => 0,
);

__PACKAGE__->run( @ARGV ) if not caller();  # modulino

sub new {
    my ($class, %args) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    while (my ($key, $value) = each %pre_defaults) {
        $value = delete $args{$key} if (exists $args{$key});
        $self->$key($value);
    }

    my $db = $self->db(delete $args{db});

    for my $key (keys %args) {  # any leftovers?
        $self->$key($args{$key});
    }

    # SQL for finding players by name
    $self->sth('select_by_name',
        $db->prepare(
            join('',
                'SELECT * FROM ',
                $self->table_name,
                ' WHERE last_name  = ?',
                ' AND   first_name = ?',
            ),
        ),
    );

    # and a statement for inserting new players
    $self->sth('insert_player',
        $db->prepare(
            join('',
                'INSERT INTO ',
                $self->table_name,
                ' ( ',
                    $self->sql_columns,
                ' ) ',
                'VALUES ( ',
                    $self->sql_insert_qs,
                ' )',
            ),
        ),
    );

    # SQL for updating when player is already in DB
    $self->sth('update_id',
        $db->prepare(
            join('',
                'UPDATE ',
                $self->table_name,
                ' SET ',
                $self->sql_update_qs,
                ' WHERE id = ?',
            ),
        ),
    );

    # SQL for finding IDs
    $self->sth('select_id',
        $db->prepare(
            join('',
                'SELECT * FROM ',
                $self->table_name,
                ' WHERE id = ?',
            ),
        ),
    );

    # SQL for getting and setting DB update time
    $self->sth('select_time',
        $db->prepare(
            join('',
                'SELECT update_time FROM ',
                $self->table_name_meta,
                ' WHERE key = 1',
            ),
        ),
    );
    $self->sth('update_time',
        $db->prepare(
            join('',
                'UPDATE ',
                $self->table_name_meta,
                ' SET update_time = ?',
                ' WHERE key = 1',
            ),
        ),
    );

    # SQL to get/set next_tmp marker
    $self->sth('select_next_tmp',
        $db->prepare(
            join('',
                'SELECT next_tmp_id FROM ',
                $self->table_name_meta,
                ' WHERE key = 1',
            ),
        ),
    );
    $self->sth('update_next_tmp',
        $db->prepare(
            join('',
                'UPDATE ',
                $self->table_name_meta,
                ' SET next_tmp_id = ?',
                ' WHERE key = 1',
            ),
        )
    );

    $self->init(\%args); # in case any subclass needs initialization

    map {
        if (not $self->can($_)) {
            my $ref = ref $self;
            confess("$ref can't '->$_'\n");
        }
        $self->$_($args{$_});
    } keys %args;

    return $self;
}

my $usage = qq(

TDListDB [ -tdlist_file filename ] [ -sqlite_file filename ]
         [ -url url | AGA ] [ -verbose ] [ -help ]

Options may be abbreviated to their first letter.

By default, TDListDB.pm updates from a file in the current
directory named TDList.txt.  Specify -tdlist_file to update
from a different file, or specify -url to update from a
website.  -url AGA updates from the usual AGA website at
    https://www.usgo.org/ratings/TDListN.txt

);

sub run {
    my ($class) = @_;

    require Getopt::Long;
    Getopt::Long->import(qw( :config pass_through ));

    my $verbose;
    my $url;
    exit 0 if (not GetOptions(
        'tdlist_file=s', => \$pre_defaults{raw_filename},   # update from file
        'sqlite_file=s', => \$pre_defaults{dbdname},        # sqlite file
        'url=s',         => \$url,                          # URL to update from
        'verbose',       => \$verbose,
        'help'           => sub { print $usage; exit 0; },
    ));

    my $tdlist = $class->new( verbose => $verbose );
    my $filename = $tdlist->raw_filename;
    my $dbfile = $tdlist->dbdname;
    STDOUT->autoflush(1);

    if ($url) {
        if (uc $url ne 'AGA') {
            $tdlist->url($url);
        }
        $url = $tdlist->url;
        print "Updating $dbfile from AGA ($url)\n";
        $tdlist->update_from_AGA();
        exit;
    }
    print "Updating $dbfile from file ($filename)\n";
    $tdlist->update_from_file($filename);
}

# stub for subclass to override
sub init {
    my ($self) = @_;
}

sub verbose {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{verbose} = $new;
    }

    return $self->{verbose};
}

sub raw_filename {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{raw_filename} = $new;
    }

    return $self->{raw_filename};
}

sub dbdname {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{dbdname} = $new;
    }

    return $self->{dbdname};
}

sub table_name {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{table_name} = $new;
    }

    return quotemeta $self->{table_name};
}

sub table_name_meta {
    my ($self) = @_;

    return $self->table_name . '_meta';
}

sub url {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{url} = $new;
    }

    return $self->{url};
}

sub background {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{background} = $new;
    }

    return $self->{background};
}

sub max_update_errors {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{max_update_errors} = $new;
    }

    return $self->{max_update_errors};
}

sub extra_columns_callback {
    my ($self, @new) = @_;

    if (@_ > 1) {
        if (ref $new[0] ne 'CODE') {
            $self->my_print("Must set a code-ref in extra_columns_callback\n");
            die;
        }
        $self->{extra_columns_callback} = $new[0];
    }
    return $self->{extra_columns_callback};
}

sub extra_columns {
    my ($self, @new) = @_;

    if (@_ > 1) {
        if (ref $new[0] eq 'ARRAY') {
            $self->{extra_columns} = $new[0];
        }
        else {
            $self->{extra_columns} = \@new;
        }
    }
    return wantarray ? @{$self->{extra_columns}} : $self->{extra_columns};
}

sub db {
    my ($self, $new) = @_;

    if (@_ > 1) {
        if (not $new) {
            if (my $fname = $self->dbdname) {
                $new = DBI->connect(          # connect to your database, create if needed
                    "dbi:SQLite:dbname=$fname", # DSN: dbi, driver, database file
                    "",                          # no user
                    "",                          # no password
                    {
                        AutoCommit => 1,
                        RaiseError => 1,         # complain if something goes wrong
                    },
                )
            }
            else {
                $self->my_print("No dbdname for SQLite file\n");
                die;
            }
        }
        $self->{db} = $new;
        $self->_db_schema();   # make sure table exists
    }

    return $self->{db};
}

# library of statement handles
sub sth {
    my ($self, $name, $new) = @_;

    if (not $name) {
        $self->my_print("Statement handle name is required\n");
        die;
    }
    if (@_ > 2) {
        $self->{sth}{$name} = $new;
    }

    my $sth = $self->{sth}{$name};
    if (not $sth) {
        $self->my_print("No statement handle called '$name'\n");
        die;
    }

    return $sth;
}

sub _db_schema {
    my ($self) = @_;

    $self->db->do(
        join('',
            'CREATE TABLE IF NOT EXISTS ',
            $self->table_name,
            ' (',
                $self->sql_column_types,
            ' )',
        ),
    );

    $self->db->do(join '',
        'CREATE TABLE IF NOT EXISTS ',
        $self->table_name_meta,
        ' (',
            'key         INTEGER PRIMARY KEY, ',
            'update_time VARCHAR(12), ',
            'next_tmp_id VARCHAR(12)',
        ' )',
    );

    $self->db->do(join '',
        'INSERT OR IGNORE INTO ',
        $self->table_name_meta,
        ' (',
            'key, ',
            'update_time, ',
            'next_tmp_id',
        ' ) VALUES ( 1, 0, 1 )',
    );
}

sub update_time {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->sth('update_time')->execute($new);
    }
    $self->sth('select_time')->execute();
    my $time = $self->sth('select_time')->fetchall_arrayref();
    $time = $time->[0][0];
    return $time || 0;
}

sub select_id {
    my ($self, $id) = @_;

    $self->sth('select_id')->execute($id);
    # ID is primary index, so can only be one - fetch into first array
    # element:
    my ($player) = $self->sth('select_id')->fetchall_arrayref;
    $player->[$self->column_idx('rank')] += 0 if (is_Rating($player->[$self->column_idx('rank')]));   # numify ratings
    return wantarray
        ? @{$player->[0]}
        : $player->[0];
}

sub insert_player {
    my ($self, @new) = @_;

    $new[$self->column_idx('id')] = $self->next_tmp_id(1) if (not $new[$self->column_idx('id')]);
    $self->sth('insert_player')->execute(@new);
    return wantarray
        ? @new
        : \@new;
}

sub next_tmp_id {
    my ($self, $used) = @_;

    $self->sth('select_next_tmp')->execute;
    my $next_tmp = $self->sth('select_next_tmp')->fetchall_arrayref;
    $next_tmp = $next_tmp->[0][0];
    $next_tmp ||= 1;
    while ($self->select_id("TMP$next_tmp")) {
        $next_tmp++
    }

    if ($used) {    # is the caller planning on allocating this one?
        $self->sth('update_next_tmp')->execute($next_tmp + 1);
    }
    return "TMP$next_tmp";
}

# reap any child zombies from earlier update_from_AGA calls
sub reap {
    my $kid;
    my $reaped = 0;
    do {
        $kid = waitpid(-1, WNOHANG);
        $reaped++ if ($kid > 0);
    } while $kid > 0;
    return $reaped;
}

sub update_from_AGA {
    my ($self) = @_;

    my $pid;
    if ($self->background) {
        $pid = fork;
        die "fork failed: $!\n" if not defined $pid;
    }
    if ($pid) {
        # parent process
        return;
    }

    if (not $self->{ua}) {
        $self->{ua} = LWP::UserAgent->new;
    }

    my $fname = $self->raw_filename;
    my $url = $self->url;
    $self->my_print("Starting $fname fetch from $url at ", scalar localtime, "\n") if ($self->verbose);
    $self->{ua}->mirror($url, $fname);
    $self->my_print("... fetch done at ", scalar localtime, "\n") if ($self->verbose);
    $self->update_from_file($fname);

    exit if (defined $pid); # exit if this is a spawned child ($pid == 0)
}

sub update_from_file {
    my ($self, $fh) = @_;

    if (not ref $fh) {
        my $fname = $fh;
        $fh = undef;
        if (not open($fh, '<', $fname)) {
            $self->my_print("Error opening $fname for reading: $!\n");
            die;
        }
    }
    $self->fh($fh);

    my $parser = Games::Go::AGA::Parse::TDList->new();
    my $verbose = $self->verbose;
    $self->my_print("Starting database update at ", scalar localtime, "\n") if ($verbose);
    $self->db->do('BEGIN');
    my $error_count = 0;
    my $ii = 0;
    my $ID = $self->column_idx('id');
    while (1) {
        $ii++;
        my $line = $self->next_line;
        last if (not defined $line);
        next if (not $line);

        if ($verbose) {
            $self->my_print('.')  if ($ii % 1000 == 0);
            $self->my_print("\n") if ($ii % 40000 == 0);
        }
        try {   # in case a line crashes, print error but continue
#$self->my_print("parse $line") if ($verbose);
            $parser->parse($line);
            my $update = $parser->as_array;
            if ($update->[$self->column_idx('last_name')] or $update->[$self->column_idx('first_name')]) {
                push @{$update}, $self->extra_columns_callback->($self, $update);
                if ($update->[$ID]) {
                    if ($update->[$ID] =~ m/tmp/i) {
                        die "TMP IDs not allowed in TDList input";
                    }
                }
                else {
                    $self->sth('select_by_name')->execute($update->[$self->column_idx('last_name')], $update->[$self->column_idx('first_name')]);
                    my $players = $self->sth('select_by_name')->fetchall_arrayref;
                    for my $player (@{$players}) {
                        if ($player->[$ID] =~ m/tmp/i) {
                            $update->[$ID] = $player->[$ID];  # already in DB (hope it's the same guy!)
                        }
                    }
                    if (not $update->[$ID]) {
                        $update->[$ID] = $self->next_tmp_id(1);
                    }
                }
                if ($self->select_id($update->[$ID])) {
                    # ID is already in database, do an update
                    $self->sth('update_id')->execute(
                        @{$update},     # new values for all columns
                        $update->[$ID],  # player ID (for WHERE condition)
                    );
                }
                else {
                    # ID is not in database, insert new record
                    $self->insert_player(@{$update});
                }
            }
            else {
                die "no name parsed from $line";
            }
        }
        catch {
            $error_count++;
            my $error = $_;
            $self->my_print("Error at line $ii: $error");
        };
        if ($error_count >= $self->max_update_errors) {
            $self->my_print("$error_count errors - aborting\n");
            last;
        }
    }
    $self->db->do('COMMIT');  # make sure we do this!
    $self->update_time(time);
}

# file might not have lines.  enforce lines here
sub next_line {
    my ($self) = @_;

    my $offset = $self->{buf_offset};
    if ($self->{buf_end} - $offset <= 160) {
        $self->get_fh_chunk;
        $offset = $self->{buf_offset};
    }
    return if ($offset >= $self->{buf_end});
    my $eol_idx;
    if ($self->{has_lines}) {
        $eol_idx = index($self->{buf}, "\n", $offset);
        if ($eol_idx < 0) {
            die "no EOL";       # shouldn't happen
        }
    }
    else {
        # assume 80 characters per line
        $eol_idx = $offset + 80;
        # but not past the end of the buffer
        $eol_idx = $self->{buf_end} if ($eol_idx > $self->{buf_end});
        $eol_idx--;
    }
    my $len = $eol_idx - $offset;
    my $line = substr $self->{buf}, $offset, $len;
    $self->{buf_offset} += $len + 1;
    return $line;
}

sub fh {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{fh} = $new;
        delete $self->{has_lines};
        if ($new and ref $new) {
            $self->{buf} = '';
            $self->{buf_offset} = $self->{buf_end} = 0;
            $self->get_fh_chunk;
            $self->{has_lines} = (index($self->{buf}, "\n") >= 0);
        }
    }
    return $self->{fh};
}

sub get_fh_chunk {
    my ($self) = @_;

    # how much is still left?
    my $left = $self->{buf_end} - $self->{buf_offset};
    # shift unused part of buf down to the beginning
    substr($self->{buf}, 0, $self->{buf_offset}, '');
    # read in a new chunk
    my $new = read $self->fh, $self->{buf}, $BUF_MAX - $left, $left;
    if (not defined $new) {
        die "Read error: $!";
    }
    $self->{buf_end} = $left + $new;
    $self->{buf_offset} = 0;
}

# sql columns (without column types)
sub sql_columns {
    my ($self, $joiner) = @_;

    $joiner = ', ' if (not defined $joiner);
    return join($joiner,
        map({ keys %{$_} }
            @columns,
            $self->extra_columns,
        ),
    );
}

# sql columns with column types
sub sql_column_types {
    my ($self, $joiner) = @_;

    $joiner = ', ' if (not defined $joiner);

    return join($joiner,
        map({join ' ', each %{$_}}
            @columns,
            $self->extra_columns,
        ),
    );
}

# '?, ' place-holder question marks for each column,
#    appropriate for an UPDATE or INSERT query
sub sql_update_qs {
    my ($self, $joiner) = @_;

    $joiner = ', ' if (not defined $joiner);

    return join($joiner,
        map({ (keys(%{$_}))[0] . ' = ?' }
            @columns,
            $self->extra_columns,
        ),
    );
}

# place-holder question marks for each column,
#    appropriate for an INSERT query
sub sql_insert_qs {
    my ($self, $joiner) = @_;

    $joiner = ', ' if (not defined $joiner);

    return join($joiner,
        map({ '?' }     # one question mark per column
            @columns,
            $self->extra_columns,
        ),
    );
}

sub my_print {
    my $self = shift;

    $self->print_cb->(@_);
}

sub print_cb {
    my ($self, $new) = @_;

    $self->{print_cb} = $new if (@_ > 1);
    return $self->{print_cb} || sub { print @_ };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::TDListDB - an SQL object for holding AGA TDList data

=head1 VERSION

version 0.048

=head1 SYNOPSIS

  use Games::Go::AGA::TDListDB;

=head1 DESCRIPTION

B<Games::Go::AGA::TDListDB> builds a database (SQLite by default) of
information from the TDList file provided by the American Go Association.

An update method is available that can reach out to the AGA website and
grab the latest TDList information.

=head2 Accessors

All of the B<options> listed under the B<new> method (below) may also be
used as accessors.

=head2 Methods

=over

=item $tdlist = Games::Go::AGA::TDListDB->new( [ %options ] );

Creates a new TdListDB object.  The following options may be supplied (and
may also be accessed via functions of the same name):

=over

=item db => $db

If B<$db> (a perl DBI object) is supplied, it is used as the database
object handle, otherwise an SQLite DBI handle is created and used.

The return value is the DBI object you want to use for regular database
operations, such as inserting, updating, etc.  However, see also the
predefined statement handles (B<tdlist-E<gt>sth> below), the statement you
need may already be there.

=item dbdname => 'path/to/filename'

This is the SQLite database filename used when no B<db> object is supplied
to B<new>.  If the file does not exist, it is created and populated.  The
default filename is 'tdlistdb.sqlite'.

=item max_update_errors => integer

An B<update_from_file> or B<update_from_AGA> counts errors until this
number is reached, at which point the update gives up and throws an
exception.  The default value is 10.

=item url => 'http://where.to.find.tdlist'

The URL to retrieve TDList from.  The default is
'http://www.usgo.org/ratings/TDListN.txt'.

=item raw_filename => 'TDList.txt'

When fetching from the AGA, the TDList data is dumped into this filename.
If this file already exists, and is not older than the data at the AGA, the
fetch is skipped (since the data should be the same - see perldoc
LWP::UserAgent B<mirror>).

=item background => true or false

When true, calls to B<update_from_AGA> will be run in the background in a
forked process.  When false, B<update_from_AGA> blocks until complete
(which could be several minutes).

NOTE: if B<background> is true, you should arrange to call the B<reap>
method periodically, or make other arrangements to remove zombies.

=item table_name => 'DB_table_name'

The name of the database table.  An additional table (retrievable with
the B<table_name_meta> read-only accessor) is also created to hold the
table's B<update_time> and B<next_tmp_id>.

When returning the table name, the value is always metaquoted.

The default table name is 'tdlistn'.

=item extra_columns => [ {column_name => column_TYPE}, ... ]

If you need extra columns in the database, add the names/column types here.
They are used only in the creation of the table schema if the database doesn't
already exist.  The default columns are:

    {last_name  => 'VARCHAR(256)'        },
    {first_name => 'VARCHAR(256)'        },
    {id         => 'INTEGER PRIMARY KEY' },
    {membership => 'VARCHAR(256)'        },
    {rank       => 'VARCHAR(256)'        },
    {date       => 'VARCHAR(256)'        },
    {club       => 'VARCHAR(256)'        },
    {state      => 'VARCHAR(256)'        },
    {extra      => 'VARCHAR(256)'        },

which are the columns found in TDList.txt from the AGA.  When defining
extra columns, take care to set a proper SQL column type and not to overlap
these existing names.

To fill in these extra columns, you might want to use:

=item extra_columns_callback => sub { ...; return @column_values; }

This callback is called for each record added (or updated) to the database
during B<update_from_AGA> or B<update_from_file>. It is called with the
object pointer, and a ref to an array containing the values of the default
columns as listed above.  It should return an array of the values for the
extra columns in the same order as given in B<extra_columns>.
Alternatively, it can directly append those values onto the passed in array
ref.

    extra_columns          => [ 'rank_range' ], # name(s) for the extra column(s)
    extra_columns_callback => sub {
        my ($self, $columns) = @_;
        # add extra column indicating Dan or kyu
        return '' if not $columns->[$self->column_idx('rank')];
        return 'Dan' if Rank_to_Rating( $columns->[$self->column_idx('rank')] ) > 0;
        return 'Kyu';
    }

This function should always return exactly the number of extra columns defined in
the extra_columns option - the returned value may be the empty string ('').

=item $tdlistdb->print_cb( [ \&callback ]

Set/get the print callback.  Whenever something is to be printed, the
B<callback> function is called with the print arguments.  B<callback>
defaults to the standard perl print function, and new B<callback> functions
should be written to take arguments the same way print does.

=back

=item $tdlistdb->my_print( @args )

Calls the B<my_print> B<callback> with B<@args>.

=item $tdlistdb->column_idx( [ 'name' ] )

When 'name' is defined, it is lower-cased, and the column index for 'name' (or undef
if 'name' isn't one of the default column names) is returned.

When 'name' is not provided, returns an array (or ref to array in scalar context) of
the default column names, in order.

These are the default columns by name:

=over

=item last_name

=item first_name

=item id

=item membership

=item rank

=item date

=item club

=item state

=item extra

=back

=item $tdlistdb->update_from_AGA( [ $force ] )

Reach out to the American Go Association (AGA) ratings web page and
grab the most recent TDList information.  Update the database.  May
throw an exception if the update fails for any of a number of reasons.

=item $tdlistdb->update_from_file( $file )

Updates the database from a file in TDList format.  Called by
B<update_from_AGA>.  B<$file> may be a file handle, or if it's a
string, it is the name of the file to open.  May throw an exception on
various file or formatting errors.

=item $sql = $tdlistdb->sql_columns( [ $joiner ])

Returns SQL suitable for the list of column names, separated by commas
(or something else if you set a B<$joiner>).  See INSERT and SELECT
queries.

=item $sql = $tdlistdb->sql_column_types( [ $joiner ])

Returns SQL suitable for the list of column names followed by the
column type, separated by commas (or something else if you set a
B<$joiner>).  See CREATE TABLE queries.

=item $sql = $tdlistdb->sql_update_qs( [ $joiner ])

Returns SQL suitable for the list of question-mark ('?') placeholders
for each column, separated by commas (or something else if you set a
B<$joiner>).  See UPDATE queries.

=item $sql = $tdlistdb->sql_insert_qs( [ $joiner ])

Returns SQL suitable for the list of "column = ?" placeholders,
separated by commas (or something else if you set a B<$joiner>).  See
INSERT queries.

=item $id = $tdlistdb->next_tmp_id( [ $used ] )

Returns the next available (unused) TMPnnnn temporary ID.  Setting
B<$used> to a true value indicates that this ID is being allocated.

=item $id = $tdlistdb->update_time( [ $seconds ] )

Get or set the time (in seconds) the database was last updated (via
B<update_from_AGA> or B<update_from_file>).

=item @player_fields = $tdlistdb->select_id( 'id_string' )

Returns the array (or ref to array in scalar context) of the player with ID
equal to 'id_string', or an empty array of 'id_string' is not found.

=item $sth = $tdlistdb->sth('handle_name', [ $DBI::sth ] )

B<Games::Go::AGA::TDListDB> maintains a small library of prepared DBI
statement handles, available by name.  You may add to the list, but
take care not to overwrite existing names if you want this module to
continue working correctly.  The predefined handles are:

=over

=item $tdlistdb->sth('select_by_name')->execute('last name', 'first name')

Find a player by last name and first name.  Note that the ID is the
'PRIMARY KEY' for the database, and that last and first names may not
be unique.

=item $tdlistdb->sth('insert_player')->execute(@new_column_values)

Add a new player to the database.  @new_column_values are values for all
the columns, both built-in and B<extra_columns>.

If the id column is non-true, this player is assigned an ID from
B<next_tmp_id>.

Returns the @new_column_values array (or a reference to it in scalar
context), with the new ID if it was set.

=item $tdlistdb->sth('update_id')->execute(@new_column_values, 'ID')

Update a player already in the database.  @new_column_values are values for
all the columns, both built-in and B<extra_columns>, and ID is the player's
unique ID.  Note that a new ID is also in the @new_column_values.  These
should differ only under exceptional circumstances, such as if a TMP player
gets a real AGA ID.

=item $tdlistdb->sth('select_id')->execute('ID');

Find a player by ID.  Note that the ID is the 'PRIMARY KEY' for the
database, so this query will return only one record.

=item $tdlistdb->sth('select_time')->execute();

Get the current database update time (but use B<update_time()> instead).

=item $tdlistdb->sth('update_time')->execute($new);

Set the current database update time (but use B<update_time($new)> instead).

=item $tdlistdb->sth('select_next_tmp')->execute;

Get the numeric part of the next TMP ID (but use B<next_tmp_id()> instead).

=item $tdlistdb->sth('update_next_tmp')->execute(integer);

Set the numeric part of the next TMP ID (but use B<next_tmp_id('use')> instead).

=item reap

Reaps zombies created when B<update_from_AGA> is called with B<background>
true (or any other zombies, for that matter).  This is a non-blocking call,
so it is safe to call periodically.

=back

=back

=head1 SEE ALSO

=over

=item Games::Go::AGA::Parse

Parsers for AGA format files.

=item Games::Go::Wgtd

Online go tournament system.

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
