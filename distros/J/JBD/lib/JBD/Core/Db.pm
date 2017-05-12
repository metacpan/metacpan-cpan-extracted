package JBD::Core::Db;
# ABSTRACT: a DBI abstraction
our $VERSION = '0.04'; # VERSION

#/ JBD::Core::Db is a simple DBI wrapper.
#/ Because of the use of LIMIT, this package assumes your database
#/ is something like MySQL or SQLite, which supports the LIKE clause.
#/ @author Joel Dalley
#/ @version 2013/Oct/27

use JBD::Core::stern;
use DBI;

sub DSN {0}
sub DBI {1}


#///////////////////////////////////////////////////////////////
#/ Object Interface ////////////////////////////////////////////

#/ @param string $type    object type
#/ @param string $dsn    DSN for DBI::connect()
#/ @return JBD::Core::Db    blessed arrayref
sub new {
    my ($type, $dsn) = @_;
    my $dbi = DBI::connect('DBI', $dsn) or die $!;
    bless [$dsn, $dbi], $type;
}

#/ @param JBD::Core::Db $this
#/ @param scalar $table    A database table
#/ @param arrayref $columns    Column names to select
#/ @param arrayref $clauses    Where clauses
#/ @param arrayref $values    Column values
#/ @param hash [optional] %opts    Select options
#/ @return coderef    a result row iterator
sub iterator {
    die 'Missing required args' if @_ < 3;
    my ($this, $table, $columns) = (shift, shift, shift);
    my ($clauses, $values, %opts) = (shift || [], shift || [], @_);

    my $query = select_query($table, $columns, $clauses, %opts);
    my $sth = $this->execute($query, $values);

    sub {
        my $res = $sth->fetchrow_arrayref;
        $sth->finish if not defined $res;
        $res;
    };
}

#/ @param JBD::Core::Db $this
#/ @param scalar $table    A database table
#/ @param arrayref $clauses    Where clauses
#/ @param arrayref $values    Column values
#/ @return scalar    the number of rows matching the where clauses
sub count {
    die 'Missing table' if @_ < 2;
    my ($this, $table) = (shift, shift);
    my ($clauses, $values) = (shift || [], shift || []);

    my $iter = $this->iterator($table, ['COUNT(*)'], $clauses, $values);
    my $data = $iter->();
    $data ? $data->[0] : 0;
}

#/ @param JBD::Core::Db $this
#/ @param scalar $table    A database table
#/ @param arrayref $columns    Column names to insert data into
#/ @param arrayref $values    Column values
sub insert {
    die 'Missing required args' if @_ < 4;
    my ($this, $table, $columns, $values) = @_;
    $this->execute(insert_query($table, $columns), $values);
}

#/ @param JBD::Core::Db $this
#/ @param scalar $table    A database table
#/ @param arrayref $columns    Column names to update
#/ @param arrayref $clauses    Where clauses
#/ @param arrayref $values    Column values
sub update {
    die 'Missing required args' if @_ < 5;
    my ($this, $table, $columns, $clauses, $values) = @_;
    $this->execute(update_query($table, $columns, $clauses), $values);
}

#/ @param JBD::Core::Db $this
#/ @param JBD::Core::Db $this
#/ @param string $table    A database table
#/ @param arrayref $clauses    Where clauses
sub delete {
    die 'Missing required args' if @_ < 4;
    my ($this, $table, $clauses, $values) = @_;
    $this->execute(delete_query($table, $clauses), $values);
}

#/ @param JBD::Core::Db $this
#/ @param string $query    SQL query
#/ @param arrayref $values    Bind parameter values
#/ @return object    a DBI::st
sub execute {
    my ($this, $query, $values) = @_;
    my $sth = $this->[DBI]->prepare($query) or die $!;
    $sth->execute(@$values) or die $!;
    $sth;
}


#///////////////////////////////////////////////////////////////
#/ Query constructors //////////////////////////////////////////

#/ @param scalar $table    A database table
#/ @param arrayref $columns    Column names
#/ @param arrayref $clauses    Where clauses
#/ @param hash [optional] %opts    Select options
#/ @return scalar    Select query SQL
sub select_query($$$;$) {
    my ($table, $columns, $clauses, %opts) = (shift, shift, shift, @_);

    my $select = join ',', @$columns;
    my $where = join ' AND ', @$clauses;
    my $query = 'SELECT ' . $select  . ' FROM ' . $table;
    $query .=  ' WHERE ' . $where if $where;

    $query .= ' ORDER BY ' . $opts{order} if $opts{order};
    $query .= ' GROUP BY ' . $opts{group} if $opts{group};
    if ($opts{start} || $opts{limit}) {
        $query .= ' LIMIT ';
        $query .= $opts{start} . ',' if $opts{start};
        $query .= $opts{limit} if $opts{limit};
    }

    $query;
}

#/ @param scalar $table    A database table
#/ @param arrayref $columns    Column names to insert values for
#/ @return scalar    Insert query SQL
sub insert_query($$) {
    my ($table, $columns) = @_;
    my $inserts = join ',', @$columns;
    my $params = join ',', map '?', @$columns;
    'INSERT INTO ' . $table . '(' . $inserts . ') VALUES(' . $params . ')';
}

#/ @param scalar $table    A database table
#/ @param arrayref $columns    Column names to update
#/ @param arrayref $clauses    Column names for the where clauses
#/ @return scalar    Update query SQL
sub update_query($$$) {
    my ($table, $columns, $clauses) = @_;
    my $updates = join ',', map "$_=?", @$columns;
    my $where = join ' AND ', @$clauses;
    'UPDATE ' . $table . ' SET ' . $updates . ' WHERE ' . $where;
}

#/ @param scalar $table    A database table
#/ @param arrayref $clauses    where clauses
#/ @return scalar    Delete query SQL
sub delete_query($$) {
    my ($table, $clauses) = @_;
    'DELETE FROM ' . $table . ' WHERE ' . join ' AND ', @$clauses;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Core::Db - a DBI abstraction

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
