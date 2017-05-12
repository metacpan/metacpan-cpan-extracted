package Karas;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.07';
use Carp ();
use Class::Accessor::Lite 0.05 (
    rw => [qw/query_builder default_row_class owner_pid connection_manager row_class_map/],
);
use Class::Trigger qw(
    BEFORE_INSERT

    BEFORE_REPLACE

    BEFORE_BULK_INSERT

    BEFORE_INSERT_ON_DUPLICATE

    BEFORE_UPDATE_ROW
    AFTER_UPDATE_ROW
    BEFORE_UPDATE_DIRECT
    AFTER_UPDATE_DIRECT

    BEFORE_DELETE_ROW
    BEFORE_DELETE_WHERE
    AFTER_DELETE_ROW
    AFTER_DELETE_DIRECT
);

use Module::Load ();
use Data::Page::NoTotalEntries;

use DBIx::TransactionManager;
use DBIx::Handler;

use Karas::Row;
use Karas::QueryBuilder;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    unless ($args{connect_info}) {
        Carp::croak("Missing mandatory parameter: connect_info");
    }

    # ref. http://blog.nomadscafe.jp/2012/11/dbi-connect.html
    $args{connect_info}->[3]->{RaiseError} //= 1;
    $args{connect_info}->[3]->{PrintError} //= 0;
    $args{connect_info}->[3]->{AutoCommit} //= 1;
    $args{connect_info}->[3]->{ShowErrorStatement} //= 1;
    $args{connect_info}->[3]->{AutoInactiveDestroy} //= 1;

    $args{connection_manager} = DBIx::Handler->new(
        @{$args{connect_info}}
    );
    my $self = bless {
        row_class_map => {},
        %args
    }, $class;
    $self->{query_builder} ||= Karas::QueryBuilder->new(driver => $self->_driver_name);
    return $self;
}

sub _driver_name {
    my $self = shift;
    $self->{driver_name} //= $self->dbh->{Driver}->{Name};
}

# -------------------------------------------------------------------------
# Plugin
#
# -------------------------------------------------------------------------
sub load_plugin {
    my ($class, $name, $args) = @_;
    Carp::croak("Do not use this plugin to instance") if ref $class;
    Carp::croak("Do not load this plugin to Karas itself. Please make your own child class from Karas.") if $class eq 'Karas';

    $name = ($name =~ s/^\+//) ? $name : "Karas::Plugin::$name";
    Module::Load::load($name);
    my $plugin = $name->new($args || +{});
    $plugin->init($class);
}

# -------------------------------------------------------------------------
# Connection
#
# -------------------------------------------------------------------------

sub dbh {
    my $self = shift @_;
    Carp::croak("Too many arguments for Karas#dbh") if @_!=0;
    return $self->connection_manager->dbh();
}

sub disconnect {
    my ($self) = @_;
    Carp::croak("Too many arguments for Karas#disconnect") if @_!=1;
    $self->connection_manager->disconnect();
}

# ------------------------------------------------------------------------- 
# schema
#
# -------------------------------------------------------------------------

sub load_schema_from_db {
    my ($self, %args) = @_;
    require Karas::Loader;
    my $class = ref($self) || $self;
    $args{namespace} //= do {
        if ($class eq 'Karas') {
            state $i=0;
            $class . '::Anon' . $i++;
        } else {
            $class;
        }
    };
    $self->{row_class_map} = Karas::Loader->load(
        dbh => $self->dbh,
        %args
    );
    return undef;
}

sub get_row_class {
    my ($self, $table_name) = @_;
    Carp::croak("Missing mandatory parameter: table_name") unless $table_name;
    my $row_class = $self->row_class_map->{$table_name}
        or Carp::croak("Unknown table: $table_name. $table_name is not registered to Karas.");
    return $row_class;
}

# -------------------------------------------------------------------------
# SQL
#
# -------------------------------------------------------------------------

sub search {
    my ($self, $table, $where, $opt) = @_;
    $opt->{cols} ||= [\'*'];
    my ($sql, @binds) = $self->query_builder->select($table, $opt->{cols}, $where, $opt);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    my $row_class = $self->get_row_class($table);
    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
        push @rows, $row_class->new($row);
    }
    return @rows;
}

sub count {
    my ($self, $table, $where) = @_;
    my ($sql, @binds) = $self->query_builder->select($table, [\'COUNT(*)'], $where);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    my ($count) = $sth->fetchrow_array();
    return $count;
}

sub search_with_pager {
    my ($self, $table, $where, $opt) = @_;
    $opt->{cols} ||= [\'*'];
    my $page = delete $opt->{page} // Carp::croak("Missing mandatory parameter: page");
    my $rows = delete $opt->{rows} // Carp::croak("Missing mandatory parameter: rows");
    $opt->{limit}  = $rows+1;
    $opt->{offset} = $rows*($page-1);
    my ($sql, @binds) = $self->query_builder->select($table, $opt->{cols}, $where, $opt);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    my $row_class = $self->get_row_class($table);
    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
        push @rows, $row_class->new($row);
    }
    my $has_next = 0;
    if (@rows == $rows+1) {
        pop @rows;
        $has_next = 1;
    }
    my $pager = Data::Page::NoTotalEntries->new(
        has_next => $has_next,
        entries_per_page => $rows,
        current_page => $page,
        entries_on_this_page => 0+@rows,
    );
    return (\@rows, $pager);
}

sub search_by_sql {
    my ($self, $sql, $binds, $table_name) = @_;
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@$binds);
    $table_name //= $self->guess_table_name($sql);
    unless ($table_name) {
        Carp::croak("Cannot guess table name from SQL. You need to pass the  table name: " . $sql);
    }
    my $row_class = $self->get_row_class($table_name);
    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
        push @rows, $row_class->new($row);
    }
    return @rows;
}

sub insert {
    my ($self, $table, $values) = @_;
    Carp::croak("Missing mandatory parameter: table") unless defined $table;
    Carp::croak("Missing mandatory parameter: values")   unless defined $values;
    $self->_insert($table, $values);

    # and select it.
    my $row_class = $self->get_row_class($table);
    my $last_insert_id = $self->last_insert_id;
    my @pk = $row_class->primary_key;
    if (@pk == 1 && defined($last_insert_id)) {
        return(($self->search($table, {$pk[0] => $last_insert_id}))[0]);
    }

    # cannot select row. just create new object from arguments.
    return $row_class->new($values);
}

sub fast_insert {
    my ($self, $table, $values) = @_;
    Carp::croak("Missing mandatory parameter: table") unless defined $table;
    Carp::croak("Missing mandatory parameter: values")   unless defined $values;
    $self->_insert($table, $values);
    return $self->last_insert_id;
}

sub _insert {
    my ($self, $table, $values) = @_;
    $self->call_trigger(BEFORE_INSERT => $table, $values);
    my ($sql, @binds) = $self->query_builder->insert($table, $values);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    return undef;
}

sub replace {
    my ($self, $table, $values) = @_;
    $self->call_trigger(BEFORE_REPLACE => $table, $values);
    my ($sql, @binds) = $self->query_builder->insert($table, $values, {prefix => 'REPLACE INTO'});
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    my $last_insert_id = $self->last_insert_id;
    return $last_insert_id;
}

sub retrieve {
    my ($self, $table, $vals) = @_;
    Carp::croak("Missing mandatory parameter: table") unless defined $table;
    Carp::croak("Too many arguments") if @_ > 3;

    my $row_class = $self->get_row_class($table);
    my %where;
    if (ref $vals eq 'HASH') {
        %where = %$vals;
    } elsif (ref $vals) {
        Carp::croak("Bad arguments for retrieve: $vals");
    } else {
        my @pk = $row_class->primary_key;
        if (@pk != 1) {
            Carp::croak(sprintf("%s has %d primary keys, but you passed %d(%s)", $table, 0+@pk, 1, join(', ', @pk)));
        }
        $where{$pk[0]} = $vals;
    }
    my ($sql, @binds) = $self->query_builder->select($table, [\'*'], \%where);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    my $row = $sth->fetchrow_hashref;
    if ($row) {
        return $row_class->new($row);
    } else {
        return undef;
    }
}

sub update {
    my $self = shift;
    if (UNIVERSAL::isa($_[0], 'Karas::Row')) {
        my ($row, $set) = @_;
        $set ||= +{};
        $set = +{ %{$row->get_dirty_columns()}, %$set };
        my $where = $row->make_where_condition();
        $self->call_trigger(BEFORE_UPDATE_ROW => $row, $set);
        my $rows = $self->_update($row->table_name, $set, $where);
        $self->call_trigger(AFTER_UPDATE_ROW => $row, $set);
        return $rows;
    } else {
        my ($table_name, $set, $where) = @_;
        Carp::croak("Usage: \$db->update(\$table_name, \%set, \%where)") if ref $table_name;
        Carp::croak("Usage: \$db->update(\$table_name, \%set, \%where)") if @_!=3;
        $self->call_trigger(BEFORE_UPDATE_DIRECT => $table_name, $set, $where);
        my $rows = $self->_update($table_name, $set, $where);
        $self->call_trigger(AFTER_UPDATE_DIRECT => $table_name, $set, $where);
        return $rows;
    }
}

sub _update {
    my ($self, $table, $set, $where) = @_;
    Carp::croak("Missing mandatory parameter: table") unless defined $table;
    Carp::croak("Missing mandatory parameter: set")   unless defined $set;
    my ($sql, @binds) = $self->query_builder->update($table, $set, $where);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    return $sth->rows;
}

sub delete {
    my $self = shift;
    if (UNIVERSAL::isa($_[0], 'Karas::Row')) {
        my ($row) = @_;
        $self->call_trigger(BEFORE_DELETE_ROW => $row);
        my $where = $row->make_where_condition();
        my $retval = $self->_delete($row->table_name, $row->where);
        $self->call_trigger(AFTER_DELETE_ROW => $row);
        return $retval;
    } else {
        my ($table_name, $where);
        $self->call_trigger(BEFORE_DELETE_DIRECT => $table_name, $where);
        my $rows = $self->_delete($table_name, $where);
        $self->call_trigger(AFTER_DELETE_DIRECT => $table_name, $where);
        return $rows;
    }
}

sub _delete {
    my ($self, $table, $where) = @_;
    Carp::croak("Missing mandatory parameter: table") unless defined $table;
    Carp::croak("Missing mandatory parameter: where") unless defined $where;
    my ($sql, @binds) = $self->query_builder->delete($table, $where);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    return $sth->rows;
}

sub refetch {
    my ($self, $row) = @_;
    return ($self->search($row->table_name, $row->make_where_condition()))[0];
}

sub bulk_insert {
    my ($self, $table_name, $rows_data) = @_;
    Carp::croak("Missing mandatory parameter: table_name") unless defined $table_name;
    Carp::croak("rows_data must be ArrayRef") unless ref $rows_data eq 'ARRAY';

    if ($self->_driver_name eq 'mysql') {
        $self->call_trigger(BEFORE_BULK_INSERT => $table_name, $rows_data);
        my ($sql, @binds) = $self->query_builder->insert_multi($table_name, $rows_data);
        my $sth = $self->dbh->prepare($sql);
        $sth->execute(@binds);
        return $sth->rows;
    } else {
        # emulate bulk insert.
        $self->call_trigger(BEFORE_BULK_INSERT => $table_name, $rows_data);
        my $txn = $self->txn_scope();
        {
            # Do not run 'BEFORE_INSERT' hook for consistency between mysql.
            for my $row (@$rows_data) {
                my ($sql, @binds) = $self->query_builder->insert($table_name, $row);
                my $sth = $self->dbh->prepare($sql);
                $sth->execute(@binds);
            }
        }
        $txn->commit;
    }
}

sub insert_on_duplicate {
    my ($self, $table_name, $insert_values, $update_values) = @_;
    if ($self->_driver_name eq 'mysql') {
        $self->call_trigger(BEFORE_INSERT_ON_DUPLICATE => $table_name, $insert_values, $update_values);
        my ($sql, @binds) = $self->query_builder->insert_on_duplicate($table_name, $insert_values, $update_values);
        my $sth = $self->dbh->prepare($sql);
        $sth->execute(@binds);
    } else {
        Carp::croak("'insert_on_duplicate' method only supports mysql: " . $self->_driver_name);
    }

    return undef;
}

# taken from teng.
sub guess_table_name {
    my ( $class, $sql ) = @_;

    if ( $sql =~ /\sfrom\s+["`]?([\w]+)["`]?\s*/si ) {
        return $1;
    }
    return undef;
}

# -------------------------------------------------------------------------
# transaction
#
# -------------------------------------------------------------------------

sub txn_scope {
    my ($self) = @_;
    return $self->connection_manager->txn_scope;
}

# taken from Teng
sub last_insert_id {
    my ( $self, $table_name ) = @_;

    my $driver = $self->_driver_name;
    if ( $driver eq 'mysql' ) {
        return $self->dbh->{mysql_insertid};
    }
    elsif ( $driver eq 'Pg' ) {
        return $self->dbh->last_insert_id( undef, undef, undef, undef, { sequence => join( '_', $table_name, 'id', 'seq' ) } );
    }
    elsif ( $driver eq 'SQLite' ) {
        return $self->dbh->func('last_insert_rowid');
    }
    elsif ( $driver eq 'Oracle' ) {
        return undef;
    }
    else {
        Carp::croak "Don't know how to get last insert id for $driver";
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Karas - Yet another O/R Mapper.

=head1 SYNOPSIS

    use Karas;

    my $db = Karas->new(connect_info => ['dbi:SQLite::memory:', '', '']);
    $db->dbh->do(q{CREATE TABLE member (id int, name varchar(255) not null)});
    my $member = $db->insert('member' => {
        name => 'John',
    });
    $db->update($member, {
        name => 'Mills',
    });
    $member = $db->refetch($member);

=head1 DESCRIPTION

Karas is yet another O/R mapper.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 FEATURES

=over 4

=item fork safe connection management

=item nested, scoped transaction support using DBIx:TransactionManager

=back

=head1 METHODS

=head2 Constructor

=over 4

=item my $db = Karas->new(%args)

Create new instance of Karas.

You can pass following arguments as hash:

=over 4

=item connect_info(Required)

connect_info is an arguments for C<< DBI->connect >>.

=item query_builder(Optional)

This is a query builder. You need to pass the child class instance of SQL::Maker.

Default value is : C<< Karas::QueryBuilder->new() >>.

=back

=back

=head2 Connection

=over 4

=item $db->connect([@args])

Connect to Database immediately.

If you pass @args, $db->{connec_info} will upgrade by @args.

=item $db->reconnect([@args])

Reconnect to Database immediately.

If you pass @args, $db->{connec_info} will upgrade by @args.

=item $db->dbh()

Get a database handle. If the connection was closed, Karas reconnects automatically.

=back

=head2 SQL Operations

=over 4

=item my @rows = $db->search($table, $where[, $opt])

Search rows from database. For more details, please see L<SQL::Maker>.

=item my $count = $db->count($table[, $where])

Count rows by $where.

=item my ($rows, $pager) = $db->search_with_pager($table, $where[, $opt])

I<$pager> is instance of Data::Page::NoTotalEntries.

=item my @rows = $db->search_by_sql($sql, $binds[, $table_name]);

Search rows by SQL.

I<$table_name> is optional. Karas finds table name by $sql automatically.

=item my $row = $db->insert($table, $values);

Insert row to database. And refetch row from database.

=item $db->fast_insert($table, $values);

Insert row to database.

=item $db->replace($table, $values);

Replace into row to database.

=item $db->update($row, \%opts)

Update row object by \%opts.

=item my $affected_rows = $db->update($table_name, $set, $where)

Update I<$table_name> set I<$set> where I<$where>.

=item $db->delete($row);

Delete row object from database.

=item $db->delete($table_name, $where)

Delete $table_name where $where.

=item $db->refetch($row)

Refetch I<$row> object from database.

=item $db->bulk_insert($table_name, $rows_data)

    $db->bulk_insert('member', [
        +{ name => 'John', email => 'john@example.com' },
        +{ name => 'Ben',  email => 'ben@example.com' },
    ])

This is a bulk insert method. see L<SQL::Maker::Plugin::InsertMulti>.

=back

=head2 Row class map management

=over 4

=item $db->get_row_class($table_name);

Clear row class from table name.

=back

=head2 Transaction

=over 4

=item my $guard = $db->txn_scope();

Start transaction scope with L<DBIx::TransactionManager>. See L<DBIx::TransactionManager> for more details.

=back

=head1 Plugins

=over 4

=item Karas->load_plugin($name[, $args])

Load plugin and install it. C<< $name >> is a class name of plugin.

You can use two style of $name. If you want to use plugin under the 'Karas::Plugin::Name' namespace, you just write 'Name' part.
If you want to put your plugin on your favorite namespace, you can pass'+My::Own::Plugin' as C<< $name >>.

C<< $args >> is a argument for C<< Karas::Plugin::Foo->new($args) >>.

=back

=head2 Utilities

=over 4

=item $db->last_insert_id()

Get a last_insert_id from $dbh.

=back

=head1 ROW CLASS DETECTION

Karas loads row class from your load path. If you are using Karas class directly, Karas does not loads any row class.
But if you use it as a parent class like following:

    parent MyDB;
    use parent qw/Karas/;

=head1 FAQ

=over 4

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
