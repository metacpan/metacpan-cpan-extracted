package Fey::Column::Alias;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Fey::Exceptions qw( object_state_error );
use Fey::Table;
use Fey::Table::Alias;
use Fey::Types qw( Column Str );

use Moose 2.1200;
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.13;

with 'Fey::Role::ColumnLike';

has 'id' => (
    is         => 'ro',
    lazy_build => 1,
    init_arg   => undef,
    clearer    => '_clear_id',
);

has 'column' => (
    is      => 'ro',
    isa     => Column,
    handles => [
        qw( name type generic_type length precision
            is_auto_increment is_nullable table )
    ],
);

has 'alias_name' => (
    is         => 'ro',
    isa        => Str,
    lazy_build => 1,
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

sub is_alias {1}

sub sql { $_[1]->quote_identifier( $_[0]->alias_name() ) }

sub sql_with_alias {
    my $sql = $_[1]->quote_identifier(
        undef,
        $_[0]->_containing_table_name_or_alias(),
        $_[0]->name(),
    );

    $sql .= ' AS ';
    $sql .= $_[1]->quote_identifier( $_[0]->alias_name() );

    return $sql;
}

sub sql_or_alias { goto &sql }

sub _build_id {
    my $self = shift;

    my $table = $self->table();

    object_state_error
        'The id attribute cannot be determined for a column object which has no table.'
        unless $table;

    return $table->id() . '.' . $self->alias_name();
}

__PACKAGE__->meta()->make_immutable();

# This is here to avoid a circular use issue.
require Fey::Column;

1;

# ABSTRACT: Represents an alias for a column

__END__

=pod

=head1 NAME

Fey::Column::Alias - Represents an alias for a column

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  my $alias = $user_id_col->alias();

=head1 DESCRIPTION

This class represents an alias for a column. Column aliases allow you
to use the same column in different ways multiple times in a query,
which makes certain types of queries simpler to express.

=head1 METHODS

=head2 Fey::Column::Alias->new()

This method constructs a new C<Fey::Column::Alias> object. It takes
the following parameters:

=over 4

=item * column - required

This is the C<Fey::Column> object which we are aliasing.

=item * alias_name - optional

This should be a valid column name for your DBMS. If not provided, a
unique name is automatically created.

=back

=head2 $alias->name()

This returns the name of the column for which this object is an alias.

=head2 $alias->alias_name()

Returns the name for this alias.

=head2 $alias->type()

=head2 $alias->generic_type()

=head2 $alias->length()

=head2 $alias->precision()

=head2 $alias->is_auto_increment()

=head2 $alias->is_nullable()

=head2 $alias->default()

Returns the specified attribute for the column, just like the
C<Fey::Column> methods of the same name.

=head2 $alias->table()

Returns the C<Fey::Table> object to which the column alias belongs, if
any.

=head2 $alias->is_alias()

Always returns false.

=head2 $alias->sql()

=head2 $alias->sql_with_alias()

=head2 $alias->sql_or_alias()

Returns the appropriate SQL snippet for the alias.

=head2 $alias->id()

Returns a unique identifier for the column. This method throws an
exception if the alias does not belong to a table.

=head1 ROLES

This class does the L<Fey::Role::ColumnLike> and L<Fey::Role::Named>
roles.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
