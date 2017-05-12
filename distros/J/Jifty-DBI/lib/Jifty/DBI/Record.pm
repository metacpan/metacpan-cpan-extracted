package Jifty::DBI::Record;

use strict;
use warnings;

use Class::ReturnValue  ();
use Lingua::EN::Inflect ();
use Jifty::DBI::Column  ();
use UNIVERSAL::require  ();
use Scalar::Util qw(blessed);
use Class::Trigger;    # exports by default
use Scalar::Defer 'force';

use base qw/
    Class::Data::Inheritable
    Jifty::DBI::HasFilters
    /;

our $VERSION = '0.01';

Jifty::DBI::Record->mk_classdata('COLUMNS');
Jifty::DBI::Record->mk_classdata('TABLE_NAME');
Jifty::DBI::Record->mk_classdata('_READABLE_COLS_CACHE');
Jifty::DBI::Record->mk_classdata('_WRITABLE_COLS_CACHE');
Jifty::DBI::Record->mk_classdata('_COLUMNS_CACHE');
Jifty::DBI::Record->mk_classdata('RECORD_MIXINS' => []);

=head1 NAME

Jifty::DBI::Record - Superclass for records loaded by Jifty::DBI::Collection

=head1 SYNOPSIS

  package MyRecord;
  use base qw/Jifty::DBI::Record/;

=head1 DESCRIPTION

Jifty::DBI::Record encapsulates records and tables as part of the L<Jifty::DBI>
object-relational mapper.

=head1 METHODS

=head2 new ARGS

Instantiate a new, empty record object.

ARGS is a hash used to pass parameters to the C<_init()> function.

Unless it is overloaded, the _init() function expects one key of
'handle' with a value containing a reference to a Jifty::DBI::Handle
object.

=cut

sub new {
    my $proto = shift;

    my $class = ref($proto) || $proto;
    my $self = {};
    bless( $self, $class );

    $self->_init_columns() unless $self->COLUMNS;
    $self->input_filters('Jifty::DBI::Filter::Truncate');

    if ( scalar(@_) == 1 ) {
        Carp::cluck(
            "new(\$handle) is deprecated, use new( handle => \$handle )");
        $self->_init( handle => shift );
    } else {
        $self->_init(@_);
    }

    return $self;
}

# Not yet documented here.  Should almost certainly be overloaded.
sub _init {
    my $self = shift;
    my %args = (@_);
    if ( $args{'handle'} ) {
        $self->_handle( $args{'handle'} );
    }

}

sub import {
    my $class = shift;
    my ($flag) = @_;
    if ( $class->isa(__PACKAGE__) and defined $flag and $flag eq '-base' ) {
        my $descendant = (caller)[0];
        unless ( $descendant->isa($class) ) {
            no strict 'refs';
            push @{ $descendant . '::ISA' }, $class
        }
        shift;

        # run the schema callback
        my $callback = shift;
        $callback->() if $callback;
    }
    $class->SUPER::import(@_);

    # Turn off redefinition warnings in the caller's scope
    @_ = ( warnings => 'redefine' );
    goto &warnings::unimport;
}

=head2 id

Returns this row's primary key.

=cut

sub id {
    my $pkey = $_[0]->_primary_key();
    my $ret  = $_[0]->{'values'}->{$pkey};
    return $ret;
}

=head2 primary_keys

Return a hash of the values of our primary keys for this function.

=cut

sub primary_keys {
    my $self = shift;
    my %hash
        = map { $_ => $self->{'values'}->{$_} } @{ $self->_primary_keys };
    return (%hash);
}

=head2 _accessible COLUMN ATTRIBUTE

Private method. 

DEPRECATED

Returns undef unless C<COLUMN> has a true value for C<ATTRIBUTE>.

Otherwise returns C<COLUMN>'s value for that attribute.


=cut

sub _accessible {
    my $self        = shift;
    my $column_name = shift;
    my $attribute   = lc( shift || '' );
    my $col         = $self->column($column_name);
    return undef unless ( $col and $col->can($attribute) );
    return $col->$attribute();

}

=head2 _primary_keys

Return our primary keys. (Subclasses should override this, but our
default is that we have one primary key, named 'id'.)

=cut

sub _primary_keys {
    my $self = shift;
    return ['id'];
}

sub _primary_key {
    my $self  = shift;
    my $pkeys = $self->_primary_keys();
    die "No primary key" unless ( ref($pkeys) eq 'ARRAY' and $pkeys->[0] );
    die "Too many primary keys" unless ( scalar(@$pkeys) == 1 );
    return $pkeys->[0];
}

=head2 _init_columns

Sets up the primary key columns.

=cut

sub _init_columns {
    my $self = shift;

    return if defined $self->COLUMNS;

    $self->COLUMNS( {} );

    foreach my $column_name ( @{ $self->_primary_keys } ) {
        my $column = $self->add_column($column_name);
        $column->writable(0);
        $column->readable(1);
        $column->type('serial');
        $column->mandatory(1);

        $self->_init_methods_for_column($column);
    }

}

=head2 _init_methods_for_columns

This is an internal method responsible for calling
L</_init_methods_for_column> for each column that has been configured.

=cut

sub _init_methods_for_columns {
    my $self = shift;

    for my $column ( sort keys %{ $self->COLUMNS || {} } ) {
        $self->_init_methods_for_column( $self->COLUMNS->{$column} );
    }
}

=head2 schema_version

If present, this method must return a string in '1.2.3' format to be
used to determine which columns are currently active in the
schema. That is, this value is used to determine which columns are
defined, based upon comparison to values set in C<till> and C<since>.

If no implementation is present, the "latest" schema version is
assumed, meaning that any column defining a C<till> is not active and
all others are.

=head2 _init_methods_for_column COLUMN

This method is used internally to update the symbol table for the
record class to include an accessor and mutator for each column based
upon the column's name.

In addition, if your record class defines the method
L</schema_version>, it will automatically generate methods according
to whether the column currently exists for the current application
schema version returned by that method. The C<schema_version> method
must return a value in the same form used by C<since> and C<till>.

If the column doesn't currently exist, it will create the methods, but
they will die with an error message stating that the column does not
exist for the current version of the application. If it does exist, a
normal accessor and mutator will be created.

See also L<Jifty::DBI::Column/active>, L<Jifty::DBI::Schema/since>,
L<Jifty::DBI::Schema/till> for more information.

=cut

sub _init_methods_for_column {
    my $self   = $_[0];
    my $column = $_[1];
    my $column_name
        = ( $column->aliased_as ? $column->aliased_as : $column->name );
    my $package = ref($self) || $self;

    # Make sure column has a record_class set as not all columns are added
    # through add_column
    $column->record_class($package) if not $column->record_class;

    # Check for the correct column type when the Storable filter is in use
    if ( grep { $_ eq 'Jifty::DBI::Filter::Storable' }
        ( $column->input_filters, $column->output_filters )
         and not grep { $_ eq 'Jifty::DBI::Filter::base64' }
        ( $column->input_filters, $column->output_filters )
         and $column->type !~ /^(blob|bytea)$/i )
    {
        die "Column '$column_name' in @{[$column->record_class]} "
            . "uses the Storable filter but is not of type 'blob'.\n";
    }

    no strict 'refs';    # We're going to be defining subs

    if ( not $self->can($column_name) ) {
        # Accessor
        my $subref;

        if ($column->computed) {
            $subref = sub {
                Carp::croak("column '$column_name' in $package is computed but has no corresponding method");
            };
        }
        elsif ( $column->active ) {

            if ( $column->readable ) {
                if (UNIVERSAL::isa(
                        $column->refers_to, "Jifty::DBI::Record"
                    )
                    )
                {
                    $subref = sub {
                        if ( @_ > 1 ) {
                            Carp::carp
                                "Value passed to column $column_name accessor.  You probably want to use the mutator.";
                        }
                        # This should be using _value, so we acl_check
                        # appropriately, except the acl checks often
                        # involve object references.  So even if you
                        # don't have rights to $object->foo_id,
                        # $object->foo->id will always have to
                        # work. :/
                        $_[0]->_to_record( $column_name,
                            $_[0]->__value($column_name) );
                    };
                } elsif (
                    UNIVERSAL::isa(
                        $column->refers_to, "Jifty::DBI::Collection"
                    )
                    )
                {
                    $subref = sub { $_[0]->_collection_value($column_name) };
                } else {
                    $subref = sub {
                        if ( @_ > 1 ) {
                            Carp::carp
                                "Value passed to column $column_name accessor.  You probably want to use the mutator.";
                        }
                        return ( $_[0]->_value($column_name) );
                    };
                }
            } else {
                $subref = sub { return '' }
            }
        } else {

           # XXX sterling: should this be done with Class::ReturnValue instead
            $subref = sub {
                Carp::croak(
                    "column $column_name is not available for $package for schema version "
                        . $self->schema_version );
            };
        }
        *{ $package . "::" . $column_name } = $subref;

    }

    if ( not $self->can( "set_" . $column_name ) ) {

        # Mutator
        my $subref;
        if ( $column->active ) {
            if ( $column->writable ) {
                if (UNIVERSAL::isa(
                        $column->refers_to, "Jifty::DBI::Record"
                    )
                    )
                {
                    $subref = sub {
                        my $self = shift;
                        my $val  = shift;

                        if (UNIVERSAL::isa( $val, 'Jifty::DBI::Record' )) {
                            my $col = $self->column($column_name);
                            my $by  = defined $col->by ? $col->by : 'id';
                            $val = $val->$by;
                        }

                        return (
                            $self->_set(
                                column => $column_name,
                                value  => $val
                            )
                        );
                    };
                } elsif (
                    UNIVERSAL::isa(
                        $column->refers_to, "Jifty::DBI::Collection"
                    )
                    )
                {    # XXX elw: collections land here, now what?
                    my $ret = Class::ReturnValue->new();
                    my $message
                        = "Collection column '$column_name' not writable";
                    $ret->as_array( 0, $message );
                    $ret->as_error(
                        errno        => 3,
                        do_backtrace => 0,
                        message      => $message
                    );
                    $subref = sub { return ( $ret->return_value ); };
                } else {
                    $subref = sub {
                        return (
                            $_[0]->_set(
                                column => $column_name,
                                value  => $_[1]
                            )
                        );
                    };
                }
            } else {
                my $ret     = Class::ReturnValue->new();
                my $message = 'Immutable column';
                $ret->as_array( 0, $message );
                $ret->as_error(
                    errno        => 3,
                    do_backtrace => 0,
                    message      => $message
                );
                $subref = sub { return ( $ret->return_value ); };
            }
        } else {

           # XXX sterling: should this be done with Class::ReturnValue instead
            $subref = sub {
                Carp::croak(
                    "column $column_name is not available for $package for schema version "
                        . $self->schema_version );
            };
        }
        *{ $package . "::" . "set_" . $column_name } = $subref;
    }
}

=head2 null_reference 

By default, Jifty::DBI::Record will return C<undef> for non-existent
foreign references which don't exist.  That is, if each Employee
C<refers_to> a Department, but isn't required to,
C<<$model->department>> will return C<undef> for employees not in a
department.

Overriding this method to return 0 will cause it to return a record
with no id.  That is, C<<$model->department>> will return a Department
object, but C<<$model->department->id>> will be C<undef>.

=cut

sub null_reference {
    return 1;
}

=head2 _to_record COLUMN VALUE

This B<PRIVATE> method takes a column name and a value for that column. 

It returns C<undef> unless C<COLUMN> is a valid column for this record
that refers to another record class.

If it is valid, this method returns a new record object with an id
of C<VALUE>.

=cut

sub _to_record {
    my $self        = shift;
    my $column_name = shift;
    my $value       = shift;

    my $column        = $self->column($column_name);
    my $classname     = $column->refers_to();
    my $remote_column = $column->by() || 'id';

    return undef if not defined $value and $self->null_reference;
    return undef unless $classname;
    return unless UNIVERSAL::isa( $classname, 'Jifty::DBI::Record' );

    if ( my $prefetched = $self->prefetched($column_name) ) {
        return $prefetched;
    }

    my $object = $classname->new( $self->_new_record_args );
    $object->load_by_cols( $remote_column => $value ) if defined $value;
    return $object;
}

sub _new_record_args {
    my $self = shift;
    return ( handle => $self->_handle );
}

sub _collection_value {
    my $self        = shift;
    my $column_name = shift;

    my $column    = $self->column($column_name);
    my $classname = $column->refers_to();

    return undef unless $classname;
    return unless UNIVERSAL::isa( $classname, 'Jifty::DBI::Collection' );

    if ( my $prefetched = $self->prefetched($column_name) ) {
        return $prefetched;
    }

    my $coll = $classname->new( $self->_new_collection_args );
    $coll->limit( column => $column->by, value => $self->id )
        if $column->by and $self->id;
    return $coll;
}

sub _new_collection_args {
    my $self = shift;
    return ( handle => $self->_handle );
}

=head2 prefetched NAME

Returns the prefetched value for column of property C<NAME>, if it
exists.

=cut

sub prefetched {
    my $self        = shift;
    my $column_name = shift;
    if (@_) {
        my $column = $self->column($column_name);
        if ( $column and not $column->refers_to ) {
            warn "$column_name isn't supposed to be an object reference!";
            return;
        } elsif ( $column
            and not UNIVERSAL::isa( $_[0], $column->refers_to ) )
        {
            warn "$column_name is supposed to be a @{[$column->refers_to]}!";
        } else {
            $self->{'_prefetched'}->{$column_name} = shift;
        }
    } else {
        return $self->{'_prefetched'}->{$column_name};
    }
}

=head2 add_column

=cut

sub add_column {
    my $self = shift;
    my $name = shift;

    #$name = lc $name;

    $self->COLUMNS->{$name} = Jifty::DBI::Column->new()
        unless exists $self->COLUMNS->{$name};
    $self->_READABLE_COLS_CACHE(undef);
    $self->_WRITABLE_COLS_CACHE(undef);
    $self->_COLUMNS_CACHE(undef);
    $self->COLUMNS->{$name}->name($name);

    my $class = ref($self) || $self;
    $self->COLUMNS->{$name}->record_class($class);

    return $self->COLUMNS->{$name};
}

=head2 column

    my $column = $self->column($column_name);

Returns the L<Jifty::DBI::Column> object of the specified column name.

=cut

sub column {
    my $self = shift;
    my $name = ( shift || '' );
    my $col  = $self->_columns_hashref;
    return undef unless $col && exists $col->{$name};
    return $col->{$name};

}

=head2 columns

    my @columns = $record->columns;

Returns a sorted list of a $record's @columns.

=cut

sub columns {
    my $self = shift;
    return @{
        $self->_COLUMNS_CACHE() || $self->_COLUMNS_CACHE(
            [ grep { $_->active } $self->all_columns ]
        )
    };
}

=head2 all_columns

  my @all_columns = $record->all_columns;

Returns all the columns for the table, even those that are inactive.

=cut

sub all_columns {
    my $self = shift;

    # Not cached because it's not expected to be used often
    return sort {
        ((($b->type || '') eq 'serial') <=> (($a->type || '') eq 'serial'))
        or       (($a->sort_order || 0) <=> ($b->sort_order || 0))
        or                   ( $a->name cmp $b->name )
    } values %{ $self->_columns_hashref }
}

sub _columns_hashref {
    my $self = shift;

    return ( $self->COLUMNS || {} );
}

=head2 readable_attributes

Returns the list of this table's readable columns. They are first sorted so
that primary keys come first, and then they are sorted in alphabetical order.

=cut

sub readable_attributes {
    my $self = shift;

    my %is_primary = map { $_ => 1 } @{ $self->_primary_keys };

    return @{ $self->_READABLE_COLS_CACHE() || $self->_READABLE_COLS_CACHE([
        map  { $_->name }
        sort { do {
            no warnings 'uninitialized';
            ($is_primary{$b->name} <=> $is_primary{$a->name})
            ||
            ($a->name cmp $b->name)
        } }
        grep { $_->readable }
        $self->columns
    ])};
}

=head2 serialize_metadata

Returns a hash which describes how this class is stored in the
database.  Right now, the keys are C<class>, C<table>, and
C<columns>. C<class> and C<table> return simple scalars, but
C<columns> returns a hash of C<name =&gt; value> pairs for all the
columns in this model. See C<Jifty::DBI::Column/serialize_metadata>
for the format of that hash.


=cut

sub serialize_metadata {
    my $self = shift;
    return {
        class => ( ref($self) || $self ),
        table => $self->table,
        columns => { $self->_serialize_columns },
    };
}

sub _serialize_columns {
    my $self = shift;
    my %serialized_columns;
    foreach my $column ( $self->columns ) {
        $serialized_columns{ $column->name } = $column->serialize_metadata();
    }

    return %serialized_columns;
}

=head2 writable_attributes

Returns a list of this table's writable columns


=cut

sub writable_attributes {
    my $self = shift;
    return @{
        $self->_WRITABLE_COLS_CACHE() || $self->_WRITABLE_COLS_CACHE(
            [ sort map { $_->name } grep { $_->writable } $self->columns ]
        )
        };
}

=head2 record values

As you've probably already noticed, C<Jifty::DBI::Record> automatically
creates methods for your standard get/set accessors. It also provides you
with some hooks to massage the values being loaded or stored.

When you fetch a record value by calling
C<$my_record-E<gt>some_field>, C<Jifty::DBI::Record> provides the
following hook

=over



=item after_I<column_name>

This hook is called with a reference to the value returned by
Jifty::DBI. Its return value is discarded.

=back

When you set a value, C<Jifty::DBI> provides the following hooks

=over

=item before_set_I<column_name> PARAMHASH

C<Jifty::DBI::Record> passes this function a reference to a paramhash
composed of:

=over

=item column

The name of the column we're updating.

=item value

The new value for I<column>.

=item is_sql_function

A boolean that, if true, indicates that I<value> is an SQL function,
not just a value.

=back

If before_set_I<column_name> returns false, the new value isn't set.

=item before_set PARAMHASH

This is identical to the C<before_set_I<column_name>>, but is called
for every column set.

=item after_set_I<column_name> PARAMHASH

This hook will be called after a value is successfully set in the
database. It will be called with a reference to a paramhash that
contains C<column>, C<value>, and C<old_value> keys. If C<value> was a
SQL function, it will now contain the actual value that was set. If
C<column> has filters on it, C<value> will be the result of going
through an encode and decode cycle.

This hook's return value is ignored.

=item after_set PARAMHASH

This is identical to the C<after_set_I<column_name>>, but is called
for every column set.

=item validate_I<column_name> VALUE

This hook is called just before updating the database. It expects the
actual new value you're trying to set I<column_name> to. It returns
two values.  The first is a boolean with truth indicating success. The
second is an optional message. Note that validate_I<column_name> may
be called outside the context of a I<set> operation to validate a
potential value. (The Jifty application framework uses this as part of
its AJAX validation system.)

=back


=cut

=head2 _value

_value takes a single column name and returns that column's value for
this row.  Subclasses can override _value to insert custom access
control.

=cut

sub _value {
    my $self   = shift;
    my $column = shift;

    my $value = $self->__value( $column => @_ );
    $self->_run_callback(
        name => "after_" . $column,
        args => \$value
    );
    return $value;
}

=head2 __raw_value

Takes a column name and returns that column's raw value.
Subclasses should never override __raw_value.

=cut

sub __raw_value {
    my $self = shift;

    my $column_name = shift;

    # In the default case of "yeah, we have a value", return it as
    # fast as we can.
    return $self->{'raw_values'}{$column_name}
      if $self->{'fetched'}{$column_name};

    if ( !$self->{'fetched'}{$column_name} and my $id = $self->id() ) {
        my $pkey = $self->_primary_key();
        my $query_string =
            "SELECT "
          . $column_name
          . " FROM "
          . $self->table
          . " WHERE $pkey = ?";
        my $sth = $self->_handle->simple_query( $query_string, $id );
        my ($value) = eval { $sth->fetchrow_array() };
        $self->{'raw_values'}{$column_name}  = $value;
        $self->{'fetched'}{$column_name} = 1;
    }

    return $self->{'raw_values'}{$column_name};
}

=head2 resolve_column

given a column name, resolve it, even if it's actually an alias 
return the column object.

=cut

sub resolve_column {
    my $self = shift;
    my $column_name = shift;
    return unless $column_name;
    return $self->COLUMNS->{$column_name};
}

=head2 __value

Takes a column name and returns that column's value. Subclasses should
never override __value.

=cut

sub __value {
    my $self = shift;

    my $column = $self->COLUMNS->{ +shift }; # Shortcut around ->resolve_column
    return unless $column;

    my $column_name = $column->{name}; # Speed optimization

    if ($column->computed) {
        return $self->$column_name;
    }

    # In the default case of "yeah, we have a value", return it as
    # fast as we can.
    return $self->{'values'}{$column_name}
        if ( $self->{'fetched'}{$column_name}
        && $self->{'decoded'}{$column_name} );

    unless ($self->{'fetched'}{$column_name}) {
        # Fetch it, and mark it as not decoded
        $self->{'values'}{$column_name} = $self->__raw_value( $column_name );
        $self->{'decoded'}{$column_name} = 0;
    }

    unless ( $self->{'decoded'}{$column_name} ) {
        $self->_apply_output_filters(
            column    => $column,
            value_ref => \$self->{'values'}{$column_name},
        ) if exists $self->{'values'}{$column_name};
        $self->{'decoded'}{$column_name} = 1;
    }

    return $self->{'values'}{$column_name};
}

=head2 as_hash 

Returns a version of this record's readable columns rendered as a hash
of key => value pairs

=cut

sub as_hash {
    my $self = shift;
    my %values;
    $values{$_} = $self->$_() for $self->readable_attributes;
    return %values;
}

=head2 _set

_set takes a single column name and a single unquoted value.  It
updates both the in-memory value of this column and the in-database
copy.  Subclasses can override _set to insert custom access control.

=cut

sub _set {
    my $self = shift;
    my %args = (
        'column'          => undef,
        'value'           => undef,
        'is_sql_function' => undef,
        @_
    );

    # Call the general before_set triggers
    my $ok = $self->_run_callback(
        name => "before_set",
        args => \%args,
    );
    return $ok if ( not defined $ok );

    # Call the specific before_set_column triggers
    $ok = $self->_run_callback(
        name => "before_set_" . $args{column},
        args => \%args,
    );
    return $ok if ( not defined $ok );

    # Fetch the old value for the benefit of the triggers
    my $old_value = $self->_value( $args{column} );

    $ok = $self->__set(%args);
    return $ok if not $ok;

    # Fetch the value back to make sure we have the actual value
    my $value = $self->_value( $args{column} );

    # Call the general after_set triggers
    $self->_run_callback(
        name => "after_set",
        args => { column => $args{column}, value => $value, old_value => $old_value },
    );

    # Call the specific after_set_column triggers
    $self->_run_callback(
        name => "after_set_" . $args{column},
        args => { column => $args{column}, value => $value, old_value => $old_value },
    );

    return $ok;
}

sub __set {
    my $self = shift;

    my %args = (
        'column'          => undef,
        'value'           => undef,
        'is_sql_function' => undef,
        @_
    );

    my $ret = Class::ReturnValue->new();

    my $column = $self->column( $args{'column'} );
    unless ($column) {
        $ret->as_array( 0, 'No column specified' );
        $ret->as_error(
            errno        => 5,
            do_backtrace => 0,
            message      => "No column specified"
        );
        return ( $ret->return_value );
    }

    my $unmunged_value;
    unless ($args{is_sql_function}) {
        $self->_apply_input_filters(
            column    => $column,
            value_ref => \$args{'value'}
        );

        # if value is not fetched or it's already decoded
        # then we don't check eqality
        # we also don't call __value because it decodes value, but
        # we need encoded value
        if ( $self->{'fetched'}{ $column->name }
            || !$self->{'decoded'}{ $column->name } )
        {
            if ((      !defined $args{'value'}
                    && !defined $self->{'values'}{ $column->name }
                )
                || (   defined $args{'value'}
                    && defined $self->{'values'}{ $column->name }

                    # XXX: This is a bloody hack to stringify DateTime
                    # and other objects for compares
                    && $args{value}
                    . "" eq ""
                    . $self->{'values'}{ $column->name }
                )
                )
            {
                $ret->as_array( 1, "That is already the current value" );
                return ( $ret->return_value );
            }
        }

        if ( my $sub = $column->validator ) {
            my ( $ok, $msg ) = $sub->( $self, $args{'value'} );
            unless ($ok) {
                $ret->as_array( 0, 'Illegal value for ' . $column->name );
                $ret->as_error(
                    errno        => 3,
                    do_backtrace => 0,
                    message      => "Illegal value for " . $column->name
                );
                return ( $ret->return_value );
            }
        }

        # Implement 'is distinct' checking
        if ( $column->distinct ) {
            my $ret = $self->is_distinct( $column->name, $args{'value'} );
            return ($ret) if not($ret);
        }

        # The blob handling will destroy $args{'value'}. But we assign
        # that back to the object at the end. this works around that
        $unmunged_value = $args{'value'};

        if ( $column->type =~ /^(text|longtext|clob|blob|lob|bytea)$/i ) {
            my $bhash
                = $self->_handle->blob_params( $column->name, $column->type );
            $bhash->{'value'} = $args{'value'};
            $args{'value'} = $bhash;
        }
    }

    my $val = $self->_handle->update_record_value(
        %args,
        table        => $self->table(),
        primary_keys => { $self->primary_keys() }
    );

    unless ($val) {
        my $message
            = $column->name . " could not be set to " . $args{'value'} . ".";
        $ret->as_array( 0, $message );
        $ret->as_error(
            errno        => 4,
            do_backtrace => 0,
            message      => $message
        );
        return ( $ret->return_value );
    }

    # If we've performed some sort of "functional update"
    # then we need to reload the object from the DB to know what's
    # really going on. (ex SET Cost = Cost+5)
    if ( $args{'is_sql_function'} ) {

        # XXX TODO primary_keys
        $self->load_by_cols( id => $self->id );
    } else {
        $self->{'raw_values'}{ $column->name }  = $unmunged_value;
        $self->{'values'}{ $column->name }  = $unmunged_value;
        $self->{'decoded'}{ $column->name } = 0;
    }
    $ret->as_array( 1, "The new value has been set." );
    return ( $ret->return_value );
}

=head2 load

C<load> can be called as a class or object method.

Takes a single argument, $id. Calls load_by_cols to retrieve the row
whose primary key is $id.

=cut

sub load {
    my $self = shift;
    return unless @_ and defined $_[0];
    Carp::carp("load called with more than one argument. Did you mean load_by_cols?") if @_ > 1;

    return $self->load_by_cols( id => shift );
}

=head2 load_by_cols

C<load_by_cols> can be called as a class or object method.

Takes a hash of columns and values. Loads the first record that
matches all keys.

The hash's keys are the columns to look at.

The hash's values are either: scalar values to look for OR hash
references which contain 'operator', 'value', 'case_sensitive' 
or 'function'

To load something case sensitively on a case insensitive database,
you can do:

  $record->load_by_cols( column => { operator => '=',
                                     value => 'Foo',
                                     case_sensitive => 1 } );

=cut

sub load_by_cols {
    my $class = shift;
    my %hash  = (@_);
    my ($self);
    if ( ref($class) ) {
        ( $self, $class ) = ( $class, undef );
    } else {
        $self = $class->new( handle => ( delete $hash{'_handle'} || undef ) );
    }

    my ( @bind, @phrases );
    foreach my $key ( keys %hash ) {
        if ( defined $hash{$key} && $hash{$key} ne '' ) {
            my $op;
            my $value;
            my $function   = "?";
            my $column_obj = $self->column($key);
            Carp::confess(
                "Unknown column '$key' in class '" . ref($self) . "'" )
                if !defined $column_obj;
            my $case_sensitive = $column_obj->case_sensitive;
            if ( ref $hash{$key} eq 'HASH' ) {
                $op             = $hash{$key}->{operator};
                $value          = $hash{$key}->{value};
                $function       = $hash{$key}->{function} || "?";
                $case_sensitive = $hash{$key}->{case_sensitive}
                    if exists $hash{$key}->{case_sensitive};
            } else {
                $op    = '=';
                $value = $hash{$key};
            }

            if ( blessed $value && $value->isa('Jifty::DBI::Record') ) {
                my $by  = defined $column_obj->by ? $column_obj->by : 'id';
                $value = $value->$by;
            }

            $self->_apply_input_filters(
                column    => $column_obj,
                value_ref => \$value,
            ) if $column_obj->encode_on_select;

            # if the handle is in a case_sensitive world and we need to make
            # a case-insensitive query
            if ( $self->_handle->case_sensitive && $value ) {
                if ( $column_obj->is_string && !$case_sensitive ) {
                    ( $key, $op, $function )
                        = $self->_handle->_make_clause_case_insensitive( $key,
                        $op, $function );
                }
            }

            if ($column_obj and $column_obj->no_placeholder and $function eq "?") {
                push @phrases, "$key $op ".$self->_handle->quote_value($value);
            } else {
                push @phrases, "$key $op $function";
                push @bind,    $value;
            }

        } elsif ( !defined $hash{$key} ) {
            push @phrases, "$key IS NULL";
        } else {
            push @phrases, "($key IS NULL OR $key = ?)";
            my $column = $self->column($key);

            if ( $column->is_numeric ) {
                push @bind, 0;
            } else {
                push @bind, '';
            }

        }
    }

    my $query_string
        = "SELECT  * FROM "
        . $self->table
        . " WHERE "
        . join( ' AND ', @phrases );
    if ($class) {
        $self->_load_from_sql( $query_string, @bind );
        return $self;
    } else {
        return $self->_load_from_sql( $query_string, @bind );
    }

}

=head2 load_by_primary_keys 

Loads records with a given set of primary keys. 

=cut

sub load_by_primary_keys {
    my $self = shift;
    my $data = ( ref $_[0] eq 'HASH' ) ? $_[0] : {@_};

    my %cols = ();
    foreach ( @{ $self->_primary_keys } ) {
        return ( 0, "Missing PK column: '$_'" ) unless defined $data->{$_};
        $cols{$_} = $data->{$_};
    }
    return ( $self->load_by_cols(%cols) );
}

=head2 load_from_hash

Takes a hashref, such as created by Jifty::DBI and populates this
record's loaded values hash.

=cut

sub load_from_hash {
    my $self    = shift;
    my $hashref = shift;
    my %args = @_;
    if ($args{fast}) {
        # Optimization for loading from database
        $self->{values} = $hashref;
        $self->{fetched}{$_} = 1 for keys %{$hashref};
        # copy $hashref so changing 'values' doesn't change 'raw_values'
        $self->{raw_values}{$_} = $hashref->{$_} for keys %{$hashref};
        $self->{decoded} = {};
        return $self->{values}{id};
    }

    unless ( ref $self ) {
        $self = $self->new( handle => delete $hashref->{'_handle'} );
    }

    $self->{'values'} = {};
    $self->{'raw_values'} = {};
    $self->{'fetched'} = {};

    foreach my $col ( grep exists $hashref->{ lc $_ }, map $_->name, $self->columns ) {
        $self->{'fetched'}{$col} = 1;
        $self->{'values'}{$col} = $hashref->{ lc $col };
        $self->{'raw_values'}{$col} = $hashref->{ lc $col };
    }

    $self->{'decoded'} = {};
    return $self->id();
}

=head2 _load_from_sql QUERYSTRING @BIND_VALUES

Load a record as the result of an SQL statement

=cut

sub _load_from_sql {
    my $self         = shift;
    my $query_string = shift;
    my @bind_values  = (@_);

    my $sth = $self->_handle->simple_query( $query_string, @bind_values );

    #TODO this only gets the first row. we should check if there are more.

    return ( 0, "Couldn't execute query" ) unless $sth;

    my $hashref = $sth->fetchrow_hashref;
    delete $self->{'values'};
    delete $self->{'raw_values'};
    $self->{'fetched'} = {};
    $self->{'decoded'} = {};

    #foreach my $f ( keys %$hashref ) { $self->{'fetched'}{  $f } = 1; }
    foreach my $col ( map { $_->name } $self->columns ) {
        next unless exists $hashref->{ lc($col) };
        $self->{'fetched'}{$col} = 1;
        $self->{'values'}->{$col} = $hashref->{ lc($col) };
        $self->{'raw_values'}->{$col} = $hashref->{ lc($col) };
    }
    if ( !$self->{'values'} && $sth->err ) {
        return ( 0, "Couldn't fetch row: " . $sth->err );
    }

    unless ( $self->{'values'} ) {
        return ( 0, "Couldn't find row" );
    }

    ## I guess to be consistant with the old code, make sure the primary
    ## keys exist.

    if ( grep { not defined } $self->primary_keys ) {
        return ( 0, "Missing a primary key?" );
    }

    return ( 1, "Found object" );

}

=head2 create PARAMHASH

C<create> can be called as either a class or object method

This method creates a new record with the values specified in the PARAMHASH.

This method calls two hooks in your subclass:

=over

=item before_create

When adding the C<before_create> trigger, you can determine whether
the trigger may cause an abort or not by passing the C<abortable>
parameter to the C<add_trigger> method. If this is not set, then the
return value is ignored regardless.

  sub before_create {
      my $self = shift;
      my $args = shift;

      # Do any checks and changes on $args here.
      $args->{first_name} = ucfirst $args->{first_name};

      return;      # false return vallue will abort the create
      return 1;    # true return value will allow create to continue
  }

This method is called before trying to create our row in the
database. It's handed a reference to your paramhash. (That means it
can modify your parameters on the fly).  C<before_create> returns a
true or false value. If it returns C<undef> and the trigger has been
added as C<abortable>, the create is aborted.

=item after_create

When adding the C<after_create> trigger, you can determine whether the
trigger may cause an abort or not by passing the C<abortable>
parameter to the C<add_trigger> method. If this is not set, then the
return value is ignored regardless.

  sub after_create {
      my $self                    = shift;
      my $insert_return_value_ref = shift;

      return unless $$insert_return_value_ref;    # bail if insert failed
      $self->load($$insert_return_value_ref);     # load ourselves from db

      # Do whatever needs to be done here

      return;   # aborts the create, possibly preventing a load
      return 1; # continue normally
  }

This method is called after attempting to insert the record into the
database. It gets handed a reference to the return value of the
insert. That will either be a true value or a L<Class::ReturnValue>.

Aborting the trigger merely causes C<create> to return a false
(undefined) value even thought he create may have succeeded. This
prevents the loading of the record that would normally be returned.

=back


=cut 

sub create {
    my $class   = shift;
    my %attribs = @_;

    my ($self);
    if ( ref($class) ) {
        ( $self, $class ) = ( $class, undef );
    } else {
        $self = $class->new(
            handle => ( delete $attribs{'_handle'} || undef ) );
    }

    my $ok
        = $self->_run_callback( name => "before_create", args => \%attribs );
    return $ok if ( not defined $ok );

    my $ret = $self->__create(%attribs);

    $ok = $self->_run_callback(
        name => "after_create",
        args => \$ret
    );
    return $ok if ( not defined $ok );

    if ($class) {
        $self->load_by_cols( id => $ret );
        return ($self);
    } else {
        return ($ret);
    }
}

sub __create {
    my ( $self, %attribs ) = @_;

    foreach my $column_name ( keys %attribs ) {
        my $column = $self->column($column_name);
        unless ($column) {

            # "Virtual" columns beginning with __ are passed through
            # to handle without munging.
            next if $column_name =~ /^__/;

            Carp::confess "$column_name isn't a column we know about";
        }
        if (    $column->readable
            and $column->refers_to
            and UNIVERSAL::isa( $column->refers_to, "Jifty::DBI::Record" )
            and UNIVERSAL::isa( $attribs{$column_name}, 'Jifty::DBI::Record' ) )
        {
            # lookup the column referenced or default to id
            my $by = defined $column->by ? $column->by : 'id';
            $attribs{$column_name} = $attribs{$column_name}->$by;
        }

        $self->_apply_input_filters(
            column    => $column,
            value_ref => \$attribs{$column_name},
        );

        # Implement 'is distinct' checking
        if ( $column->distinct ) {
            my $ret
                = $self->is_distinct( $column_name, $attribs{$column_name} );
            if ( not $ret ) {
                Carp::cluck(
                    "$self failed a 'is_distinct' check for $column_name on "
                        . $attribs{$column_name} );
                return ($ret);
            }
        }

        if ( $column->type =~ /^(text|longtext|clob|blob|lob|bytea)$/i ) {
            my $bhash
                = $self->_handle->blob_params( $column_name, $column->type );
            $bhash->{'value'} = $attribs{$column_name};
            $attribs{$column_name} = $bhash;
        }
    }

    for my $column ( $self->columns ) {
        if (    not defined $attribs{ $column->name }
            and defined $column->default
            and not ref $column->default )
        {
            my $default = force $column->default;
            $default = $default->id
                if UNIVERSAL::isa( $default, 'Jifty::DBI::Record' );

            $attribs{ $column->name } = $default;

            $self->_apply_input_filters(
                column    => $column,
                value_ref => \$attribs{ $column->name },
            );
        }

        if (    not defined $attribs{ $column->name }
            and $column->mandatory
            and $column->type ne "serial" )
        {
            # Enforce "mandatory"
            Carp::carp "Did not supply value for mandatory column "
                . $column->name;
            unless ( $column->active ) {
                Carp::carp "The mandatory column "
                    . $column->name
                    . " is no longer active. This is likely to cause problems!";
            }

            return (0);
        }
    }

    return $self->_handle->insert( $self->table, %attribs );
}

=head2 delete

Delete this record from the database. On failure return a
Class::ReturnValue with the error. On success, return 1;

This method has two hooks:

=over 

=item before_delete

This method is called before the record deletion, if it exists. On
failure it returns a L<Class::ReturnValue> with the error.  On success
it returns 1.

If this method returns an error, it causes the delete to abort and
return the return value from this hook. 

=item after_delete

This method is called after deletion, with a reference to the return
value from the delete operation.

=back

=cut

sub delete {
    my $self = shift;
    my $before_ret = $self->_run_callback( name => 'before_delete' );
    return $before_ret unless ( defined $before_ret );
    my $ret = $self->__delete;

    my $after_ret
        = $self->_run_callback( name => 'after_delete', args => \$ret );
    return $after_ret unless ( defined $after_ret );
    return ($ret);

}

sub __delete {
    my $self = shift;

    #TODO Check to make sure the key's not already listed.
    #TODO Update internal data structure

    ## Constructs the where clause.
    my %pkeys = $self->primary_keys();
    my $return = $self->_handle->delete( $self->table, $self->primary_keys );

    if ( UNIVERSAL::isa( 'Class::ReturnValue', $return ) ) {
        return ($return);
    } else {
        return (1);
    }
}

=head2 table

This method returns this class's default table name. It uses
Lingua::EN::Inflect to pluralize the class's name as we believe that
class names for records should be in the singular and table names
should be plural.

If your class name is C<My::App::Rhino>, your table name will default
to C<rhinos>. If your class name is C<My::App::RhinoOctopus>, your
default table name will be C<rhino_octopuses>. Not perfect, but
arguably correct.

=cut

sub table {
    my $self = shift;
    $self->TABLE_NAME( $self->_guess_table_name )
        unless ( $self->TABLE_NAME() );
    return $self->TABLE_NAME();
}

=head2 collection_class

Returns the collection class which this record belongs to; override
this to subclass.  If you haven't specified a collection class, this
returns a best guess at the name of the collection class for this
collection.

It uses a simple heuristic to determine the collection class name --
It appends "Collection" to its own name. If you want to name your
records and collections differently, go right ahead, but don't say we
didn't warn you.

=cut

sub collection_class {
    my $self = shift;
    my $class = ref($self) || $self;
    $class . 'Collection';
}

=head2 _guess_table_name

Guesses a table name based on the class's last part.


=cut

sub _guess_table_name {
    my $self = shift;
    my $class = ref($self) ? ref($self) : $self;
    die "Couldn't turn " . $class . " into a table name"
        unless ( $class =~ /(?:\:\:)?(\w+)$/ );
    my $table = $1;
    $table =~ s/(?<=[a-z])([A-Z]+)/"_" . lc($1)/eg;
    $table =~ tr/A-Z/a-z/;
    $table = Lingua::EN::Inflect::PL_N($table);
    return ($table);

}

=head2 _handle

Returns or sets the current Jifty::DBI::Handle object

=cut

sub _handle {
    my $self = shift;
    if (@_) {
        $self->{'DBIxHandle'} = shift;
    }
    return ( $self->{'DBIxHandle'} );
}

=head2 PRIVATE refers_to

used for the declarative syntax

=cut

sub _filters {
    my $self = shift;
    my %args = ( direction => 'input', column => undef, @_ );

    if ( $args{'direction'} eq 'input' ) {
        return grep $_, map $_->input_filters,
            ( $self, $args{'column'}, $self->_handle );
    } else {
        return grep $_, map $_->output_filters,
            ( $self->_handle, $args{'column'}, $self );
    }
}

sub _apply_input_filters {
    return (shift)->_apply_filters( direction => 'input', @_ );
}

sub _apply_output_filters {
    return (shift)->_apply_filters( direction => 'output', @_ );
}

{ my %cache = ();
sub _apply_filters {
    my $self = shift;
    my %args = (
        direction => 'input',
        column    => undef,
        value_ref => undef,
        @_
    );

    my @filters = $self->_filters(%args);
    my $action = $args{'direction'} eq 'output' ? 'decode' : 'encode';
    foreach my $filter_class (@filters) {
        unless ( exists $cache{ $filter_class } ) {
            local $UNIVERSAL::require::ERROR;
            $filter_class->require;
            if ($UNIVERSAL::require::ERROR) {
                warn $UNIVERSAL::require::ERROR;
                $cache{ $filter_class } = 0;
                next;
            }
            $cache{ $filter_class } = 1;
        }
        elsif ( !$cache{ $filter_class } ) {
            next;
        }

        my $filter = $filter_class->new(
            record    => $self,
            column    => $args{'column'},
            value_ref => $args{'value_ref'},
            handle    => $self->_handle,
        );

        # XXX TODO error proof this
        $filter->$action();
    }
} }

=head2 is_distinct COLUMN_NAME, VALUE

Checks to see if there is already a record in the database where
COLUMN_NAME equals VALUE.  If no such record exists then the
COLUMN_NAME and VALUE pair is considered distinct and it returns 1.
If a value is already present the test is considered to have failed
and it returns a L<Class::ReturnValue> with the error.

=cut 

sub is_distinct {
    my $self   = shift;
    my $column = shift;
    my $value  = shift;

    my $record = $self->new( $self->_new_record_args );
    $record->load_by_cols( $column => $value );

    my $ret = Class::ReturnValue->new();

    if ( $record->id ) {
        $ret->as_array( 0, "Value already exists for unique column $column" );
        $ret->as_error(
            errno        => 3,
            do_backtrace => 0,
            message      => "Value already exists for unique column $column",
        );
        return ( $ret->return_value );
    } else {
        return (1);
    }
}

=head2 run_canonicalization_for_column column => 'COLUMN', value => 'VALUE'

Runs all canonicalizers for the specified column.

=cut

sub run_canonicalization_for_column {
    my $self = shift;
    my %args = (
        column => undef,
        value  => undef,
        extra  => [],
        @_
    );

    my ( $ret, $value_ref ) = $self->_run_callback(
        name          => "canonicalize_" . $args{'column'},
        args          => $args{'value'},
        extra         => $args{'extra'},
        short_circuit => 0,
    );
    return unless defined $ret;
    return (
        exists $value_ref->[-1]->[0]
        ? $value_ref->[-1]->[0]
        : $args{'value'}
    );
}

=head2 has_canonicalizer_for_column COLUMN

Returns true if COLUMN has a canonicalizer, otherwise returns undef.

=cut

sub has_canonicalizer_for_column {
    my $self   = shift;
    my $key    = shift;
    my $method = "canonicalize_$key";
    if ( $self->can($method) ) {
        return 1;
    # We have to force context here because we're reaching inside Class::Trigger
    } elsif ( my @sighs = Class::Trigger::__fetch_all_triggers($self, $method) ) {
        return 1;
    } else {
        return undef;
    }
}

=head2 run_validation_for_column column => 'COLUMN', value => 'VALUE' [extra => \@ARGS]

Runs all validators for the specified column.

=cut

sub run_validation_for_column {
    my $self = shift;
    my %args = (
        column => undef,
        value  => undef,
        extra  => [],
        @_
    );
    my $key  = $args{'column'};
    my $attr = $args{'value'};

    my ( $ret, $results )
        = $self->_run_callback(
            name  => "validate_" . $key,
            args  => $attr,
            extra => $args{'extra'},
        );

    if ( defined $ret ) {
        return ( 1, 'Validation ok' );
    } else {
        return ( @{ $results->[-1] } );
    }

}

=head2 has_validator_for_column COLUMN

Returns true if COLUMN has a validator, otherwise returns undef.

=cut

sub has_validator_for_column {
    my $self = shift;
    my $key  = shift;
    my $method = "validate_$key";
    if ( $self->can( $method ) ) {
        return 1;
    # We have to force context here because we're reaching inside Class::Trigger
    } elsif ( my @sighs = Class::Trigger::__fetch_all_triggers($self, $method) ) {
        return 1;
    } else {
        return undef;
    }
}

sub _run_callback {
    my $self = shift;
    my %args = (
        name => undef,
        args => undef,
        short_circuit => 1,
        extra => [],
        @_
    );

    my $ret;
    my $method = $args{'name'};
    my @results;
    if ( my $func = $self->can($method) ) {
        @results = $func->( $self, $args{args}, @{$args{'extra'}} );
        return ( wantarray ? ( undef, [ [@results] ] ) : undef )
            if $args{short_circuit} and not $results[0];
    }
    $ret = $self->call_trigger( $args{'name'} => $args{args}, @{$args{'extra'}} );
    return (
        wantarray
        ? ( $ret, [ [@results], @{ $self->last_trigger_results } ] )
        : $ret
    );
}

=head2 unload_value COLUMN

Purges the cached value of COLUMN from the object, forcing it to be
fetched from the database next time it is queried.

=cut

sub unload_value {
    my $self = shift;
    my $column = shift;
    delete $self->{$_}{$column} for qw/values raw_values fetched decoded _prefetched/;
}

1;

__END__



=head1 AUTHOR

Jesse Vincent <jesse@bestpractical.com>, Alex Vandiver
<alexmv@bestpractical.com>, David Glasser <glasser@bestpractical.com>,
Ruslan Zakirov <ruslan.zakirov@gmail.com>

Based on DBIx::SearchBuilder::Record, whose credits read:

 Jesse Vincent, <jesse@fsck.com> 
 Enhancements by Ivan Kohler, <ivan-rt@420.am>
 Docs by Matt Knopp <mhat@netlag.com>

=head1 SEE ALSO

L<Jifty::DBI>, L<Jifty::DBI::Handle>, L<Jifty::DBI::Collection>.

=cut
