package Fey::Table::Alias;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Fey::Exceptions qw(param_error);
use Fey::Table;
use Fey::Types qw( Column HashRef Str Table );

use Moose 2.1200;
use MooseX::Params::Validate 0.21 qw( pos_validated_list );
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.13;

with 'Fey::Role::TableLike';

has 'id' => (
    is         => 'ro',
    lazy_build => 1,
    init_arg   => undef,
);

has 'table' => (
    is      => 'ro',
    isa     => Table,
    handles => [ 'schema', 'name' ],
);

has 'alias_name' => (
    is         => 'ro',
    isa        => Str,
    lazy_build => 1,
);

has '_columns' => (
    traits  => ['Hash'],
    is      => 'bare',
    isa     => HashRef [Column],
    default => sub { {} },
    handles => {
        _get_column => 'get',
        _set_column => 'set',
        _has_column => 'exists',
    },
    init_arg => undef,
);

with 'Fey::Role::Named';

{
    my %Numbers;

    sub _build_alias_name {
        my $self = shift;

        my $name = $self->name();
        $Numbers{$name} ||= 0;

        return $name . ++$Numbers{$name};
    }
}

sub column {
    my $self = shift;
    my ($name) = pos_validated_list( \@_, { isa => 'Str' } );

    return $self->_get_column($name)
        if $self->_has_column($name);

    my $col = $self->table()->column($name)
        or return;

    my $clone = $col->_clone();
    $clone->_set_table($self);

    $self->_set_column( $name => $clone );

    return $clone;
}

sub columns {
    my $self = shift;

    my @cols = @_ ? @_ : map { $_->name() } $self->table()->columns();

    return map { $self->column($_) } @cols;
}

# Making this an attribute would be a hassle since we'd need to reset
# it whenever the associated table's keys changed.
sub primary_key {
    return [
        $_[0]->columns(
            map { $_->name() } @{ $_[0]->table()->primary_key() }
        )
    ];
}

sub is_alias {1}

sub sql_with_alias {
    return (  $_[1]->quote_identifier( $_[0]->table()->name() ) . ' AS '
            . $_[1]->quote_identifier( $_[0]->alias_name() ) );
}

sub _build_id { $_[0]->alias_name() }

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents an alias for a table

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::Table::Alias - Represents an alias for a table

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  my $alias = $user_table->alias();

  my $alias = $user_table->alias( alias_name => 'User2' );

=head1 DESCRIPTION

This class represents an alias for a table. Table aliases allow you to
join the same table more than once in a query, which makes certain
types of queries simpler to express.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Table::Alias->new()

This method constructs a new C<Fey::Table::Alias> object. It takes the
following parameters:

=over 4

=item * table - required

This is the C<Fey::Table> object which we are aliasing.

=item * alias_name - optional

This should be a valid table name for your DBMS. If not provided, a
unique name is automatically created.

=back

=head2 $alias->table()

Returns the C<Fey::Table> object for which this object is an alias.

=head2 $alias->alias_name()

Returns the name for this alias.

=head2 $alias->name()

=head2 $alias->schema()

These methods work like the corresponding methods in
C<Fey::Table>. The C<name()> method returns the real table name.

=head2 $alias->column($name)

=head2 $alias->columns()

=head2 $alias->columns(@names)

=head2 $alias->primary_key()

These methods work like the corresponding methods in
C<Fey::Table>. However, the columns they return will return the alias
object when C<< $column->table() >> is called.

=head2 $alias->is_alias()

Always returns true.

=head2 $alias->sql_with_alias()

=head2 $table->sql_for_select_clause()

Returns the appropriate SQL snippet for the alias.

=head2 $alias->id()

Returns a unique string identifying the alias.

=head1 ROLES

This class does the L<Fey::Role::TableLike> and L<Fey::Role::Named>
roles.

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
