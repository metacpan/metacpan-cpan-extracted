package Fey::SQL::Insert;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Fey::Types
    qw( ArrayRef HashRef CanQuote IntoElement NonNullableInsertValue
    NullableInsertValue );
use overload ();
use Scalar::Util qw( blessed );

use Moose 2.1200;
use MooseX::Params::Validate 0.21 qw( validated_hash pos_validated_list );
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.13;

with 'Fey::Role::SQL::HasBindParams';

has '_into' => (
    is       => 'rw',
    isa      => ArrayRef,
    init_arg => undef,
);

has '_values_spec' => (
    is       => 'rw',
    isa      => HashRef,
    init_arg => undef,
);

has '_values' => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => ArrayRef [HashRef],
    default => sub { [] },
    handles => {
        _add_values => 'push',
        _values     => 'elements',
    },
    init_arg => undef,
);

with 'Fey::Role::SQL::Cloneable';

sub insert { return $_[0] }

sub into {
    my $self = shift;

    my $count = @_ ? scalar @_ : 1;
    my @into = pos_validated_list(
        \@_,
        ( ( { isa => IntoElement } ) x $count ),
        MX_PARAMS_VALIDATE_NO_CACHE => 1,
    );

    my @cols;
    for my $elt (@into) {
        push @cols, $elt->isa('Fey::Table')
            ? $elt->columns
            : $elt;
    }

    $self->_set_into( \@cols );

    my %spec;
    for my $col ( @{ $self->_into() } ) {
        $spec{ $col->name() }
            = $col->is_nullable()
            ? { isa => NullableInsertValue }
            : { isa => NonNullableInsertValue };
    }

    $self->_set_values_spec( \%spec );

    return $self;
}

sub values {
    my $self = shift;

    my %vals = validated_hash(
        \@_,
        %{ $self->_values_spec() },
        MX_PARAMS_VALIDATE_NO_CACHE => 1
    );

    for my $col_name (
        grep { exists $vals{$_} }
        map  { $_->name() } @{ $self->_into() }
        ) {
        my $val = $vals{$col_name};

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

        $vals{$col_name} = $val;
    }

    $self->_add_values( \%vals );

    return $self;
}

sub sql {
    my $self = shift;
    my ($dbh) = pos_validated_list( \@_, { isa => CanQuote } );

    return (
        join ' ',
        $self->insert_clause($dbh),
        $self->columns_clause($dbh),
        $self->values_clause($dbh),
    );
}

sub insert_clause {
    return ( 'INSERT INTO '
            . $_[1]->quote_identifier( $_[0]->_into()->[0]->table()->name() )
    );
}

sub columns_clause {
    return (
        '('
            . (
            join ', ',
            map { $_[1]->quote_identifier( $_->name() ) } @{ $_[0]->_into() }
            )
            . ')'
    );
}

sub values_clause {
    my $self = shift;
    my $dbh  = shift;

    my @cols = @{ $self->_into() };

    my @v;
    for my $vals ( $self->_values() ) {
        my $v = '(';

        $v .= (
            join ', ',
            map {
                my $val = $vals->{ $_->name() };
                my $sql = $val->sql($dbh);
                blessed $val
                    && $val->can('does')
                    && $val->does('Fey::Role::SQL::ReturnsData')
                    ? "($sql)"
                    : $sql
            } @cols
        );

        $v .= ')';

        push @v, $v;
    }

    return 'VALUES ' . join ',', @v;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a INSERT query

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::SQL::Insert - Represents a INSERT query

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  my $sql = Fey::SQL->new_insert();

  # INSERT INTO Part
  #             (part_id, name, quantity)
  #      VALUES
  #             (?, ?, ?)
  $sql->insert()->into($Part);

  my $ph = Fey::Placeholder->new();

  $sql->values( part_id  => $ph,
                name     => $ph,
                quantity => $ph,
              );

  print $sql->sql($dbh);

=head1 DESCRIPTION

This class represents a C<INSERT> query.

=head1 METHODS

This class provides the following methods:

=head2 Constructor

To construct an object of this class, call C<< $query->insert() >> on
a C<Fey::SQL> object.

=head2 $insert->insert()

This method is basically a no-op that exists to so that L<Fey::SQL>
has something to call after it constructs an object in this class.

=head2 $insert->into()

This method specifies the C<INTO> clause of the query. It expects a
list of L<Fey::Column> and/or L<Fey::Table> objects, but not aliases.

If you pass a table object, then the C<INTO> will include all of that
table's columns, in the order returned by the C<< $table->columns() >>
method.

Most RDBMS implementations only allow for a single table here, but
some (like MySQL) do allow for multi-table inserts.

=head2 $insert->values(...)

This method takes a hash where the keys are column names, and values are the
value to be inserted for that column. Each value can be of the following:

=over 4

=item * a plain scalar, including undef

This will be passed to C<< Fey::Literal->new_from_scalar() >>.

=item * C<Fey::Literal> object

=item * C<Fey::Placeholder> object

=back

You can call this method multiple times in order to do a multi-row
insert.

=head2 $insert->sql()

Returns the full SQL statement which this object represents. A DBI
handle must be passed so that identifiers can be properly quoted.

=head2 $insert->bind_params()

See the L<Fey::SQL section on Bind Parameters|Fey::SQL/Bind
Parameters> for more details.

=head2 $insert->insert_clause()

Returns the C<INSERT INTO> clause portion of the SQL statement as a
string (just the tables).

=head2 $insert->columns_clause()

Returns the portion of the SQL statement containing the columns for
which values are being inserted as a string.

=head2 $insert->values_clause()

Returns the C<VALUES> clause portion of the SQL statement as a string.

=head1 ROLES

=over 4

=item * L<Fey::Role::SQL::HasBindParams>

=item * L<Fey::Role::SQL::Cloneable>

=back

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
