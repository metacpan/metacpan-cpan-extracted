package Fey::Table;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Fey::Column;
use Fey::Exceptions qw( param_error );
use Fey::NamedObjectSet;
use Fey::Schema;
use Fey::Table::Alias;
use Fey::Types qw(
    ArrayRef Bool HashRef Str Undef Column ColumnOrName NamedObjectSet Schema
);
use List::AllUtils qw( any all first_index );
use Scalar::Util qw( blessed weaken );

use Moose 2.1200;
use MooseX::Params::Validate 0.21 qw( pos_validated_list );
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.13;
use Moose::Util::TypeConstraints;

with 'Fey::Role::TableLike';

with 'Fey::Role::MakesAliasObjects' => {
    self_param  => 'table',
    alias_class => 'Fey::Table::Alias',
};

has 'id' => (
    is         => 'ro',
    lazy_build => 1,
    init_arg   => undef,
);

has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'is_view' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has '_keys' => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => ArrayRef [NamedObjectSet],
    default => sub { [] },
    handles => {
        _keys       => 'elements',
        _add_key    => 'push',
        _delete_key => 'splice',
    },

);

has '_columns' => (
    is      => 'ro',
    isa     => NamedObjectSet,
    default => sub { return Fey::NamedObjectSet->new() },
    handles => {
        columns => 'objects',
        column  => 'object',
    },
);

has 'schema' => (
    is        => 'rw',
    isa       => Undef | Schema,
    weak_ref  => 1,
    writer    => '_set_schema',
    clearer   => '_clear_schema',
    predicate => 'has_schema',
);

has 'candidate_keys' => (
    is         => 'ro',
    isa        => ArrayRef [ ArrayRef [Column] ],
    clearer    => '_clear_candidate_keys',
    lazy_build => 1,
    init_arg   => undef,
);

after '_add_key', '_delete_key' => sub { $_[0]->_clear_candidate_keys() };

has 'primary_key' => (
    is         => 'ro',
    isa        => ArrayRef [Column],
    clearer    => '_clear_primary_key',
    lazy_build => 1,
    init_arg   => undef,
);

after '_clear_candidate_keys' => sub { $_[0]->_clear_primary_key() };

has '_aliased_tables' => (
    traits  => ['Hash'],
    is      => 'bare',
    isa     => HashRef,
    lazy    => 1,
    default => sub { {} },
    handles => {
        _aliased_table       => 'get',
        _store_aliased_table => 'set',
        _has_aliased_table   => 'exists',
    },
);

with 'Fey::Role::Named';

sub add_column {
    my $self = shift;
    my ($col) = pos_validated_list( \@_, { isa => Column } );

    my $name = $col->name();
    param_error "The table already has a column named $name."
        if $self->column($name);

    $self->_columns()->add($col);

    $col->_set_table($self);

    return $self;
}

sub remove_column {
    my $self = shift;
    my ($col)
        = pos_validated_list( \@_, { isa => ColumnOrName } );

    $col = $self->column($col)
        unless blessed $col;

    if ( my $schema = $self->schema() ) {
        for my $fk ( grep { $_->has_column($col) }
            $schema->foreign_keys_for_table($self) ) {
            $schema->remove_foreign_key($fk);
        }
    }

    my $name = $col->name();

    for my $k ( $self->_keys() ) {
        $self->remove_candidate_key( $k->objects() )
            if $k->object($name);
    }

    $self->_columns()->delete($col);

    $col->_clear_table();

    return $self;
}

sub _build_candidate_keys {
    my $self = shift;

    return [ map { [ $_->objects() ] } $self->_keys() ];
}

sub _build_primary_key {
    my $self = shift;

    my $keys = $self->candidate_keys();

    return $keys->[0] || [];
}

sub add_candidate_key {
    my $self = shift;

    my $count = @_ ? @_ : 1;
    my (@cols) = pos_validated_list(
        \@_,
        ( ( { isa => ColumnOrName } ) x $count ),
        MX_PARAMS_VALIDATE_NO_CACHE => 1,
    );

    for my $name ( map { blessed $_ ? $_->name() : $_ } @cols ) {
        param_error "The column $name is not part of the "
            . $self->name()
            . ' table.'
            unless $self->column($name);
    }

    $_ = $self->column($_) for grep { !blessed $_ } @cols;

    return if $self->has_candidate_key(@cols);

    $self->_add_key( Fey::NamedObjectSet->new(@cols) );

    return;
}

sub remove_candidate_key {
    my $self = shift;

    my $count = @_ ? @_ : 1;
    my (@cols) = pos_validated_list(
        \@_,
        ( ( { isa => ColumnOrName } ) x $count ),
        MX_PARAMS_VALIDATE_NO_CACHE => 1,
    );

    for my $name ( map { blessed $_ ? $_->name() : $_ } @cols ) {
        param_error "The column $name is not part of the "
            . $self->name()
            . ' table.'
            unless $self->column($name);
    }

    $_ = $self->column($_) for grep { !blessed $_ } @cols;

    my $set = Fey::NamedObjectSet->new(@cols);

    my $idx = first_index { $_->is_same_as($set) } $self->_keys();

    $self->_delete_key( $idx, 1 )
        if $idx >= 0;

    return;
}

sub has_candidate_key {
    my $self = shift;

    my $count = @_ ? @_ : 1;
    my (@cols) = pos_validated_list(
        \@_,
        ( ( { isa => ColumnOrName } ) x $count ),
        MX_PARAMS_VALIDATE_NO_CACHE => 1,
    );

    for my $name ( map { blessed $_ ? $_->name() : $_ } @cols ) {
        param_error "The column $name is not part of the "
            . $self->name()
            . ' table.'
            unless $self->column($name);
    }

    $_ = $self->column($_) for grep { !blessed $_ } @cols;

    my $set = Fey::NamedObjectSet->new(@cols);

    return 1
        if any { $_->is_same_as($set) } $self->_keys();

    return 0;
}

# Caching the objects by name prevents a weird bug where we have two
# aliases of the same name, and one disappears because of weak
# references, causing weird errors.
around 'alias' => sub {
    my $orig = shift;
    my $self = shift;

    # bleh, duplicating code from Aliasable
    my %p = @_ == 1 ? ( alias_name => $_[0] ) : @_;

    if ( defined $p{alias_name} ) {
        return $self->_aliased_table( $p{alias_name} )
            if $self->_has_aliased_table( $p{alias_name} );
    }

    my $alias = $orig->( $self, %p );

    $self->_store_aliased_table( $alias->alias_name() => $alias );

    return $alias;
};

sub is_alias {0}

sub aliased_column {
    my $self   = shift;
    my $prefix = shift;
    my $name   = shift;

    my $col = $self->column($name)
        or return;

    return $col->alias( alias_name => $prefix . $col->name() );
}

sub aliased_columns {
    my $self   = shift;
    my $prefix = shift;

    my @names = @_ ? @_ : map { $_->name() } $self->columns();

    return map { $self->aliased_column( $prefix, $_ ) } @names;
}

sub sql {
    return $_[1]->quote_identifier( $_[0]->name() );
}

sub sql_with_alias { goto &sql }

sub _build_id { $_[0]->name() }

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a table (or view)

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::Table - Represents a table (or view)

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  my $table = Fey::Table->new( name => 'User' );

=head1 DESCRIPTION

This class represents a table or view in a schema. From the standpoint
of SQL construction in Fey, a table and a view are basically the same
thing.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Table->new()

  my $table = Fey::Table->new( name => 'User' );

  my $table = Fey::Table->new( name    => 'ActiveUser',
                               is_view => 1,
                             );

This method constructs a new C<Fey::Table> object. It takes the
following parameters:

=over 4

=item * name - required

The name of the table.

=item * is_view - defaults to 0

A boolean indicating whether this table is a view.

=back

=head2 $table->name()

Returns the name of the table.

=head2 $table->is_view()

Returns a boolean indicating whether the object is a view.

=head2 $table->schema()

Returns the C<Fey::Schema> object that this table belongs to. This is
set when the table is added to a schema via the C<<
Fey::Schema->add_table() >> method.

=head2 $table->add_column($column)

This adds a new column to the schema. The column must be a
C<Fey::Column> object. Adding the column to the table sets the table
for the column, so that C<< $column->table() >> returns the correct
object.

If the table already has a column with the same name, an exception is
thrown.

=head2 $table->remove_column($column)

Remove the specified column from the table. If the column was part of
any foreign keys, these are removed from the schema. If this column is
part of any keys for the table, those keys will be removed. Removing
the column unsets the table for the column.

The table can be specified either by name or by passing in a
C<Fey::Column> object.

=head2 $table->column($name)

Given a column name, this method returns the matching column object,
if one exists.

=head2 $table->columns

=head2 $table->columns(@names)

When this method is called with no arguments, it returns all of the columns in
the table. Columns are returned in the order with which they were added to the
table.

If given a list of names, it returns only the specified columns. If a name is
given which doesn't match a column in the table, then it is ignored.

=head2 $table->candidate_keys()

Returns all of the candidate keys for the table as an array
reference. Each element of the reference is in turn an array reference
containing one or more columns.

=head2 $table->has_candidate_key(@columns)

This method returns true if the table has the given key. A key is
identified as a list of names or C<Fey::Column> objects.

=head2 $table->add_candidate_key(@columns)

This method adds a new candidate key to the table. The list of columns
can contain either names or C<Fey::Column> objects.

A candidate key is one or more columns which uniquely identify a row
in that table.

If a name or column is specified which doesn't belong to the table, an
exception will be thrown.

=head2 $table->remove_candidate_key(@columns)

This method removes a candidate key for the table. The list of columns
can contain either names or C<Fey::Column> objects.

If a name or column is specified which doesn't belong to the table, an
exception will be thrown.

=head2 $table->primary_key()

This is a convenience method that simply returns the first candidate
key added to the table. The key is returned as an array reference of
column objects.

=head2 $table->alias(%p)

=head2 $table->alias($alias_name)

This method returns a new C<Fey::Table::Alias> object based on the
table. Any parameters passed to this method will be passed through to
C<< Fey::Table::Alias->new() >>.

As a shortcut, if you pass a single argument to this method, it will
be passed as the "alias_name" parameter to C<<
Fey::Table::Alias->new() >>.

=head2 $table->is_alias()

Always returns false.

=head2 $table->aliased_column( $prefix, $column_name )

This method returns a new L<Fey::Column::Alias> object. The alias's
name is generated by concatenating the specified prefix and the
column's real name.

=head2 $table->aliased_columns( $prefix, @column_names )

This method returns a list of new L<Fey::Column::Alias> objects. The
alias names are generated by concatenating the specified prefix and
the column's real name.

If you omit the list of column names, it returns aliases for I<all> of the
columns in table, in same order as returned by C<< $table->columns() >>.

=head2 $table->sql()

=head2 $table->sql_with_alias()

=head2 $table->sql_for_select_clause()

Returns the appropriate SQL snippet for the table.

=head2 $table->id()

Returns a unique identifier for the table.

=head1 ROLES

This class does the L<Fey::Role::TableLike>, L<Fey::Role::MakesAliasObjects>,
and L<Fey::Role::Named> roles.

=head1 BUGS

See L<Fey> for details on how to report bugs.

Bugs may be submitted at L<https://github.com/ap/Fey/issues>.

=head1 SOURCE

The source code repository for Fey can be found at L<https://github.com/ap/Fey>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2025 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
