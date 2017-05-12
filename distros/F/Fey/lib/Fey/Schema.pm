package Fey::Schema;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Fey::Exceptions qw( param_error );
use Fey::NamedObjectSet;
use Fey::SQL;
use Fey::Table;
use Fey::Types
    qw( FK HashRef NamedObjectSet Str Table TableLikeOrName TableOrName  );
use Scalar::Util qw( blessed );

use Moose 2.1200;
use MooseX::Params::Validate 0.21 qw( pos_validated_list );
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.13;

has 'name' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has '_tables' => (
    is      => 'ro',
    isa     => NamedObjectSet,
    default => sub { return Fey::NamedObjectSet->new() },
    handles => {
        tables => 'objects',
        table  => 'object',
    },
    init_arg => undef,
);

has '_fks' => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { {} },
    init_arg => undef,
);

sub add_table {
    my $self = shift;
    my ($table) = pos_validated_list( \@_, { isa => Table } );

    my $name = $table->name();
    param_error "The schema already contains a table named $name."
        if $self->table($name);

    $self->_tables->add($table);

    $table->_set_schema($self);

    return $self;
}

sub remove_table {
    my $self = shift;
    my ($table)
        = pos_validated_list( \@_, { isa => TableOrName } );

    $table = $self->table($table)
        unless blessed $table;

    for my $fk ( $self->foreign_keys_for_table($table) ) {
        $self->remove_foreign_key($fk);
    }

    $self->_tables()->delete($table);

    $table->_set_schema(undef);

    return $self;
}

sub add_foreign_key {
    my $self = shift;
    my ($fk) = pos_validated_list( \@_, { isa => FK } );

    my $fk_id = $fk->id();

    my $source_table_name = $fk->source_table()->name();

    for my $col_name ( map { $_->name() } @{ $fk->source_columns() } ) {
        $self->_fks()->{$source_table_name}{$col_name}{$fk_id} = $fk;
    }

    my $target_table_name = $fk->target_table()->name();

    for my $col_name ( map { $_->name() } @{ $fk->target_columns() } ) {
        $self->_fks()->{$target_table_name}{$col_name}{$fk_id} = $fk;
    }

    return $self;
}

sub remove_foreign_key {
    my $self = shift;
    my ($fk) = pos_validated_list( \@_, { isa => FK } );

    my $fk_id = $fk->id();

    my $source_table_name = $fk->source_table()->name();
    for my $col_name ( map { $_->name() } @{ $fk->source_columns() } ) {
        delete $self->_fks()->{$source_table_name}{$col_name}{$fk_id};
    }

    my $target_table_name = $fk->target_table()->name();
    for my $col_name ( map { $_->name() } @{ $fk->target_columns() } ) {
        delete $self->_fks()->{$target_table_name}{$col_name}{$fk_id};
    }

    return $self;
}

sub foreign_keys_for_table {
    my $self = shift;
    my ($table)
        = pos_validated_list( \@_, { isa => TableOrName } );

    my $name = blessed $table ? $table->name() : $table;

    my %fks = (
        map { $_->id() => $_ }
            map { values %{ $self->_fks()->{$name}{$_} } }
            keys %{ $self->_fks()->{$name} || {} }
    );

    return values %fks;
}

sub foreign_keys_between_tables {
    my $self = shift;
    my ( $table1, $table2 ) = pos_validated_list(
        \@_,
        { isa => TableLikeOrName },
        { isa => TableLikeOrName }
    );

    my $name1
        = !blessed $table1           ? $table1
        : $table1->isa('Fey::Table') ? $table1->name()
        :                              $table1->table()->name();

    my $name2
        = !blessed $table2           ? $table2
        : $table2->isa('Fey::Table') ? $table2->name()
        :                              $table2->table()->name();

    my %fks = (
        map { $_->id() => $_ }
            grep { $_->has_tables( $name1, $name2 ) }
            map { values %{ $self->_fks()->{$name1}{$_} } }
            keys %{ $self->_fks()->{$name1} || {} }
    );

    return values %fks
        unless grep { blessed $_ && $_->is_alias() } $table1, $table2;

    $table1 = $self->table($name1)
        unless blessed $table1;

    $table2 = $self->table($name2)
        unless blessed $table2;

    my @fks;

    for my $fk ( values %fks ) {
        my %p
            = $table1->name() eq $fk->source_table()->name()
            ? (
            source_columns => [
                $table1->columns(
                    map { $_->name() } @{ $fk->source_columns() }
                )
            ],
            target_columns => [
                $table2->columns(
                    map { $_->name() } @{ $fk->target_columns() }
                )
            ],
            )
            : (
            source_columns => [
                $table2->columns(
                    map { $_->name() } @{ $fk->source_columns() }
                )
            ],
            target_columns => [
                $table1->columns(
                    map { $_->name() } @{ $fk->target_columns() }
                )
            ],
            );

        push @fks, Fey::FK->new(%p);
    }

    return @fks;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a schema and contains tables and foreign keys

__END__

=pod

=head1 NAME

Fey::Schema - Represents a schema and contains tables and foreign keys

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  my $schema = Fey::Schema->new( name => 'MySchema' );

  $schema->add_table(...);

  $schema->add_foreign_key(...);

=head1 DESCRIPTION

This class represents a schema, which is a set of tables and foreign
keys.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Schema->new()

  my $schema = Fey::Schema->new( name => 'MySchema' );

This method constructs a new C<Fey::Schema> object. It takes the
following parameters:

=over 4

=item * name - required

The name of the schema.

=back

=head2 $schema->name()

Returns the name of the schema.

=head2 $schema->add_table($table)

Adds the specified table to the schema. The table must be a
C<Fey::Table> object. Adding the table to the schema sets the schema
for the table, so that C<< $table->schema() >> returns the correct
object.

If the table is already part of the schema, an exception will be
thrown.

=head2 $schema->remove_table($table)

Remove the specified table from the schema. Removing the table also
removes any foreign keys which reference the table. Removing the table
unsets the schema for the table.

The table can be specified either by name or by passing in a
C<Fey::Table> object.

=head2 $schema->table($name)

Returns the table with the specified name. If no such table exists,
this method returns false.

=head2 $schema->tables()

=head2 $schema->tables(@names)

When this method is called with no arguments, it returns all of the tables in
the schema. Tables are returned in the order with which they were added to the
schema.

If given a list of names, it returns only the specified tables. If a name is
given which doesn't match a table in the schema, then it is ignored.

=head2 $schema->add_foreign_key($fk)

Adds the specified to the schema. The foreign key must be a C<Fey::FK>
object.

If the foreign key references tables which are not in the schema, an
exception will be thrown.

=head2 $schema->remove_foreign_key($fk)

Removes the specified foreign key from the schema. The foreign key
must be a C<Fey::FK> object.

=head2 $schema->foreign_keys_for_table($table)

Returns all the foreign keys which reference the specified table. The
table can be specified as a name or a C<Fey::Table> object.

=head2 $schema->foreign_keys_between_tables( $source_table, $target_table )

Returns all the foreign keys which reference both tables. The tables
can be specified as names, C<Fey::Table> objects, or
C<Fey::Table::Alias> objects. If you provide any aliases, the foreign
keys returned will contain columns from those aliases, not the real
tables. This provides support for joining an alias in a SQL statement.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
