package Fey::Object::Table;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::Literal::Function;
use Fey::Placeholder;
use Fey::SQL;
use Fey::Table;
use List::AllUtils qw( all );
use Object::ID qw( object_id );
use Scalar::Util qw( blessed );
use Try::Tiny;

use Fey::Exceptions qw( param_error );
use Fey::ORM::Exceptions qw( no_such_row );

use Moose;

override new => sub {
    my $class = shift;

    if ( $class->meta()->_object_cache_is_enabled() ) {
        my $instance
            = $class->meta()->_search_cache( ref $_[0] ? $_[0] : {@_} );

        return $instance if $instance;
    }

    my $instance;
    my @args = @_;

    $class->_ClearConstructorError();

    try {
        $instance = super();
    }
    catch {
        die $_ unless blessed $_ && $_->isa('Fey::Exception::NoSuchRow');
        $class->_SetConstructorError($_);
    };

    return unless $instance;

    $class->meta()->_write_to_cache($instance)
        if $class->meta()->_object_cache_is_enabled();

    return $instance;
};

# I'd like to use MX::ClassAttribute but trying to apply this to each
# Fey::ORM::Table-using class causes all sorts of weird errors.
{
    my %E;

    sub ConstructorError {
        my $class = shift;

        return $E{$class};
    }

    sub _SetConstructorError {
        my $class = shift;

        $E{$class} = shift;
    }

    sub _ClearConstructorError {
        my $class = shift;

        delete $E{$class};
    }
}

sub BUILD {
    my $self = shift;
    my $p    = shift;

    if ( delete $p->{_from_query} ) {
        $self->_require_pk($p);

        return;
    }

    $self->_load_from_dbms($p);

    return;
}

sub _require_pk {
    my $self = shift;
    my $p    = shift;

    return
        if all { defined $p->{$_} }
    map { $_->name() } @{ $self->Table()->primary_key() };

    my $package = ref $self;
    param_error
        "$package->new() requires that you pass the primary key if you set _from_query to true.";
}

sub EnableObjectCache {
    my $class = shift;

    $class->meta()->_set_object_cache_is_enabled(1);
}

sub DisableObjectCache {
    my $class = shift;

    $class->meta()->_set_object_cache_is_enabled(0);
}

sub ClearObjectCache {
    my $class = shift;

    $class->meta()->_clear_object_cache();
}

sub _load_from_dbms {
    my $self = shift;
    my $p    = shift;

    for my $key ( @{ $self->Table()->candidate_keys() } ) {
        my @names = map { $_->name() } @{$key};
        next unless all { defined $p->{$_} } @names;

        return if $self->_load_from_key( $key, [ @{$p}{@names} ] );
    }

    my $error = 'Could not find a row in ' . $self->Table()->name();
    $error .= ' matching the values you provided to the constructor.';

    no_such_row $error;
}

sub _load_from_key {
    my $self = shift;
    my $key  = shift;
    my $bind = shift;

    my $select = $self->_SelectSQLForKey($key);

    return 1 if $self->_get_column_values( $select, $bind );

    my $error = 'Could not find a row in ' . $self->Table()->name();
    $error .= ' where ';

    my @where;

    ## no critic (ControlStructures::ProhibitCStyleForLoops)
    for ( my $i = 0; $i < @{$key}; $i++ ) {
        push @where, $key->[$i]->name() . q{ = } . $bind->[$i];
    }
    ## use critic

    $error .= join ', ', @where;

    no_such_row $error;
}

# Based on discussions on #moose, this could be done more elegantly
# with a custom instance metaclass that lazily initializes a batch of
# attributes at once.
sub _get_column_values {
    my $self   = shift;
    my $select = shift;
    my $bind   = shift;

    my $dbh = $self->_dbh($select);

    my $sth = $dbh->prepare( $self->_sql_string( $select, $dbh ) );

    $sth->execute( @{$bind} );

    my %col_values;
    $sth->bind_columns( \( @col_values{ @{ $sth->{NAME} } } ) );

    my $fetched = $sth->fetch();

    $sth->finish();

    return unless $fetched;

    $self->_set_column_values_from_hashref( \%col_values );

    return \%col_values;
}

sub _set_column_values_from_hashref {
    my $self   = shift;
    my $values = shift;

    for my $col ( keys %{$values} ) {
        my $set_meth = q{_set_} . $col;

        $self->$set_meth( $values->{$col} );
    }
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _get_column_value {
    my $self = shift;

    my $col_values = $self->_get_column_values(
        $self->meta()->_select_by_pk_sql(),
        [ $self->pk_values_list() ],
    );

    my $name = shift;

    return $col_values->{$name};
}
## use critic

sub pk_values_list {
    my $self = shift;

    my @cols = ( map { $_->name() } @{ $self->Table()->primary_key() } );

    return map { $self->_deflated_value($_) } @cols;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _MakeSelectByPKSQL {
    my $class = shift;

    return $class->_SelectSQLForKey( $class->Table->primary_key() );
}
## use critic

sub _SelectSQLForKey {
    my $class = shift;
    my $key   = shift;

    my $cache = $class->meta()->_select_sql_cache();

    my $select = $cache->get($key);

    return $select if $select;

    my $table = $class->Table();

    my @select = $table->columns();

    $select = $class->SchemaClass()->SQLFactoryClass()->new_select();
    $select->select( sort { $a->name() cmp $b->name() } @select );
    $select->from($table);
    $select->where( $_, '=', Fey::Placeholder->new() ) for @{$key};

    $cache->store( $key => $select );

    return $select;
}

sub insert {
    my $class = shift;
    my %p     = @_;

    return $class->insert_many( \%p );
}

sub insert_many {
    my $class = shift;
    my @rows  = @_;

    my $insert = $class->_insert_for_data( $rows[0] );

    my $dbh = $class->_dbh($insert);

    my $sth = $dbh->prepare( $class->_sql_string( $insert, $dbh ) );

    my @auto_inc_columns = (
        grep { !exists $rows[0]->{$_} }
        map  { $_->name() }
        grep { $_->is_auto_increment() } $class->Table->columns()
    );

    my $table_name = $class->Table()->name();

    my @non_literal_row_keys;
    my @literal_row_keys;
    my @ref_row_keys;

    for my $key ( sort keys %{ $rows[0] } ) {
        my $val = $rows[0]{$key};

        if (
               defined $val
            && blessed $val
            && $val->can('does')
            && (   $val->does('Fey::Role::IsLiteral')
                || $val->does('Fey::Role::SQL::ReturnsData') )
            ) {
            push @literal_row_keys, $key;
            push @ref_row_keys,     $key;
        }
        else {
            push @non_literal_row_keys, $key;
            push @ref_row_keys,         $key
                if ref $val;
        }
    }

    my @bind_attributes
        = $class->_bind_attributes_for( $dbh, @non_literal_row_keys );

    my $wantarray = wantarray;

    my @objects;
    for my $row (@rows) {
        push @objects,
            $class->_insert_one_row(
            $row,
            $dbh,
            $sth,
            \@non_literal_row_keys,
            \@ref_row_keys,
            \@bind_attributes,
            \@auto_inc_columns,
            $table_name,
            $wantarray,
            );
    }

    return $wantarray ? @objects : $objects[0];
}

sub _bind_attributes_for {
    my $self = shift;
    my $dbh  = shift;
    my @keys = @_;

    return unless $dbh->{Driver}{Name} eq 'Pg';

    my @attr = map {
        lc $self->Table()->column($_)->type() eq 'bytea'
            ? { pg_type => DBD::Pg::PG_BYTEA() }
            : {}
    } @keys;

    return unless grep { keys %{$_} } @attr;

    return @attr;
}

## no critic (Subroutines::ProhibitManyArgs)
sub _insert_one_row {
    my $class = shift;

    # This is really grotesque
    my $row                  = shift;
    my $dbh                  = shift;
    my $sth                  = shift;
    my $non_literal_row_keys = shift;
    my $ref_row_keys         = shift;
    my $bind_attributes      = shift;
    my $auto_inc_columns     = shift;
    my $table_name           = shift;
    my $wantarray            = shift;

    $class->_sth_execute(
        $sth,
        [
            map { $class->_deflated_value( $_, $row->{$_} ) }
                @{$non_literal_row_keys}
        ],
        $bind_attributes,
    );

    return unless defined $wantarray;

    my %auto_inc;
    for my $col ( @{$auto_inc_columns} ) {
        $auto_inc{$col}
            = $dbh->last_insert_id( undef, undef, $table_name, $col );
    }

    delete @{$row}{ @{$ref_row_keys} }
        if @{$ref_row_keys};

    return $class->new( %{$row}, %auto_inc, _from_query => 1 );
}

sub _sth_execute {
    my $self = shift;
    my $sth  = shift;
    my $vals = shift;
    my $attr = shift;

    if ( @{$attr} ) {
        ## no critic (ControlStructures::ProhibitCStyleForLoops)
        for ( my $i = 0; $i < @{$vals}; $i++ ) {
            $sth->bind_param( $i + 1, $vals->[$i], $attr->[$i] );
        }
        ## use critic

        return $sth->execute();
    }
    else {
        return $sth->execute( @{$vals} );
    }
}

sub _deflated_value {
    my $self = shift;
    my $name = shift;
    my $val  = @_ ? shift : $self->$name();

    my $meth = $self->meta()->deflator_for($name);

    return $meth ? $self->$meth($val) : $val;
}

sub _insert_for_data {
    my $class = shift;
    my $data  = shift;

    my $insert = $class->SchemaClass()->SQLFactoryClass()->new_insert();

    my $table = $class->Table();

    $insert->into( $table->columns( sort keys %{$data} ) );

    my $ph = Fey::Placeholder->new();

    my @vals = (
        map {
            $_ => (
                defined $data->{$_}
                    && blessed $data->{$_}
                    && $data->{$_}->can('does')
                    && ( $data->{$_}->does('Fey::Role::IsLiteral')
                    || $data->{$_}->does('Fey::Role::SQL::ReturnsData') )
                ? $data->{$_}
                : $ph
                )
            }
            sort keys %{$data}
    );

    $insert->values(@vals);

    return $insert;
}

sub update {
    my $self = shift;
    my %p    = @_;

    my $update = $self->SchemaClass()->SQLFactoryClass()->new_update();

    my $table = $self->Table();

    $update->update($table);

    $update->set(
        map { $table->column($_) => $self->_deflated_value( $_, $p{$_} ) }
        sort keys %p
    );

    for my $col ( @{ $table->primary_key() } ) {
        my $name = $col->name();

        $update->where( $col, '=', $self->_deflated_value($name) );
    }

    my $dbh = $self->_dbh($update);

    my $sth = $dbh->prepare( $self->_sql_string( $update, $dbh ) );

    my @attr = $self->_bind_attributes_for(
        $dbh,
        (
            sort keys %p,
            map { $_->name() } @{ $table->primary_key() }
        ),
    );

    $self->_sth_execute( $sth, [ $update->bind_params() ], \@attr );

    for my $k ( sort keys %p ) {
        if ( ref $p{$k} ) {
            my $clear = q{_clear_} . $k;
            $self->$clear();
        }
        else {
            my $set_meth = q{_set_} . $k;
            $self->$set_meth( $p{$k} );
        }
    }

    return;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub delete {
    my $self = shift;

    my $delete = $self->SchemaClass()->SQLFactoryClass()->new_delete();

    my $table = $self->Table();

    $delete->from($table);

    for my $col ( @{ $table->primary_key() } ) {
        my $name = $col->name();

        $delete->where( $col, '=', $self->_deflated_value($name) );
    }

    my $dbh = $self->_dbh($delete);

    $dbh->do(
        $self->_sql_string( $delete, $dbh ),
        {},
        $delete->bind_params()
    );

    return;
}
## use critic

sub _dbh {
    my $self = shift;
    my $sql  = shift;

    my $source = $self->SchemaClass()->DBIManager()->source_for_sql($sql);

    die "Could not get a source for this sql ($sql)"
        unless $source;

    return $source->dbh();
}

sub pk_values_hash {
    my $self = shift;

    my @vals = $self->pk_values_list()
        or return;

    my @cols = ( map { $_->name() } @{ $self->Table()->primary_key() } );

    return map { $cols[$_] => $vals[$_] } 0 .. $#vals;
}

sub Count {
    my $class = shift;

    my $select = $class->meta()->_count_sql();

    my $dbh = $class->_dbh($select);

    my $row
        = $dbh->selectcol_arrayref( $class->_sql_string( $select, $dbh ) );

    return $row->[0];
}

sub Table {
    my $class = shift;

    return $class->meta()->table();
}

sub SchemaClass {
    my $class = shift;

    return $class->meta()->schema_class();
}

sub _sql_string {
    my $self = shift;
    my $sql  = shift;
    my $dbh  = shift;

    my $cache = $self->meta()->_sql_string_cache();

    return $cache->{ object_id($sql) . object_id($dbh) } ||= $sql->sql($dbh);
}

__PACKAGE__->meta()->make_immutable( inline_constructor => 0 );

1;

# ABSTRACT: Base class for table-based objects

__END__

=pod

=head1 NAME

Fey::Object::Table - Base class for table-based objects

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  package MyApp::User;

  use Fey::ORM::Table;

  has_table(...);

=head1 DESCRIPTION

This class is a the base class for all table-based objects. It
implements a large amount of the core L<Fey::ORM> functionality,
including CRUD (create, update, delete) and loading of data from the
DBMS.

=head1 METHODS

This class provides the following methods:

=head2 $class->new(...)

This method overrides the default C<Moose::Object> constructor in
order to implement cache management.

By default, object caching is disabled. In that case, this method lets
its parent class do most of the work. However, unlike the standard
Moose constructor, this method may sometimes not return an object. If
it attempts to load object data from the DBMS and cannot find anything
matching the parameters given to the constructor, it will return
false.

If the constructor fails, you can check the value of C<<
$class->ConstructorError >> for the error message. This is done so that
calling the constructor does not overwrite any value already in C<$@>.

If caching is enabled, then this method will attempt to find a
matching object in the cache. A match is determined by looking for an
object which has a candidate key with the same values as are passed to
the constructor.

If no match is found, it attempts to create a new object. If this
succeeds, it stores it in the cache before returning it.

=head3 Constructor Parameters

The constructor accepts any attribute of the class as a
parameter. This includes any column-based attributes, as well as any
additional attributes defined by C<has_one()> or C<has_many()>. Of
course, if you disabled caching for C<has_one()> or C<has_many()>
relationships, then they are implemented as simple methods, not
attributes.

If you define additional methods via Moose's C<has()> function, and
these will be accepted by the constructor as well.

Finally, the constructor accepts a parameter C<_from_query>. This
tells the constructor that the parameters passed to the constructor
are the result of a C<SELECT>. This stops the C<BUILD()> method from
attempting to load the object from the DBMS. However, you still must
pass values for the primary key, so that the object is identifiable in
the DBMS.

=head2 $class->ConstructorError()

If the constructor does not return an object, this will always contain the
error message from the constructor. This should always be something like
"Could not a find a row in SomeTable matching the values you provided to the
constructor" or "Could not find a row in SomeTable where table_id = 42".

This error is cleared each time the class's constructor is called.

=head2 $class->EnableObjectCache()

=head2 $class->DisableObjectCache()

These methods enable or disable the object cache for the calling
class.

=head2 $class->Count()

Returns the number of rows in the class's associated table.

=head2 $class->ClearObjectCache()

Clears the object cache for the calling class.

=head2 $class->Table()

Returns the L<Fey::Table> object passed to C<has_table()>.

=head2 $class->SchemaClass()

Returns the name of the class associated with the class's table's
schema.

=head2 $class->insert(%values)

Given a hash of column names and values, this method inserts a new row
for the class's table, and returns a new object for that row.

The values for the columns can be plain scalars or object. Values will
be passed through the appropriate deflators. You can also pass
L<Fey::Literal> objects of any type.

As an optimization, no object will be created in void context.

=head2 $class->insert_many( \%values, \%values, ... )

This method allows you to insert multiple rows efficiently. It expects
an array of hash references. Each hash reference should contain the
same set of column names as its keys. The advantage of using this
method is that under the hood it uses the same C<DBI> statement handle
repeatedly. If you were to call C<< $class->insert() >> repeatedly it
would have to recreate the same SQL and DBI statement handle
repeatedly.

In scalar context, it returns the first object created. In list
context, it returns all the objects created.

As an optimization, no objects will be created in void context.

=head2 $object->update(%values)

This method accepts a hash of column keys and values, just like C<<
$class->insert() >>. However, it instead updates the values for an
existing object's row. It will also make sure that the object's
attributes are updated properly. In some cases, it will just clear the
attribute, forcing it to be reloaded the next time it is
accessed. This is necessary when the update value was a
L<Fey::Literal>, since that could be a function that gets interpreted
by the DBMS, such as C<NOW()>.

=head2 $object->delete()

This method deletes the object's associated row from the DBMS.

The object is still usable after this method is called, but if you
attempt to call any method that tries to access the DBMS it will
probably blow up.

=head2 $object->pk_values_hash()

Returns a hash representing the names and values for the object's
primary key. The values are returned in their raw form, regardless of
any transforms specific for a primary key column.

This may return an empty hash if the primary key for the object has
not yet been determined. This can happen if you try to call this
method on an object before its attributes have been fetched from the
dbms.

=head2 $object->pk_values_list()

Returns a list of values for the object's primary key. The values are
returned in the same order as C<< $self->primary_key() >> returns the
columns. The values are returned in their raw form, regardless of any
transforms specific for a primary key column.

This may return an empty list if the primary key for the object
has not yet been determined.

=head1 METHODS FOR SUBCLASSES

Since your table-based class will be a subclass of this object, there
are several methods you may want to use that are not intended for use
outside of your subclasses. You may also want to subclass some of
these methods in this class.

=head2 $class->_dbh($sql)

Given a L<Fey::SQL> object, this method returns an appropriate C<DBI>
object for that SQL. Internally, it calls C<source_for_sql()> on the
schema class's L<Fey::DBIManager> object and then calls C<<
$source->dbh() >> on the source.

If there is no source for the given SQL, it will die.

=head2 $object->_load_from_dbms($params)

This method will be called as part of object construction (unless
C<_from_query> was true).

By default, this method attempts to find a row in the associated table
by looking at each of the table's candidate keys in turn. If the
parameters passed to the constructor include values for all parts of a
key, it does a select to find a matching row.

You can override this method in order to attempt to load an object
based on some other method. For example, if your user table stores a
username and a hashed password, you could accept an I<unhashed>
password, and then do a lookup based on the hashed value.

This method is expected to create a C<SELECT> statement and then pass
the statement and bind parameters to C<< $object->_get_column_values()
>>.

On success, this method should simply return. If it fails, it should throw a
Fey::Exception::NoSuchRow exception. See L<Fey::ORM::Exceptions> for details.

=head2 $object->_get_column_values( $select, $bind_params )

This method takes a C<SELECT> statement and an array reference of bind
parameters. The C<SELECT> is expected to find a single row, which
should correspond to the current object. If it finds a row, it sets
the corresponding attributes in the object based on the values returns
by the C<SELECT>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
