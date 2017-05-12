package Fey::SQL::Update;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Fey::Exceptions qw( param_error );
use Fey::Literal;
use Fey::Types qw( ArrayRef CanQuote ColumnWithTable NonNullableUpdateValue
    NullableUpdateValue Table );
use overload ();
use Scalar::Util qw( blessed );

use Moose 2.1200;
use MooseX::Params::Validate 0.21 qw( pos_validated_list );
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.13;

with 'Fey::Role::SQL::HasOrderByClause', 'Fey::Role::SQL::HasLimitClause';

with 'Fey::Role::SQL::HasWhereClause' => {
    -excludes => 'bind_params',
    -alias    => { bind_params => '_where_clause_bind_params' },
};

with 'Fey::Role::SQL::HasBindParams' => {
    -excludes => 'bind_params',
    -alias    => { bind_params => '_update_bind_params' },
};

has '_update' => (
    is       => 'rw',
    isa      => ArrayRef,
    default  => sub { [] },
    init_arg => undef,
);

has '_set_pairs' => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => ArrayRef [ArrayRef],
    default => sub { [] },
    handles => {
        _add_set_pair => 'push',
        _set_pairs    => 'elements',
    },
    init_arg => undef,
);

with 'Fey::Role::SQL::Cloneable';

sub update {
    my $self = shift;

    my $count = @_ ? @_ : 1;
    my (@tables) = pos_validated_list(
        \@_,
        ( ( { isa => Table } ) x $count ),
        MX_PARAMS_VALIDATE_NO_CACHE => 1,
    );

    $self->_set_update( \@tables );

    return $self;
}

sub set {
    my $self = shift;

    if ( !@_ || @_ % 2 ) {
        my $count = @_;
        param_error
            "The set method expects a list of paired column objects and values but you passed $count parameters";
    }

    my @spec;
    for ( my $x = 0; $x < @_; $x += 2 ) {
        push @spec, { isa => ColumnWithTable };
        push @spec,
            blessed $_[$x] && $_[$x]->is_nullable()
            ? { isa => NullableUpdateValue }
            : { isa => NonNullableUpdateValue };
    }

    my @set
        = pos_validated_list( \@_, @spec, MX_PARAMS_VALIDATE_NO_CACHE => 1 );

    for ( my $x = 0; $x < @_; $x += 2 ) {
        my $val = $_[ $x + 1 ];

        $val .= ''
            if blessed $val && overload::Overloaded($val);

        if ( !blessed $val ) {
            if ( defined $val && $self->auto_placeholders() ) {
                $self->_add_bind_param($val);

                $val = Fey::Placeholder->new();
            }
            else {
                $val = Fey::Literal->new_from_scalar($val);
            }
        }

        $self->_add_set_pair( [ $_[$x], $val ] );
    }

    return $self;
}

sub sql {
    my $self = shift;
    my ($dbh) = pos_validated_list( \@_, { isa => CanQuote } );

    return (
        join ' ',
        $self->update_clause($dbh),
        $self->set_clause($dbh),
        $self->where_clause($dbh),
        $self->order_by_clause($dbh),
        $self->limit_clause($dbh),
    );
}

sub update_clause {
    return 'UPDATE ' . $_[0]->_tables_subclause( $_[1] );
}

sub _tables_subclause {
    return (
        join ', ',
        map { $_[1]->quote_identifier( $_->name() ) } @{ $_[0]->_update() }
    );
}

sub set_clause {
    my $self = shift;
    my $dbh  = shift;

    # SQLite objects when the table name is provided ("User"."email")
    # on the LHS of the set. I'm hoping that a DBMS which allows a
    # multi-table update also allows the table name in the LHS.
    my $col_quote = @{ $self->_update() } > 1 ? '_name_and_table' : '_name';

    return (
        'SET ' . (
            join ', ',
            map {
                my $val     = $_->[1];
                my $val_sql = $val->sql($dbh);
                $val_sql = "($val_sql)"
                    if blessed $val
                    && $val->can('does')
                    && $val->does('Fey::Role::SQL::ReturnsData');
                $self->$col_quote( $_->[0], $dbh ) . ' = ' . $val_sql;
            } $self->_set_pairs()
        )
    );
}

sub _name_and_table {
    return $_[1]->sql( $_[2] );
}

sub _name {
    return $_[2]->quote_identifier( $_[1]->name() );
}

sub bind_params {
    my $self = shift;

    return (
        $self->_update_bind_params(),
        $self->_where_clause_bind_params(),
    );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a UPDATE query

__END__

=pod

=head1 NAME

Fey::SQL::Update - Represents a UPDATE query

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  my $sql = Fey::SQL->new_update();

  # UPDATE Part
  #    SET quantity = 10
  #  WHERE part_id IN (1, 5)
  $sql->update($Part);
  $sql->set( $quantity, 10 );
  $sql->where( $part_id, 'IN', 1, 5 );

  print $sql->sql($dbh);

=head1 DESCRIPTION

This class represents a C<UPDATE> query.

=head1 METHODS

This class provides the following methods:

=head2 Constructor

To construct an object of this class, call C<< $query->update() >> on
a C<Fey::SQL> object.

=head2 $update->update()

This method specifies the C<UPDATE> clause of the query. It expects
one or more L<Fey::Table> objects (not aliases). Most RDBMS
implementations only allow for a single table here, but some (like
MySQL) do allow for multi-table updates.

=head2 $update->set(...)

This method takes a list of key/value pairs. The keys should be column
objects, and the value can be one of the following:

=over 4

=item * a plain scalar, including undef

This will be passed to C<< Fey::Literal->new_from_scalar() >>.

=item * C<Fey::Literal> object

=item * C<Fey::Column> object

A column alias cannot be used.

=item * C<Fey::Placeholder> object

=back

=head2 $update->where(...)

See the L<Fey::SQL section on WHERE Clauses|Fey::SQL/WHERE Clauses>
for more details.

=head2 $update->order_by(...)

See the L<Fey::SQL section on ORDER BY Clauses|Fey::SQL/ORDER BY
Clauses> for more details.

=head2 $update->limit(...)

See the L<Fey::SQL section on LIMIT Clauses|Fey::SQL/LIMIT Clauses>
for more details.

=head2 $update->sql($dbh)

Returns the full SQL statement which this object represents. A DBI
handle must be passed so that identifiers can be properly quoted.

=head2 $update->bind_params()

See the L<Fey::SQL section on Bind Parameters|Fey::SQL/Bind
Parameters> for more details.

=head2 $update->update_clause()

Returns the C<UPDATE> clause portion of the SQL statement as a string.

=head2 $update->set_clause()

Returns the C<SET> clause portion of the SQL statement as a string.

=head2 $update->where_clause()

Returns the C<WHERE> clause portion of the SQL statement as a string.

=head2 $update->order_by_clause()

Returns the C<ORDER BY> clause portion of the SQL statement as a
string.

=head2 $update->limit_clause()

Returns the C<LIMIT> clause portion of the SQL statement as a string.

=head1 ROLES

=over 4

=item * L<Fey::Role::SQL::HasBindParams>

=item * L<Fey::Role::SQL::HasWhereClause>

=item * L<Fey::Role::SQL::HasOrderByClause>

=item * L<Fey::Role::SQL::HasLimitClause>

=item * L<Fey::Role::SQL::Cloneable>

=back

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
