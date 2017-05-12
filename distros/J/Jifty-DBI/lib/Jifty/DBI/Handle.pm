package Jifty::DBI::Handle;
use strict;
use Carp               ();
use DBI                ();
use Class::ReturnValue ();
use Encode             ();

use base qw/Jifty::DBI::HasFilters/;

use vars qw(%DBIHandle $PrevHandle $DEBUG $TRANSDEPTH);

$TRANSDEPTH = 0;

our $VERSION = '0.01';

if ( my $pattern = $ENV{JIFTY_DBQUERY_CALLER} ) {
    require Hook::LexWrap;
    Hook::LexWrap::wrap(
        'Jifty::DBI::Handle::simple_query',
        pre => sub {
            return unless $_[1] =~ m/$pattern/;
            Carp::cluck($_[1] . '   ' . CORE::join( ',', @_[ 2 .. $#_ ] ));
        }
    );
}

=head1 NAME

Jifty::DBI::Handle - Perl extension which is a generic DBI handle

=head1 SYNOPSIS

  use Jifty::DBI::Handle;

  my $handle = Jifty::DBI::Handle->new();
  $handle->connect( driver => 'mysql',
                    database => 'dbname',
                    host => 'hostname',
                    user => 'dbuser',
                    password => 'dbpassword');
  # now $handle isa Jifty::DBI::Handle::mysql

=head1 DESCRIPTION

This class provides a wrapper for DBI handles that can also perform a
number of additional functions.

=cut

=head2 new

Generic constructor

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless( $self, $class );

    @{ $self->{'StatementLog'} } = ();
    return $self;
}

=head2 connect PARAMHASH

Takes a paramhash and connects to your DBI datasource, with the keys C<driver>,
C<database>, C<host>, C<user> and C<password>.

If you created the handle with 
     Jifty::DBI::Handle->new
and there is a Jifty::DBI::Handle::(Driver) subclass for the driver you have chosen,
the handle will be automatically "upgraded" into that subclass.

If there is an error, an exception will be thrown. If a connection has already
been established and is still active, C<undef> will be returned (which is not
an error). Otherwise, if a new connection is made, a true value will be returned.

=cut

sub connect {
    my $self = shift;

    my %args = (
        driver     => undef,
        database   => undef,
        host       => undef,
        sid        => undef,
        port       => undef,
        user       => undef,
        password   => undef,
        requiressl => undef,
        extra      => {},
        @_
    );

    if ( $args{'driver'}
        && !$self->isa( 'Jifty::DBI::Handle::' . $args{'driver'} ) )
    {
        if ( $self->_upgrade_handle( $args{'driver'} ) ) {
            return ( $self->connect(%args) );
        }
    }

    my $dsn = $self->dsn || '';

# Setting this actually breaks old RT versions in subtle ways. So we need to explicitly call it

    $self->build_dsn(%args);

    # Only connect if we're not connected to this source already
    if ( ( !$self->dbh ) || ( !$self->dbh->ping ) || ( $self->dsn ne $dsn ) )
    {
        my $handle
            = DBI->connect( $self->dsn, $args{'user'}, $args{'password'}, $args{'extra'} )
            || Carp::croak "Connection failed: $DBI::errstr\n";

#databases do case conversion on the name of columns returned.
#actually, some databases just ignore case. this smashes it to something consistent
        $handle->{FetchHashKeyName} = 'NAME_lc';

        #Set the handle
        $self->dbh($handle);

        return (1);
    }

    return (undef);

}

=head2 _upgrade_handle DRIVER

This private internal method turns a plain Jifty::DBI::Handle into one
of the standard driver-specific subclasses.

=cut

sub _upgrade_handle {
    my $self = shift;

    my $driver = shift;
    my $class  = 'Jifty::DBI::Handle::' . $driver;

    local $@;
    eval "require $class";
    return if $@;

    bless $self, $class;
    return 1;
}

=head2 build_dsn PARAMHASH

Builds a dsn suitable for handing to DBI->connect.

Mandatory arguments:

=over

=item driver

=item database

=back

Optional arguments:

=over 

=item host

=item port

=item sid

=item requiressl

=item and anything else your DBD lets you pass in

=back

=cut

sub build_dsn {
    my $self = shift;
    my %args = (
        driver     => undef,
        database   => undef,
        host       => undef,
        port       => undef,
        sid        => undef,
        requiressl => undef,
        @_
    );

    my $driver = delete $args{'driver'};
    $args{'dbname'} ||= delete $args{'database'};

    delete $args{'user'};
    delete $args{'password'};
    delete $args{'extra'};

    $self->{'dsn'} = "dbi:$driver:"
        . CORE::join( ';',
        map { $_ . "=" . $args{$_} } grep { defined $args{$_} } keys %args );
}

=head2 dsn

Returns the dsn for this database connection.

=cut

sub dsn {
    my $self = shift;
    return ( $self->{'dsn'} );
}

=head2 raise_error [MODE]

Turns on the Database Handle's RaiseError attribute.

=cut

sub raise_error {
    my $self = shift;
    $self->dbh->{RaiseError} = shift if (@_);
    return $self->dbh->{RaiseError};
}

=head2 print_error [MODE]

Turns on the Database Handle's PrintError attribute.

=cut

sub print_error {
    my $self = shift;
    $self->dbh->{PrintError} = shift if (@_);
    return $self->dbh->{PrintError};
}

=head2 log MESSAGE

Takes a single argument, a message to log.

Currently prints that message to STDERR

=cut

sub log {
    my $self = shift;
    my $msg  = shift;
    warn $msg . "\n";

}

=head2 log_sql_statements BOOL

Takes a boolean argument. If the boolean is true, it will log all SQL
statements, as well as their invocation times and execution times.

Returns whether we're currently logging or not as a boolean

=cut

sub log_sql_statements {
    my $self = shift;
    if (@_) {
        require Time::HiRes;
        $self->{'_dologsql'} = shift;
    }
    return ( $self->{'_dologsql'} );
}

=head2 log_sql_hook NAME [, CODE]

Used in instrumenting the SQL logging. You can use this to, for example, get a
stack trace for each query (so you can find out where the query is being made).
The name is required so that multiple hooks can be installed, and inspected, by
name.

The coderef is run in scalar context and (currently) receives no arguments.

If you don't pass CODE in, then the coderef currently assigned under
NAME is returned.

=cut

sub log_sql_hook {
    my $self = shift;
    my $name = shift;

    if (@_) {
        $self->{'_logsqlhooks'}{$name} = shift;
    }
    return ( $self->{'_logsqlhooks'}{$name} );
}

=head2 _log_sql_statement STATEMENT DURATION BINDINGS

add an SQL statement to our query log

=cut

sub _log_sql_statement {
    my $self      = shift;
    my $statement = shift;
    my $duration  = shift;
    my @bind      = @_;

    my %results;
    my @log = (Time::HiRes::time(), $statement, [@bind], $duration, \%results);

    while (my ($name, $code) = each %{ $self->{'_logsqlhooks'} || {} }) {
        $results{$name} = $code->(@log);
    }

    push @{ $self->{'StatementLog'} }, \@log;
}

=head2 clear_sql_statement_log

Clears out the SQL statement log. 

=cut

sub clear_sql_statement_log {
    my $self = shift;
    @{ $self->{'StatementLog'} } = ();
}

=head2 sql_statement_log

Returns the current SQL statement log as an array of arrays. Each entry is a list of:

(Time, Statement, [Bindings], Duration, {HookResults})

Bindings is an arrayref of the values of any placeholders. HookResults is a
hashref keyed by hook name.

=cut

sub sql_statement_log {
    my $self = shift;
    return ( @{ $self->{'StatementLog'} } );

}

=head2 auto_commit [MODE]

Turns on the Database Handle's Autocommit attribute.

=cut

sub auto_commit {
    my $self = shift;

    my $mode = 1;
    $mode = shift if (@_);

    $self->dbh->{AutoCommit} = $mode;
}

=head2 disconnect

disconnect from your DBI datasource

=cut

sub disconnect {
    my $self = shift;
    if ( $self->dbh ) {
        return ( $self->dbh->disconnect() );
    } else {
        return;
    }
}

=head2 dbh [HANDLE]

Return the current DBI handle. If we're handed a parameter, make the database handle that.

=cut

sub dbh {
    my $self = shift;

    #If we are setting the database handle, set it.
    $DBIHandle{$self} = $PrevHandle = shift if (@_);

    return ( $DBIHandle{$self} ||= $PrevHandle );
}

=head2 delete $table_NAME @KEY_VALUE_PAIRS

Takes a table name and a set of key-value pairs in an array. splits the key value pairs, constructs an DELETE statement and performs the delete. Returns the row_id of this row.

=cut

sub delete {
    my ( $self, $table, @pairs ) = @_;

    my @bind  = ();
    my $where = 'WHERE ';
    while ( my $key = shift @pairs ) {
        $where .= $key . "=?" . " AND ";
        push( @bind, shift(@pairs) );
    }

    $where =~ s/AND $//;
    my $query_string = "DELETE FROM " . $table . ' ' . $where;
    $self->simple_query( $query_string, @bind );
}

=head2 insert $table_NAME @KEY_VALUE_PAIRS

Takes a table name and a set of key-value pairs in an array. splits the key value pairs, constructs an INSERT statement and performs the insert. Returns the row_id of this row.

=cut

sub insert {
    my ( $self, $table, @pairs ) = @_;
    my ( @cols, @vals, @bind );

#my %seen; #only the *first* value is used - allows drivers to specify default
    while ( my $key = shift @pairs ) {
        my $value = shift @pairs;

        # next if $seen{$key}++;
        push @cols, $key;
        push @vals, '?';
        push @bind, $value;
    }

    my $query_string
        = "INSERT INTO $table ("
        . CORE::join( ", ", @cols )
        . ") VALUES " . "("
        . CORE::join( ", ", @vals ) . ")";

    my $sth = $self->simple_query( $query_string, @bind );
    return ($sth);
}

=head2 update_record_value 

Takes a hash with columns: C<table>, C<column>, C<value>, C<primary_keys>, and
C<is_sql_function>.  The first two should be obvious; C<value> is where you 
set the new value you want the column to have. The C<primary_keys> column should 
be the lvalue of Jifty::DBI::Record::PrimaryKeys().  Finally ,
C<is_sql_function> is set when the Value is a SQL function.  For example, you 
might have C<< value => 'PASSWORD(string)' >>, by setting C<is_sql_function> to true,
that string will be inserted into the query directly rather then as a binding. 

=cut

sub update_record_value {
    my $self = shift;
    my %args = (
        table           => undef,
        column          => undef,
        is_sql_function => undef,
        primary_keys    => undef,
        @_
    );

    return 1 unless grep {defined} values %{ $args{primary_keys} };

    my @bind  = ();
    my $query = 'UPDATE ' . $args{'table'} . ' ';
    $query .= 'SET ' . $args{'column'} . '=';

    ## Look and see if the column is being updated via a SQL function.
    if ( $args{'is_sql_function'} ) {
        $query .= $args{'value'} . ' ';
    } else {
        $query .= '? ';
        push( @bind, $args{'value'} );
    }

    ## Constructs the where clause.
    my $where = 'WHERE ';
    foreach my $key ( keys %{ $args{'primary_keys'} } ) {
        $where .= $key . "=?" . " AND ";
        push( @bind, $args{'primary_keys'}{$key} );
    }
    $where =~ s/AND\s$//;

    my $query_str = $query . $where;
    return ( $self->simple_query( $query_str, @bind ) );
}

=head2 update_table_value table COLUMN NEW_value RECORD_ID IS_SQL

Update column COLUMN of table table where the record id = RECORD_ID.

If IS_SQL is set, don't quote the NEW_VALUE.

=cut

sub update_table_value {
    my $self = shift;

    ## This is just a wrapper to update_record_value().
    my %args = ();
    $args{'table'}           = shift;
    $args{'column'}          = shift;
    $args{'value'}           = shift;
    $args{'primary_keys'}    = shift;
    $args{'is_sql_function'} = shift;

    return $self->update_record_value(%args);
}

=head2 simple_query QUERY_STRING, [ BIND_VALUE, ... ]

Execute the SQL string specified in QUERY_STRING

=cut

our $retry_simple_query = 1;
sub simple_query {
    my $self         = shift;
    my $query_string = shift;
    my @bind_values;
    @bind_values = (@_) if (@_);

    my $sth = $self->dbh->prepare($query_string);
    unless ($sth) {
        my $message = "$self couldn't prepare the query '$query_string': "
                    . $self->dbh->errstr;
        if ($DEBUG) {
            die "$message\n";
        } else {
            warn "$message\n";
            my $ret = Class::ReturnValue->new();
            $ret->as_error(
                errno   => '-1',
                message => $message,
                do_backtrace => undef
            );
            return ( $ret->return_value );
        }
    }

    # Check @bind_values for HASH refs
    for ( my $bind_idx = 0; $bind_idx < scalar @bind_values; $bind_idx++ ) {
        if ( ref( $bind_values[$bind_idx] ) eq "HASH" ) {
            my $bhash = $bind_values[$bind_idx];
            $bind_values[$bind_idx] = $bhash->{'value'};
            delete $bhash->{'value'};
            $sth->bind_param( $bind_idx + 1, undef, $bhash );
        }

        # Some databases, such as Oracle fail to cope if it's a perl utf8
        # string. they desperately want bytes.
        Encode::_utf8_off( $bind_values[$bind_idx] );
    }

    my $basetime;
    if ( $self->log_sql_statements ) {
        $basetime = Time::HiRes::time();
    }
    my $executed;

    local $@;
    {
        no warnings 'uninitialized';    # undef in bind_values makes DBI sad
        eval { $executed = $sth->execute(@bind_values) };

        # try to ping and reconnect, if the DB connection failed
        if (($@ or not $executed) and !$self->dbh->ping) {
            $self->dbh(undef); # don't try pinging again, just connect
            $self->connect; 

            # Need to call ourselves, to create a new sth from the new dbh
            if ($retry_simple_query) {
                local $retry_simple_query = 0;
                return $self->simple_query($query_string, @_);
            }
        }
    }
    if ( $self->log_sql_statements ) {
        $self->_log_sql_statement( $query_string,
            Time::HiRes::time() - $basetime, @bind_values );

    }

    if ( $@ or !$executed ) {
        my $message = "$self couldn't execute the query '$query_string': "
                        . ($self->dbh->errstr || $@);

        if ($DEBUG) {
            die "$message\n";
        } else {

 # XXX: This warn doesn't show up because we mask logging in Jifty::Test::END.
 # and it usually fails because the test server is still running.
            warn "$message\n";

            my $ret = Class::ReturnValue->new();
            $ret->as_error(
                errno   => '-1',
                message => $message,
                do_backtrace => undef
            );
            return ( $ret->return_value );
        }

    }
    return ($sth);

}

=head2 fetch_result QUERY, [ BIND_VALUE, ... ]

Takes a SELECT query as a string, along with an array of BIND_VALUEs
If the select succeeds, returns the first row as an array.
Otherwise, returns a Class::ResturnValue object with the failure loaded
up.

=cut 

sub fetch_result {
    my $self        = shift;
    my $query       = shift;
    my @bind_values = @_;
    my $sth         = $self->simple_query( $query, @bind_values );
    if ($sth) {
        return ( $sth->fetchrow );
    } else {
        return ($sth);
    }
}

=head2 blob_params COLUMN_NAME COLUMN_TYPE

Returns a hash ref for the bind_param call to identify BLOB types used
by the current database for a particular column type.

=cut

sub blob_params {
    my $self = shift;

    # Don't assign to key 'value' as it is defined later.
    return ( {} );
}

=head2 database_version

Returns the database's version.

If argument C<short> is true returns short variant, in other
case returns whatever database handle/driver returns. By default
returns short version, e.g. C<4.1.23> or C<8.0-rc4>.

Returns empty string on error or if database couldn't return version.

The base implementation uses a C<SELECT VERSION()>

=cut

sub database_version {
    my $self = shift;
    my %args = ( short => 1, @_ );

    unless ( defined $self->{'database_version'} ) {

        # turn off error handling, store old values to restore later
        my $re = $self->raise_error;
        $self->raise_error(0);
        my $pe = $self->print_error;
        $self->print_error(0);

        my $statement = "SELECT VERSION()";
        my $sth       = $self->simple_query($statement);

        my $ver = '';
        $ver = ( $sth->fetchrow_arrayref->[0] || '' ) if $sth;
        $ver =~ /(\d+(?:\.\d+)*(?:-[a-z0-9]+)?)/i;
        $self->{'database_version'} = $ver;
        $self->{'database_version_short'} = $1 || $ver;

        $self->raise_error($re);
        $self->print_error($pe);
    }

    return $self->{'database_version_short'} if $args{'short'};
    return $self->{'database_version'};
}

=head2 case_sensitive

Returns 1 if the current database's searches are case sensitive by default
Returns undef otherwise

=cut

sub case_sensitive {
    my $self = shift;
    return (1);
}

=head2 _make_clause_case_insensitive column operator VALUE

Takes a column, operator and value. performs the magic necessary to make
your database treat this clause as case insensitive.

Returns a column operator value triple.

=cut

sub _case_insensitivity_valid {
    my $self     = shift;
    my $column   = shift;
    my $operator = shift;
    my $value    = shift;

    return $value ne ''
        && $value ne "''"
        && ( $operator =~ /^(?:(?:NOT )?LIKE|!?=|IN)$/i )

        # don't downcase integer values
        && $value !~ /^['"]?\d+['"]?$/;
}

sub _make_clause_case_insensitive {
    my $self     = shift;
    my $column   = shift;
    my $operator = shift;
    my $value    = shift;

    if ( $self->_case_insensitivity_valid( $column, $operator, $value ) ) {
        $column = "lower($column)";
        if ( ref $value eq 'ARRAY' ) {
            map { $_ = "lower($_)" } @{$value};
        } else {
            $value = "lower($value)";
        }
    }
    return ( $column, $operator, $value );
}

=head2 quote_value VALUE

Calls the database's L<DBD/quote> method and returns the result.
Additionally, turns on perl's utf8 flag if the returned content is
UTF8.

=cut

sub quote_value {
    my $self = shift;
    my ($value) = @_;
    my $tmp = $self->dbh->quote($value);

    # Accomodate DBI drivers that don't understand UTF8
    if ( $] >= 5.007 ) {
        require Encode;
        if ( Encode::is_utf8($tmp) ) {
            Encode::_utf8_on($tmp);
        }
    }
    return $tmp;
}

=head2 begin_transaction

Tells Jifty::DBI to begin a new SQL transaction. This will
temporarily suspend Autocommit mode.

Emulates nested transactions, by keeping a transaction stack depth.

=cut

sub begin_transaction {
    my $self = shift;

    if ( $TRANSDEPTH > 0 ) {
        # We're inside a transaction.
        $TRANSDEPTH++;
        return $TRANSDEPTH;
    }

    my $rv = $self->dbh->begin_work;
    if ($rv) {
        $TRANSDEPTH++;
    }
    return $rv;
}

=head2 commit

Tells Jifty::DBI to commit the current SQL transaction. 
This will turn Autocommit mode back on.

=cut

sub commit {
    my $self = shift;
    unless ($TRANSDEPTH) {
        Carp::confess(
            "Attempted to commit a transaction with none in progress");
    }

    if ($TRANSDEPTH > 1) {
        # We're inside a nested transaction.
        $TRANSDEPTH--;
        return $TRANSDEPTH;
    }

    my $rv = $self->dbh->commit;
    if ($rv) {
        $TRANSDEPTH--;
    }
    return $rv;
}

=head2 rollback [FORCE]

Tells Jifty::DBI to abort the current SQL transaction. 
This will turn Autocommit mode back on.

If this method is passed a true argument, stack depth is blown away and the outermost transaction is rolled back

=cut

sub rollback {
    my $self  = shift;
    my $force = shift;

    my $dbh = $self->dbh;
    unless ($dbh) {
        $TRANSDEPTH = 0;
        return;
    }

#unless ($TRANSDEPTH) {Carp::confess("Attempted to rollback a transaction with none in progress")};
    if ($force) {
        $TRANSDEPTH = 0;

        return ( $dbh->rollback );
    }

    if ($TRANSDEPTH == 0) {
        # We're not actually in a transaction.
        return 1;
    }

    if ($TRANSDEPTH > 1) {
        # We're inside a nested transaction.
        $TRANSDEPTH--;
        return $TRANSDEPTH;
    }

    my $rv = $dbh->rollback;
    if ($rv) {
        $TRANSDEPTH--;
    }
    return $rv;
}

=head2 force_rollback

Force the handle to rollback. Whether or not we're deep in nested transactions

=cut

sub force_rollback {
    my $self = shift;
    $self->rollback(1);
}

=head2 transaction_depth

Return the current depth of the faked nested transaction stack.

=cut

sub transaction_depth {
    my $self = shift;
    return ($TRANSDEPTH);
}

=head2 apply_limits STATEMENTREF ROWS_PER_PAGE FIRST_ROW

takes an SQL SELECT statement and massages it to return ROWS_PER_PAGE starting with FIRST_ROW;


=cut

sub apply_limits {
    my $self         = shift;
    my $statementref = shift;
    my $per_page     = shift;
    my $first        = shift;

    my $limit_clause = '';

    if ($per_page) {
        $limit_clause = " LIMIT ";
        if ($first) {
            $limit_clause .= $first . ", ";
        }
        $limit_clause .= $per_page;
    }

    $$statementref .= $limit_clause;

}

=head2 join { Paramhash }

Takes a paramhash of everything Jifty::DBI::Collection's C<join> method
takes, plus a parameter called C<collection> that contains a ref to a
L<Jifty::DBI::Collection> object'.

This performs the join.

=cut

sub join {

    my $self = shift;
    my %args = (
        collection  => undef,
        type        => 'normal',
        alias1      => 'main',
        column1     => undef,
        table2      => undef,
        alias2      => undef,
        column2     => undef,
        expression  => undef,
        operator    => '=',
        is_distinct => 0,
        @_
    );

    my $alias;

    # If we're handed in a table2 as a Collection object, make notes
    # about if the result of the join is still distinct for the
    # calling collection
    if ( $args{'table2'}
        && UNIVERSAL::isa( $args{'table2'}, 'Jifty::DBI::Collection' ) )
    {
        my $c = ref $args{'table2'} ? $args{'table2'} : $args{'table2'}->new($args{collection}->_new_collection_args);
        if ( $args{'operator'} eq '=' ) {
            my $x = $c->new_item->column( $args{column2} );
            if ( $x->type eq 'serial' || $x->distinct ) {
                $args{'is_distinct'} = 1;
            }
        }
        $args{'class2'} = ref $c;
        $args{'table2'} = $c->table;
    }

    if ( $args{'alias2'} ) {
        if ( $args{'collection'}{'joins'}{ $args{alias2} } and lc $args{'collection'}{'joins'}{ $args{alias2} }{type} eq "cross" ) {
            my $join = $args{'collection'}{'joins'}{ $args{alias2} };
            $args{'table2'} = $join->{table};
            $alias = $join->{alias};
        } else {

            # if we can't do that, can we reverse the join and have it work?
            @args{qw/alias1 alias2/}   = @args{qw/alias2 alias1/};
            @args{qw/column1 column2/} = @args{qw/column2 column1/};

            if ( $args{'collection'}{'joins'}{ $args{alias2} } and lc $args{'collection'}{'joins'}{ $args{alias2} }{type} eq "cross" ) {
                my $join = $args{'collection'}{'joins'}{ $args{alias2} };
                $args{'table2'} = $join->{table};
                $alias = $join->{alias};
            } else {

                # Swap back
                @args{qw/alias1 alias2/}   = @args{qw/alias2 alias1/};
                @args{qw/column1 column2/} = @args{qw/column2 column1/};

                return $args{'collection'}->limit(
                    entry_aggregator => 'AND',
                    @_,
                    quote_value => 0,
                    alias       => $args{'alias1'},
                    column      => $args{'column1'},
                    value       => $args{'alias2'} . "." . $args{'column2'},
                );
            }
        }
    } else {
        $alias = $args{'collection'}->_get_alias( $args{'table2'} );
    }

    my $meta = $args{'collection'}->{'joins'}{$alias} ||= {};
    $meta->{alias} = $alias;
    if ( $args{'type'} =~ /LEFT/i ) {
        $meta->{'alias_string'}
            = " LEFT JOIN " . $args{'table2'} . " $alias ";
        $meta->{'type'} = 'LEFT';

    } else {
        $meta->{'alias_string'} = " JOIN " . $args{'table2'} . " $alias ";
        $meta->{'type'}         = 'NORMAL';
    }
    $meta->{'depends_on'}       = $args{'alias1'};
    $meta->{'is_distinct'}      = $args{'is_distinct'};
    $meta->{'class'}            = $args{'class2'} if $args{'class2'};
    $meta->{'entry_aggregator'} = $args{'entry_aggregator'}
        if $args{'entry_aggregator'};

    my $criterion = $args{'expression'} || "$args{'alias1'}.$args{'column1'}";
    $meta->{'criteria'}{'base_criterion'} = [
        {   column   => $criterion,
            operator => $args{'operator'},
            value    => "$alias.$args{'column2'}",
        }
    ];

    return ($alias);
}

# this code is all hacky and evil. but people desperately want _something_ and I'm
# super tired. refactoring gratefully appreciated.

sub _build_joins {
    my $self       = shift;
    my $collection = shift;

    $self->_optimize_joins( collection => $collection );

    my @cross = grep { lc $_->{type} eq "cross" }
        values %{ $collection->{'joins'} };
    my $join_clause = ( $collection->table . " main" )
        . CORE::join( " ", map { $_->{alias_string} } @cross );
    my %processed = map { $_->{alias} => 1 } @cross;
    $processed{'main'} = 1;

# get a @list of joins that have not been processed yet, but depend on processed join
    my $joins = $collection->{'joins'};
    while ( my @list = grep !$processed{$_}
        && $processed{ $joins->{$_}{'depends_on'} }, keys %$joins )
    {
        foreach my $join (@list) {
            $processed{$join}++;

            my $meta = $joins->{$join};
            my $aggregator = $meta->{'entry_aggregator'} || 'AND';

            $join_clause .= $meta->{'alias_string'} . " ON ";
            my @tmp = map {
                ref($_)
                    ? $_->{'column'} . ' '
                    . $_->{'operator'} . ' '
                    . $_->{'value'}
                    : $_
                }
                map {
                ( '(', @$_, ')', $aggregator )
                } values %{ $meta->{'criteria'} };

            # delete last aggregator
            pop @tmp;
            $join_clause .= CORE::join ' ', @tmp;
        }
    }

# here we could check if there is recursion in joins by checking that all joins
# are processed
    if ( my @not_processed = grep !$processed{$_}, keys %$joins ) {
        die "Unsatisfied dependency chain in joins @not_processed";
    }
    return $join_clause;
}

sub _optimize_joins {
    my $self  = shift;
    my %args  = ( collection => undef, @_ );
    my $joins = $args{'collection'}->{'joins'};

    my %processed;
    $processed{$_}++
        foreach grep {lc $joins->{$_}{'type'} ne 'left'} keys %$joins;
    $processed{'main'}++;

    my @ordered;

# get a @list of joins that have not been processed yet, but depend on processed join
# if we are talking about forest then we'll get the second level of the forest,
# but we should process nodes on this level at the end, so we build FILO ordered list.
# finally we'll get ordered list with leafes in the beginning and top most nodes at
# the end.
    while ( my @list = grep !$processed{$_}
        && $processed{ $joins->{$_}{'depends_on'} }, keys %$joins )
    {
        unshift @ordered, @list;
        $processed{$_}++ foreach @list;
    }

    foreach my $join (@ordered) {
        next
            if $self->may_be_null(
            collection => $args{'collection'},
            alias      => $join
            );

        $joins->{$join}{'alias_string'} =~ s/^\s*LEFT\s+/ /i;
        $joins->{$join}{'type'} = 'NORMAL';
    }

}

=head2 may_be_null

Takes a C<collection> and C<alias> in a hash and returns true if
restrictions of the query allow NULLs in a table joined with the
alias, otherwise returns false value which means that you can use
normal join instead of left for the aliased table.

Works only for queries have been built with
L<Jifty::DBI::Collection/join> and L<Jifty::DBI::Collection/limit>
methods, for other cases return true value to avoid fault
optimizations.

=cut

sub may_be_null {
    my $self = shift;
    my %args = ( collection => undef, alias => undef, @_ );

# if we have at least one subclause that is not generic then we should get out
# of here as we can't parse subclauses
    return 1
        if grep $_ ne 'generic_restrictions',
        keys %{ $args{'collection'}->{'subclauses'} };

    # build full list of generic conditions
    my @conditions;
    foreach ( grep @$_, values %{ $args{'collection'}->{'restrictions'} } ) {
        push @conditions, 'AND' if @conditions;
        push @conditions, '(', @$_, ')';
    }

    # find tables that depends on this alias and add their join conditions
    foreach my $join ( values %{ $args{'collection'}->{'joins'} } ) {

        # left joins on the left side so later we'll get 1 AND x expression
        # which equal to x, so we just skip it
        next if $join->{'type'} eq 'LEFT';
        next unless $join->{'depends_on'} && ($join->{'depends_on'} eq $args{'alias'});

        my @tmp = map { ( '(', @$_, ')', $join->{'entry_aggregator'} ) }
            values %{ $join->{'criteria'} };
        pop @tmp;

        @conditions = ( '(', @conditions, ')', 'AND', '(', @tmp, ')' );

    }
    return 1 unless @conditions;

    # replace conditions with boolean result: 1 - allow nulls, 0 - doesn't
    foreach ( splice @conditions ) {
        unless ( ref $_ ) {
            push @conditions, $_;
        } elsif ( $_->{'column'} =~ /^\Q$args{'alias'}./ ) {

            # only operator IS allows NULLs in the aliased table
            push @conditions, lc $_->{'operator'} eq 'is';
        } elsif ( $_->{'value'} && $_->{'value'} =~ /^\Q$args{'alias'}./ ) {

            # right operand is our alias, such condition don't allow NULLs
            push @conditions, 0;
        } else {

            # conditions on other aliases
            push @conditions, 1;
        }
    }

    # returns index of closing paren by index of openning paren
    my $closing_paren = sub {
        my $i     = shift;
        my $count = 0;
        for ( ; $i < @conditions; $i++ ) {
            if ( $conditions[$i] && $conditions[$i] eq '(' ) {
                $count++;
            } elsif ( $conditions[$i] && $conditions[$i] eq ')' ) {
                $count--;
            }
            return $i unless $count;
        }
        die "lost in parens";
    };

    # solve boolean expression we have, an answer is our result
    my @tmp = ();
    while ( defined( my $e = shift @conditions ) ) {

        #warn "@tmp >>>$e<<< @conditions";
        return $e if !@conditions && !@tmp;

        unless ($e) {
            if ( $conditions[0] eq ')' ) {
                push @tmp, $e;
                next;
            }

            my $aggreg = uc shift @conditions;
            if ( $aggreg eq 'OR' ) {

                # 0 OR x == x
                next;
            } elsif ( $aggreg eq 'AND' ) {

                # 0 AND x == 0
                my $close_p = $closing_paren->(0);
                splice @conditions, 0, $close_p + 1, (0);
            } else {
                die "lost @tmp >>>$e $aggreg<<< @conditions";
            }
        } elsif ( $e eq '1' ) {
            if ( $conditions[0] eq ')' ) {
                push @tmp, $e;
                next;
            }

            my $aggreg = uc shift @conditions;
            if ( $aggreg eq 'OR' ) {

                # 1 OR x == 1
                my $close_p = $closing_paren->(0);
                splice @conditions, 0, $close_p + 1, (1);
            } elsif ( $aggreg eq 'AND' ) {

                # 1 AND x == x
                next;
            } else {
                die "lost @tmp >>>$e $aggreg<<< @conditions";
            }
        } elsif ( $e eq '(' ) {
            if ( $conditions[1] eq ')' ) {
                splice @conditions, 1, 1;
            } else {
                push @tmp, $e;
            }
        } elsif ( $e eq ')' ) {
            unshift @conditions, @tmp, $e;
            @tmp = ();
        } else {
            die "lost: @tmp >>>$e<<< @conditions";
        }
    }
    return 1;
}

=head2 distinct_query STATEMENTREF 

takes an incomplete SQL SELECT statement and massages it to return a DISTINCT result set.

=cut

sub distinct_query {
    my $self         = shift;
    my $statementref = shift;
    my $collection   = shift;

    # Prepend select query for DBs which allow DISTINCT on all column types.
    $$statementref
        = "SELECT DISTINCT "
        . $collection->query_columns
        . " FROM $$statementref";

    $$statementref .= $collection->_group_clause;
    $$statementref .= $collection->_order_clause;
}

=head2 distinct_count STATEMENTREF 

takes an incomplete SQL SELECT statement and massages it to return a DISTINCT result set.

=cut

sub distinct_count {
    my $self         = shift;
    my $statementref = shift;

    # Prepend select query for DBs which allow DISTINCT on all column types.
    $$statementref = "SELECT COUNT(DISTINCT main.id) FROM $$statementref";

}

=head2 canonical_true

This returns the canonical true value for this database. For example, in SQLite
it is 1 but in Postgres it is 't'.

The default is 1.

=cut

sub canonical_true { 1 }

=head2 canonical_false

This returns the canonical false value for this database. For example, in SQLite
it is 0 but in Postgres it is 'f'.

The default is 0.

=cut

sub canonical_false { 0 }

=head2 Schema manipulation methods

=head3 rename_column

Rename a column in a table. Takes 'table', 'column' and new name in 'to'.

=cut

sub rename_column {
    my $self = shift;
    my %args = (table => undef, column => undef, to => undef, @_);
# Oracle: since Oracle 9i R2
# Pg: 7.4 can this and may be earlier
    return $self->simple_query(
        "ALTER TABLE $args{'table'} RENAME COLUMN $args{'column'} TO $args{'to'}"
    );
}


=head3 rename_table

Renames a table in the DB. Takes 'table' and new name of it in 'to'.

=cut

sub rename_table {
    my $self = shift;
    my %args = (table => undef, to => undef, @_);
# mysql has RENAME TABLE, but alter can rename temporary
# Oracle, Pg, SQLite are ok with this
    return $self->simple_query("ALTER TABLE $args{'table'} RENAME TO $args{'to'}");
}

=head2 supported_drivers

Returns a list of the drivers L<Jifty::DBI> supports.

=cut

sub supported_drivers {
    return qw(
        SQLite
        Informix
        mysql
        mysqlPP
        ODBC
        Oracle
        Pg
        Sybase
    );
}

=head2 available_drivers

Returns a list of the available drivers based on the presence of C<DBD::*>
modules.

=cut

sub available_drivers {
    my $self = shift;

    local $@;
    return grep { eval "require DBD::" . $_ } $self->supported_drivers;
}

=head2 is_available_driver

Returns a boolean indicating whether the provided driver is available.

=cut

do {
    # lazily memoize
    my $is_available_driver;

    sub is_available_driver {
        my $self   = shift;
        my $driver = shift;

        if (!$is_available_driver) {
            %$is_available_driver = map { $_ => 1 } $self->available_drivers;
        }

        return $is_available_driver->{$driver};
    }
};

=head2 DESTROY

When we get rid of the L<Jifty::DBI::Handle>, we need to disconnect
from the database

=cut

sub DESTROY {
    my $self = shift;

    # eval in DESTROY can cause $@ issues elsewhere
    local $@;

    $self->disconnect
        unless $self->dbh
            and $self->dbh
                # We use an eval {} because DESTROY order during
                # global destruction is not guaranteed -- the dbh may
                # no longer be tied, which throws an error.
            and eval { $self->dbh->{InactiveDestroy} };
    delete $DBIHandle{$self};
}

1;
__END__


=head1 DIAGNOSIS

Setting C<JIFTY_DBQUERY_CALLER> environment variable will make
L<Jifty::DBI> dump the caller for the SQL queries matching it.  See
also C<DBI> about setting C<DBI_PROFILE>.

=head1 AUTHOR

Jesse Vincent, <jesse@bestpractical.com>

=head1 SEE ALSO

perl(1), L<Jifty::DBI>

=cut

