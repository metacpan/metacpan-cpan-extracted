# $Id$
package Handel::Storage::RDBO;
use warnings;
use strict;
use vars qw/$VERSION/;

$VERSION = '1.00003';

BEGIN {
    use base qw/Handel::Storage/;

    __PACKAGE__->mk_group_accessors('inherited', qw/
        _columns_to_add
        _columns_to_remove
        _schema_instance
        connection_info
        item_relationship
        table_name
    /);
    __PACKAGE__->mk_group_accessors('component_class', qw/
        schema_class
    /);

    use Handel::Exception qw/:try/;
    use Handel::L10N qw/translate/;
    use Clone ();
    use Scalar::Util qw/blessed weaken/;
};

__PACKAGE__->item_relationship('items');
__PACKAGE__->iterator_class('Handel::Iterator::RDBO');
__PACKAGE__->result_class('Handel::Storage::RDBO::Result');

sub add_columns {
    my ($self, @columns) = @_;

    if ($self->_schema_instance) {
        $self->_schema_instance->meta->add_columns(@columns);
    };

    $self->_columns_to_add
        ? push @{$self->_columns_to_add}, @columns
        : $self->_columns_to_add(\@columns);

    return;
};

sub add_item {
    my ($self, $result, $data) = @_;

    throw Handel::Exception::Argument(
        -details => translate('NO_RESULT')
    ) unless $result; ## no critic

    my $storage_result = $result->storage_result;
    my $result_class = $self->result_class;

    throw Handel::Exception::Argument(
        -details => translate('PARAM2_NOT_HASHREF')
    ) unless ref($data) eq 'HASH'; ## no critic

    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $self->item_relationship; ## no critic

    my $relationship = $storage_result->meta->relationship($self->item_relationship);
    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $relationship; ## no critic

    my $column_map = $relationship->column_map;
    foreach my $key (keys %{$column_map}) {
        $data->{$column_map->{$key}} = $storage_result->$key;
    };

    $self->item_storage->set_default_values($data);
    $self->item_storage->check_constraints($data);
    $self->item_storage->validate_data($data);

    my $item;
    eval {
        $item = $relationship->class->new(%{$data}, db => $result->storage_result->db);
        $item->save
    };
    if ($@) {
        $self->process_error($@);
    };

    return $result_class->create_instance(
        $item, $self->item_storage
    );
};

sub clone {
    my $self = shift;

    throw Handel::Exception::Storage(
        -details => translate('NOT_CLASS_METHOD')
    ) unless blessed($self); ## no critic

    if ($self->_schema_instance) {
        my $schema_instance = $self->_schema_instance;
        $self->_schema_instance(undef);

        my $clone = Clone::clone($self);

        $self->_schema_instance($schema_instance);

        return $clone;
    } else {
        return $self->SUPER::clone;
    };
};

sub column_accessors {
    my $self = shift;
    my $accessors = {};

    if ($self->_schema_instance) {
        my @columns = $self->_schema_instance->meta->columns;
        foreach my $column (@columns) {
            my $accessor = $column->alias;
            if (!$accessor) {
                $accessor = $column->name;
            };
            $accessors->{$column} = $accessor;
        };
    } else {
        my @columns = $self->schema_class->meta->columns;
        foreach my $column (@columns) {
            my $accessor = $column->alias;
            if (!$accessor) {
                $accessor = $column->name;
            };
            $accessors->{$column} = $accessor;
        };

        if ($self->_columns_to_add) {
            my $adding = Clone::clone($self->_columns_to_add);

            while (my $column = shift @{$adding}) {
                my $column_info = ref $adding->[0] ? shift(@{$adding}) : {};
                my $accessor = $column_info->{'alias'};
                if (!$accessor) {
                    $accessor = $column;
                };
                $accessors->{$column} = $accessor;
            };
        };

        if ($self->_columns_to_remove) {
            foreach my $column (@{$self->_columns_to_remove}) {
                delete $accessors->{$column};
            };
        };
    };

    return $accessors;
};

sub columns {
    my $self = shift;

    if ($self->_schema_instance) {
        return $self->_schema_instance->meta->column_names;
    } else {
        return keys %{$self->column_accessors};
    };
};

sub copyable_item_columns {
    my $self = shift;

    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $self->item_relationship; ## no critic

    throw Handel::Exception::Storage(
        -details => translate('ITEM_STORAGE_NOT_DEFINED')
    ) unless $self->item_storage; ## no critic

    my $schema_instance = $self->schema_instance;
    my @copyable;
    my %primaries = map {$_ => 1} $self->item_storage->primary_columns;
    my %foreigns;

    if (my $relationship = $schema_instance->meta->relationship($self->item_relationship)) {
        %foreigns = map {$_ => 1} values %{$relationship->column_map};
    };

    foreach ($self->item_storage->columns) {
        if (!exists $primaries{$_} && !exists $foreigns{$_}) {
            push @copyable, $_;
        };
    };

    return @copyable;
};

sub count_items {
    my ($self, $result, $filter) = @_;

    throw Handel::Exception::Argument(
        -details => translate('NO_RESULT')
    ) unless $result; ## no critic

    my $storage_result = $result->storage_result;

    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $self->item_relationship; ## no critic

    $filter = $self->_migrate_wildcards($filter) || {};

    my $relationship = $storage_result->meta->relationship($self->item_relationship);
    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $relationship; ## no critic

    my $column_map = $relationship->column_map;
    foreach my $key (keys %{$column_map}) {
        $filter->{$column_map->{$key}} = $storage_result->$key;
    };

    my $count = 0;
    eval {
        $count = Rose::DB::Object::Manager->get_objects_count(
            db => $result->storage_result->db,            
            object_class => $relationship->class,
            query        => [%{$filter}]
        );
    };
    if ($@) {
        $self->process_error($@);
    };

    return $count;
};

sub create {
    my ($self, $data) = (shift, shift);
    my $schema = $self->schema_instance;
    my $result_class = $self->result_class;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) unless ref($data) eq 'HASH'; ## no critic

    $self->set_default_values($data);
    $self->check_constraints($data);
    $self->validate_data($data);

    my $storage_result;
    eval {
        $storage_result = $schema->new(%{$data});
        $storage_result->save(@_)
    };
    if ($@) {
        $self->process_error($@);
    };

    return $result_class->create_instance(
        $storage_result, $self
    );
};

sub delete {
    my ($self, $filter) = @_;
    my $schema = $self->schema_instance;

    $filter = $self->_migrate_wildcards($filter) || {};

    my $delete;
    eval {
        my $results = $self->search($filter);
        
        while (my $result = $results->next) {
            if ($result->delete) {
                $delete++;
            };
        };
    };
    if ($@) {
        $self->process_error($@);
    };

    return $delete;
};

sub delete_items {
    my ($self, $result, $filter) = @_;
    throw Handel::Exception::Argument(
        -details => translate('NO_RESULT')
    ) unless $result; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('PARAM2_NOT_HASHREF')
    ) unless !$filter || ref $filter eq 'HASH'; ## no critic

    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $self->item_relationship; ## no critic

    my $storage_result = $result->storage_result;
    $filter = $self->_migrate_wildcards($filter) || {};

    my $relationship = $storage_result->meta->relationship($self->item_relationship);
    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $relationship; ## no critic

    my $column_map = $relationship->column_map;
    foreach my $key (keys %{$column_map}) {
        $filter->{$column_map->{$key}} = $storage_result->$key;
    };

    my $delete;
    eval {
        $delete = Rose::DB::Object::Manager->delete_objects(
            db => $result->storage_result->db,            
            object_class => $relationship->class,
            where        => [%{$filter}]
        );
    };
    if ($@) {
        $self->process_error($@);
    };

    return $delete;
};

sub has_column {
    my ($self, $column) = @_;

    if ($self->_schema_instance) {
        ## no critic (RequireBlockGrep)
        return scalar grep(/$column/, $self->schema_instance->meta->column_names);
    } else {
        return $self->SUPER::has_column($column);
    };
};

sub primary_columns {
    my ($self, @columns) = @_;

    if ($self->_schema_instance) {
        if (@columns) {
            $self->schema_instance->meta->primary_key_columns(@columns);
        };

        return $self->schema_instance->meta->primary_key_column_names;
    } else {
        if (@columns) {
            $self->_primary_columns(\@columns);
        };

        return $self->_primary_columns ?
            @{$self->_primary_columns} :
            $self->schema_class->meta->primary_key_column_names;
    };
};

sub remove_columns {
    my ($self, @columns) = @_;

    if ($self->_schema_instance) {
        foreach my $column (@columns) {
            $self->_schema_instance->meta->delete_column($column);
        };
    };

    $self->_columns_to_remove
        ? push @{$self->_columns_to_remove}, @columns
        : $self->_columns_to_remove(\@columns);

    return;
};

sub schema_instance {
    my $self = shift;

    # allow unsetting
    if (scalar @_) {
        return $self->_schema_instance(@_);
    };

    if (!$self->_schema_instance) {
        no strict 'refs';

        throw Handel::Exception::Storage(
            -details => translate('SCHEMA_CLASS_NOT_SPECIFIED')
        ) unless $self->schema_class; ## no critic

        my $package = $self->schema_class;
        my $namespace = "$package\:\:".uc($self->new_uuid);
        $namespace =~ s/-//g;

        push @{"$namespace\:\:ISA"}, $package;
        $namespace->import;

        $self->_schema_instance($namespace);
        $self->_configure_schema_instance;
    };

    return $self->_schema_instance;
};

sub search {
    my ($self, $filter, $options) = @_;
    my $schema = $self->schema_instance;

    $filter = $self->_migrate_wildcards($filter) || {};
    $options = $self->_migrate_options($options) || {};

    my $resultset;
    eval {
        $resultset = Rose::DB::Object::Manager->get_objects(
            object_class => $schema,
            query        => [%{$filter}],
            %{$options}
        );
    };
    if ($@) {
        $self->process_error($@);
    };

    my $iterator = $self->iterator_class->new({
        data         => $resultset,
        storage      => $self,
        result_class => $self->result_class
    });

    return wantarray ? $iterator->all : $iterator;
};

sub search_items {
    my ($self, $result, $filter, $options) = @_;

    throw Handel::Exception::Argument(
        -details => translate('NO_RESULT')
    ) unless $result; ## no critic

    my $storage_result = $result->storage_result;
    my $result_class = $self->result_class;

    throw Handel::Exception::Argument(
        -details => translate('PARAM2_NOT_HASHREF')
    ) if defined $filter && ref $filter ne 'HASH'; ## no critic

    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $self->item_relationship; ## no critic

    $filter = $self->_migrate_wildcards($filter) || {};
    $options = $self->_migrate_options($options) || {};

    my $relationship = $storage_result->meta->relationship($self->item_relationship);
    throw Handel::Exception::Storage(
        -details => translate('ITEM_RELATIONSHIP_NOT_SPECIFIED')
    ) unless $relationship; ## no critic

    my $column_map = $relationship->column_map;
    foreach my $key (keys %{$column_map}) {
        $filter->{$column_map->{$key}} = $storage_result->$key;
    };

    my $resultset;
    eval {
        $resultset = Rose::DB::Object::Manager->get_objects(
            db => $result->storage_result->db,
            object_class => $relationship->class,
            query        => [%{$filter}],
            %{$options}
        );
    };
    if ($@) {
        $self->process_error($@);
    };

    my $iterator = $self->iterator_class->new({
        data         => $resultset,
        storage      => $self->item_storage,
        result_class => $self->item_storage->result_class
    });

    return wantarray ? $iterator->all : $iterator;
};

sub setup {
    my ($self, $options) = @_;

    throw Handel::Exception::Argument(
        -details => translate('PARAM1_NOT_HASHREF')
    ) unless ref($options) eq 'HASH'; ## no critic

    throw Handel::Exception::Storage(
        -details => translate('SETUP_EXISTING_SCHEMA')
    ) if $self->_schema_instance; ## no critic

    # make ->columns/column_accessors w/o happy schema_instance/source
    foreach my $setting (qw/schema_class/) {
        if (exists $options->{$setting}) {
            $self->$setting(delete $options->{$setting});
        };
    }

    $self->SUPER::setup($options);

    return;
};

sub txn_begin {
    my ($self, $result) = @_;

    return $result->db->begin_work;
};

sub txn_commit {
    my ($self, $result) = @_;

    return $result->db->commit;
};

sub txn_rollback {
    my ($self, $result) = @_;

    return $result->db->rollback;
};

sub _configure_schema_instance {
    my ($self) = @_;
    my $schema_instance = $self->schema_instance;
    my $item_storage = $self->item_storage;

    # change the table name
    if ($self->table_name) {
        $schema_instance->meta->table($self->table_name);
    };

    # twiddle columns
    if ($self->_columns_to_add) {
        $schema_instance->meta->add_columns(@{$self->_columns_to_add});
    };
    if ($self->_columns_to_remove) {
        foreach my $column (@{$self->_columns_to_remove}) {
            $schema_instance->meta->delete_column($column);
        };
    };

    # add currency columns
    if ($self->currency_columns) {
        my $currency_class = $self->currency_class;
        foreach my $column ($self->currency_columns) {
            my $column = $schema_instance->meta->column($column);
            next unless $column; ## no critic

            $column->add_trigger(
                'inflate',
                sub {
                    my ($row, $value) = @_;

                    if (blessed $value && $value->isa('Data::Currency')) {
                        $value =  $value->value;
                    };

                    my $codecolumn = $self->can('currency_code_column')->($self);
                    my $storagecode = $self->can('currency_code')->($self);
                    my $code;
                    if ($codecolumn) {
                        $code = $row->$codecolumn;
                        if (!$code) {
                            $code = $storagecode;
                        };
                    } else {
                        $code = $storagecode;
                    };

                    $currency_class->new(
                        $value,
                        $code,
                        $self->can('currency_format')->($self)
                    );
                }
            );
            $column->add_trigger(
                'deflate',
                sub {
                    my ($self, $value) = @_;
                    return blessed $value ? $value->value : $value;
                }
            );
        };
    };

    if ($item_storage) {
        my $item_relationship = $schema_instance->meta->relationship($self->item_relationship);

        throw Handel::Exception::Storage(-text =>
            translate('SCHEMA_SOURCE_NO_RELATIONSHIP', $self->schema_class, $self->item_relationship)
        ) unless $item_relationship; ## no critic

        $item_relationship->class($item_storage->schema_instance);

        $item_storage->schema_instance->meta->initialize(replace_existing => 1);
    };
    $schema_instance->meta->initialize(replace_existing => 1);

    # setup db
    if ($self->connection_info) {
        $schema_instance->meta->db(
            Handel::Schema::RDBO::DB->get_db(@{$self->connection_info})
        );
    };

    return;
};

sub _migrate_wildcards {
    my ($self, $filter) = @_;

    return unless $filter; ## no critic

    if (ref $filter eq 'HASH') {
        foreach my $key (keys %{$filter}) {
            my $value = $filter->{$key};
            if (!ref $filter->{$key} && $value =~ /\%/) {
                $filter->{$key} = {like => $value}
            };
        };
    };

    return $filter;
};

sub _migrate_options {
    my ($self, $options) = @_;

    return unless $options; ## no critic

    if (exists $options->{'order_by'}) {
        my $order_by = delete $options->{'order_by'};
        $options->{'sort_by'} = ref $order_by eq 'ARRAY' ? $order_by : [$order_by];
    };

    return $options;
};

1;
__END__

=head1 NAME

Handel::Storage::RDBO - RDBO storage layer for Handel 1.x

=head1 SYNOPSIS

    use MyCustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('Handel::Storage::RDBO');
    __PACKAGE__->storage({
        schema_class   => 'Handel::Schema::RDBO::Cart',
        constraints    => {
            id         => {'Check Id'      => \&constraint_uuid},
            shopper    => {'Check Shopper' => \&constraint_uuid},
            type       => {'Check Type'    => \&constraint_cart_type},
            name       => {'Check Name'    => \&constraint_cart_name}
        },
        default_values => {
            id         => __PACKAGE__->storage_class->can('new_uuid'),
            type       => CART_TYPE_TEMP
        }
    });
    
    1;

=head1 DESCRIPTION

Handel::Storage::RDBO is used as an intermediary
between Handel::Cart/Handel::Order and the RDBO schema used for reading/writing
to the database.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%options

=back

Creates a new instance of Handel::Storage::RDBO, and passes the options to 
L</setup> on the new instance. The three examples below are the same:

    my $storage = Handel::Storage::RDBO-new({
        schema_class  => 'Handel::Schema::RDBO::Cart'
    });
    
    my $storage = Handel::Storage::RDBO-new;
    $storage->setup({
        schema_source  => 'Handel::Schema::RDBO::Cart'
    });
    
    my $storage = Handel::Storage::RDBO->new;
    $storage->schema_source('Handel::Schema::RDBO::Cart');

The following additional options are available to new/setup, and take the same
data as their method counterparts:

    connection_info
    item_relationship
    schema_class
    schema_instance
    table_name

See L<Handel::Storage/new> a list of other possible options.

=head1 METHODS

=head2 add_columns

=over

=item Arguments: @columns

=back

Adds a list of columns to the current schema_class. Be careful to always use
the column names, not their accessor aliases.

    $storage->add_columns(qw/foo bar baz/);

You can also add columns using the Rose::DB::Object::Meta syntax:

    $storage->add_columns(
        foo => {type => 'varchar', length => 36, not_null => 1},
        bar => {type => int, alias => 'get_bar'}
    );

Yes, you can even mix/match the two:

    $storage->add_columns(
        'foo',
        bar => {type => int, alias => 'get_bar'},
        'baz'
    );

Before schema_instance is initialized, the columns to be added are stored
internally, then added to the schema_instance when it is initialized. If a
schema_instance already exists, the columns are added directly to the
schema_source in the schema_instance itself.

See L<Handel::Storage/add_columns> for more information about this method.

=head2 add_item

=over

=item Arguments: $result, \%data

=back

Adds a new item to the specified result, returning a storage result object.

    my $storage = Handel::Storage::RDBO::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    my $item = $storage->add_item($result, {
        sku => 'ABC123'
    });
    
    print $item->sku;

A L<Handel::Storage::Exception|Handel::Storage::Exception> will be thrown if the
specified result has no item relationship, has a relationship that can't be
found in the schema, second parameter is not a HASH reference or no result is
specified.

See L<Handel::Storage/add_item> for more information about this method.

=head2 clone

Returns a clone of the current storage instance. This is the same as
L<Handel::Storage/clone> except that it disconnects the db instance before
cloning as DBI hates being cloned apparently.

See L<Handel::Storage/clone> for more information about this method.

=head2 column_accessors

Returns a hashref containing all of the columns and their accessor names for the
current storage object.

If a schema_instance already exists, the columns from schema_source in that
schema_instance will be returned. If no schema_instance exists, the columns from
schema_source in the current schema_class will be returned plus any columns to
be added from add_columns minus and columns to be removed from remove_columns.

See L<Handel::Storage/column_accessors> for more information about this method.

=head2 columns

Returns a list of columns from the current schema source.

See L<Handel::Storage/columns> for more information about this method.

=head2 connection_info

=over

=item Arguments: \@info

=back

Gets/sets the connection information used when connecting to the database.

    $storage->connection_info(['dbi:mysql:foo', 'user', 'pass', {PrintError=>1}]);

The info argument is an array ref that holds the following values:

=over

=item $dsn

The DBI dsn to use to connect to.

=item $username

The username for the database you are connecting to.

=item $password

The password for the database you are connecting to.

=item \%attr

The attributes to be pass to DBI for this connection.

=back

See L<DBI> for more information about dsns and connection attributes.

=head2 copyable_item_columns

Returns a list of columns in the current item class that can be copied freely.
This list is usually all columns in the item class except for the primary
key columns and the foreign key columns that participate in the specified item
relationship.

A L<Handel::Storage::Exception|Handel::Storage::Exception> will be thrown if
item class or item relationship are not defined.

See L<Handel::Storage/copyable_item_columns> for more information about this
method.

=head2 count_items

=over

=item Arguments: $result

=back

Returns the number of items associated with the specified result.

    my $storage = Handel::Storage::RDBO::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->add_item({
        sku => 'ABC123'
    });
    
    print $storage->count_items($result);

A L<Handel::Storage::Exception|Handel::Storage::Exception> will be thrown if the
specified result has no item relationship or no result is specified.

See L<Handel::Storage/count_items> for more information about this method.

=head2 create

=over

=item Arguments: \%data

=back

Creates a new result in the current source in the current schema.

    my $result = $storage->create({
        col1 => 'foo',
        col2 => 'bar'
    });

See L<Handel::Storage/create> for more information about this method.

=head2 delete

=over

=item Arguments: \%filter

=back

Deletes results matching the filter in the current source in the current schema.

    $storage->delete({
        id => '11111111-1111-1111-1111-111111111111'
    });

See L<Handel::Storage/delete> for more information about this method.

=head2 delete_items

=over

=item Arguments: $result, \%filter

=back

Deletes items matching the filter from the specified result.

    my $storage = Handel::Storage::RDBO::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->add_item({
        sku => 'ABC123'
    });
    
    $storage->delete_items($result, {
        sku => 'ABC%'
    });

A L<Handel::Storage::Exception|Handel::Storage::Exception> will be thrown if the
specified result has no item relationship.

See L<Handel::Storage/delete_items> for more information about this method.

=head2 has_column

=over

=item Arguments: $column

=back

Returns true if the column exists in the current storage object. If the schema
is already initialized, the has_column method on the result source will be used.
Otherwise, has_column will calculate the existence of the column based on any
current add_columns/remove_columns information.

=head2 item_relationship

=over

=item Arguments: $relationship_name

=back

Gets/sets the name of the schema relationship between carts and items.
The default item relationship is 'items'.

    # in your schema classes
    MySchema::CustomCart->meta->setup(
        relationships => [
            rel_items => {
                type       => 'one to many',
                class      => 'Handel::Schema::RDBO::Cart::Item',
                column_map => {id => 'cart'}
            }
        ]
    );
    
    # in your storage
    $storage->item_relationship('rel_items');

=head2 primary_columns

=over

=item Arguments @columns

=back

Gets/sets the list of primary columns for the current schema_class. When the
schema instance exists, the primary columns are added to and returns from the
current schema source on the schema instance.

When no schema instance exists, the columns are set locally like C<add_columns>
then added to the schema instance during its configuration. Primary columns are
returns from the current schema source in the current schema class if no primary
columns have been set locally.

=head2 remove_columns

=over

=item Arguments: @columns

=back

Removes a list of columns from the current schema_class and removes the
autogenerated accessors from the current class. Be careful to always use the
column names, not their accessor aliases.

    $storage->remove_columns(qw/description/);

Before schema_instance is initialized, the columns to be removed are stored
internally, then removed from the schema_instance when it is initialized. If a
schema_instance already exists, the columns are removed directly from the
schema_source in the schema_instance itself.

See L<Handel::Storage/remove_columns> for more information about this method.

=head2 schema_class

=over

=item Arguments: $schema_class

=back

Gets/sets the schema class to be used for database reading/writing.

    $storage->schema_class('MySchema');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 schema_instance

=over

=item Arguments: $schema_instance

=back

Gets/sets the schema instance to be used for database reading/writing. If no
instance exists, a new one will be created from the specified schema class.
When a new schema instance is created or assigned, it is cloned and the clone
is altered and used, leaving the original schema untouched.

See L<Handel::Manual::Schema|Handel::Manual::Schema> for more detailed
information about how the schema instance is configured.

=head2 search

=over

=item Arguments: \%filter

=back

Returns results in list context, or an iterator in scalar context from the
current source in the current schema matching the search filter.

    my $iterator = $storage->search({
        col1 => 'foo'
    });

    my @results = $storage->search({
        col1 => 'foo'
    });

See L<Handel::Storage/search> for more information about this method.

=head2 search_items

=over

=item Arguments: $result, \%filter

=back

Returns items matching the filter associated with the specified result.

    my $storage = Handel::Storage::RDBO::Cart->new;
    my $result = $storage->search({
        id => '11111111-1111-1111-1111-111111111111'
    });
    
    my $iterator = $storage->search_items($result);

Returns results in list context, or an iterator in scalar context from the
current source in the current schema matching the search filter.

A L<Handel::Storage::Exception|Handel::Storage::Exception> will be thrown if the
specified result has no item relationship.

See L<Handel::Storage/search_items> for more information about this method.

=head2 setup

=over

=item Arguments: \%options

=back

Configures a storage instance with the options specified. Setup accepts the
exact same options that L</new> does.

    package MyStorageClass;
    use strict;
    use warnings;
    use base qw/Handel::Storage::RDBO/;
    
    __PACKAGE__->setup({
        schema_class => 'MySchema::Cart'
    });
    
    # or
    
    my $storage = Handel::Storage::RDBO-new;
    $storage->setup({
        schema_class => 'MySchema::Cart'
    });

This is the same as doing:

    my $storage = Handel::Storage::RDBO-new({
        schema_class => 'MySchema::Cart'
    });

If you call setup on a storage instance or class that has already been
configured, its configuration will be updated with the new options. No attempt
will be made to clear or reset the unspecified settings back to their defaults.

If you pass in a schema_instance, it will be assigned last after all of the
other options have been applied.

=head2 table_name

=over

=item Arguments: $table_name

=back

Gets/sets the name of the table in the database to be used for this schema
source.

=head2 txn_begin

Starts a transaction on the current schema instance.

=head2 txn_commit

Commits the current transaction on the current schema instance.

=head2 txn_rollback

Rolls back the current transaction on the current schema instance.

=head1 SEE ALSO

L<Handel::Storage>, L<Handel::Storage::Result>, L<Handel::Manual::Storage>,
L<Handel::Storage::RDBO::Result>, L<Handel::Storage::RDBO::Cart>,
L<Handel::Storage::RDBO::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
