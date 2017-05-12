package Fey::SQL::Select;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Fey::Exceptions qw( param_error );
use Fey::Literal;
use Fey::Role::ColumnLike;
use Fey::SQL::Fragment::Join;
use Fey::Types
    qw( ArrayRef Bool HashRef CanQuote GroupByElement SelectElement );
use List::AllUtils qw( all );
use Scalar::Util qw( blessed );

use Moose 2.1200;
use MooseX::Params::Validate 0.21 qw( pos_validated_list );
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.13;

with 'Fey::Role::Comparable',
    'Fey::Role::Selectable',
    'Fey::Role::SQL::HasOrderByClause',
    'Fey::Role::SQL::HasLimitClause',
    'Fey::Role::SQL::ReturnsData';

with 'Fey::Role::SQL::HasWhereClause' => {
    -excludes => 'bind_params',
    -alias    => { bind_params => '_where_clause_bind_params' },
};

with 'Fey::Role::SQL::HasBindParams' => { -excludes => 'bind_params' };

with 'Fey::Role::HasAliasName' => {
    generated_alias_prefix => 'SUBSELECT',
    sql_needs_parens       => 1,
};

has '_select' => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => ArrayRef,
    default => sub { [] },
    handles => {
        _add_select_element    => 'push',
        select_clause_elements => 'elements',
    },
    init_arg => undef,
);

has 'is_distinct' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
    writer  => '_set_is_distinct',
);

has 'is_distinct_on' => (
    is        => 'rw',
    does      => 'Fey::Role::ColumnLike',
    writer    => '_set_is_distinct_on',
    predicate => '_has_is_distinct_on',
);

has '_from' => (
    traits  => ['Hash'],
    is      => 'bare',
    isa     => HashRef,
    default => sub { {} },
    handles => {
        _get_from => 'get',
        _set_from => 'set',
        _from_ids => 'keys',
    },
    init_arg => undef,
);

has '_group_by' => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => ArrayRef,
    default => sub { [] },
    handles => {
        _add_group_by_elements => 'push',
        _has_group_by_elements => 'count',
        _group_by              => 'elements',
    },
    init_arg => undef,
);

has '_having' => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => ArrayRef,
    default => sub { [] },
    handles => {
        _add_having_element  => 'push',
        _has_having_elements => 'count',
        _last_having_element => [ 'get', -1 ],
        _having              => 'elements',
    },
    init_arg => undef,
);

with 'Fey::Role::SQL::Cloneable';

sub select {
    my $self = shift;

    my $count = @_ ? @_ : 1;
    my (@select) = pos_validated_list(
        \@_,
        ( ( { isa => SelectElement } ) x $count ),
        MX_PARAMS_VALIDATE_NO_CACHE => 1,
    );

    for my $elt (@select) {
        $self->_add_select_element(
            blessed $elt ? $elt : Fey::Literal->new_from_scalar($elt) );
    }

    return $self;
}

sub distinct {
    die 'Cannot call ->distinct and ->distinct_on'
        if $_[0]->_has_is_distinct_on();

    $_[0]->_set_is_distinct(1);

    return $_[0];
}

sub distinct_on {
    die 'Cannot call ->distinct and ->distinct_on'
        if $_[0]->is_distinct();

    $_[0]->_set_is_distinct_on( $_[1] );

    return $_[0];
}

# XXX - need to handle subselect as if it were a table rather than as
# a special case
sub from {
    my $self = shift;

    # $t1, 'LEFT', $t2, ...
    my $is_outer_join = @_ >= 3 && !blessed $_[1];

    my $is_inner_join = @_ >= 2 && !$is_outer_join;

    # gee, wouldn't multimethods be nice here?

    #<<<
    my $meth = (
        @_ == 1
            && blessed $_[0]
            && $_[0]->can('is_joinable')
            && $_[0]->is_joinable()
          ? '_from_one_table'

        : @_ == 1
            && blessed $_[0]
            && $_[0]->can('does')
            && $_[0]->does('Fey::Role::SQL::ReturnsData')
          ? '_from_subselect'

        : $is_inner_join
            && @_ == 4 && $_[3]->isa('Fey::SQL::Where')
          ? '_join_with_where'

        : $is_inner_join
            && @_ == 3 && $_[2]->isa('Fey::SQL::Where')
          ? '_join_with_where'

        : $is_inner_join && @_ == 3 && $_[2]->isa('Fey::FK')
          ? '_join'

        : $is_inner_join && @_ == 2
          ? '_join'

        : $is_outer_join && @_ == 5
          ? '_outer_join_with_where'

        : $is_outer_join
            && @_ == 4
            && $_[3]->isa('Fey::SQL::Where')
          ? '_outer_join_with_where'

        : $is_outer_join && @_ == 4 && $_[3]->isa('Fey::FK')
           ? '_outer_join'

        : $is_outer_join && @_ == 3
          ? '_outer_join'

        : undef
    );
    #>>>

    param_error "from() called with invalid parameters (@_)."
        unless $meth;

    $self->$meth(@_);

    return $self;
}

sub _from_one_table {
    my $self = shift;

    my $join = Fey::SQL::Fragment::Join->new( table1 => $_[0] );
    $self->_set_from( $join->id() => $join );
}

sub _from_subselect {
    my $self = shift;

    my $subsel = $_[0];
    $self->_set_from( $subsel->id() => $subsel );
}

sub _join {
    my $self = shift;

    _check_join_arguments(@_);

    my $fk = $_[2] || $self->_fk_for_join(@_);

    my $join = Fey::SQL::Fragment::Join->new(
        table1 => $_[0],
        table2 => $_[1],
        fk     => $fk,
    );
    $self->_set_from( $join->id() => $join );
}

sub _join_with_where {
    my $self = shift;

    _check_join_arguments(@_);

    my $where = pop;
    my $fk = @_ == 3 ? pop : $self->_fk_for_join(@_);

    my $join = Fey::SQL::Fragment::Join->new(
        table1 => $_[0],
        table2 => $_[1],
        fk     => $fk,
        where  => $where,
    );
    $self->_set_from( $join->id() => $join );
}

sub _check_join_arguments {
    param_error
        'the first two arguments to from() were not valid (not tables or something else joinable).'
        unless
        all { blessed $_ && $_->can('is_joinable') && $_->is_joinable() }
    @_[ 0, 1 ];
}

sub _fk_for_join {
    my $self   = shift;
    my @tables = @_;

    my $s  = $tables[0]->schema;
    my @fk = $s->foreign_keys_between_tables(@tables);

    unless ( @fk == 1 ) {
        my $names = join ' and ', sort map { $_->name() } @tables;

        param_error
            "You specified a join for two tables that do not share a foreign key ($names)."
            unless @fk;

        param_error
            "You specified a join for two tables with more than one foreign key ($names)"
            . ', so you must specify which foreign key to use for the join.';
    }

    return $fk[0];
}

sub _outer_join {
    my $self = shift;

    _check_outer_join_arguments(@_);

    # I used to have ...
    #
    #  $_[3] || $self->_fk_for_join( @_[0, 2] )
    #
    # but this ends up reducing code coverage because it's not
    # possible (I hope) to have a situation where both are false.
    my $fk = $_[3];
    $fk = $self->_fk_for_join( @_[ 0, 2 ] )
        unless $fk;

    my $join = Fey::SQL::Fragment::Join->new(
        table1     => $_[0],
        table2     => $_[2],
        fk         => $fk,
        outer_type => lc $_[1],
    );
    $self->_set_from( $join->id() => $join );
}

sub _outer_join_with_where {
    my $self = shift;

    _check_outer_join_arguments(@_);

    my $fk;
    $fk = $_[3]->isa('Fey::FK') ? $_[3] : $self->_fk_for_join( @_[ 0, 2 ] );

    my $where = $_[4] ? $_[4] : $_[3];

    my $join = Fey::SQL::Fragment::Join->new(
        table1     => $_[0],
        table2     => $_[2],
        fk         => $fk,
        outer_type => lc $_[1],
        where      => $where,
    );
    $self->_set_from( $join->id() => $join );
}

sub _check_outer_join_arguments {
    param_error
        'invalid outer join type, must be one of out left, right, or full.'
        unless $_[1] =~ /^(?:left|right|full)$/i;

    param_error 'from() was called with invalid arguments'
        unless $_[0]->can('is_joinable')
        && $_[0]->is_joinable()
        && $_[2]->can('is_joinable')
        && $_[2]->is_joinable();
}

sub group_by {
    my $self = shift;

    my $count = @_ ? @_ : 1;
    my (@by) = pos_validated_list(
        \@_,
        ( ( { isa => GroupByElement } ) x $count ),
        MX_PARAMS_VALIDATE_NO_CACHE => 1,
    );

    $self->_add_group_by_elements(@by);

    return $self;
}

sub having {
    my $self = shift;

    $self->_condition( 'having', @_ );

    return $self;
}

sub id {
    return $_[0]->sql('Fey::FakeDBI');
}

sub sql {
    my $self = shift;
    my ($dbh) = pos_validated_list( \@_, { isa => CanQuote } );

    return (
        join q{ },
        $self->select_clause($dbh),
        $self->from_clause($dbh),
        $self->where_clause($dbh),
        $self->group_by_clause($dbh),
        $self->having_clause($dbh),
        $self->order_by_clause($dbh),
        $self->limit_clause($dbh),
    );
}

sub select_clause {
    my $self = shift;
    my $dbh  = shift;

    my $sql = 'SELECT ';

    if ( $self->is_distinct() ) {
        $sql .= 'DISTINCT ';
    }
    elsif ( $self->_has_is_distinct_on() ) {
        $sql .= 'DISTINCT ON ('
            . $self->is_distinct_on()->sql_or_alias($dbh) . ') ';
    }

    $sql .= (
        join ', ',
        map {
                  $_->can('sql_for_select_clause')
                ? $_->sql_for_select_clause($dbh)
                : $_->sql_with_alias($dbh)
        } $self->select_clause_elements()
    );

    return $sql;
}

sub from_clause {
    my $self = shift;
    my $dbh  = shift;

    my @from;

    my %seen;

    # We lower case the test for correctly skipping already-seen tables.
    for my $frag (
        $self->_get_from( sort { lc($a) cmp lc($b) } $self->_from_ids() ) ) {
        my $join_sql = $frag->sql_with_alias( $dbh, \%seen );

        # the fragment could be a Fey::SQL::Select itself
        my @tables = $frag->can('tables') ? $frag->tables() : ();

        $seen{ $_->id() } = 1 for @tables;

        next unless length $join_sql;

        push @from, $join_sql;
    }

    my $sql = 'FROM ';

    # This is a sort of manual join() call special-cased to add a
    # comma as needed.
    for ( my $i = 0; $i < @from; $i++ ) {
        $sql .= $from[$i];

        if ( $sql =~ /\)^/ ) {
            $sql .= q{ };
        }
        elsif ( ( $from[ $i + 1 ] || '' ) =~ /^[\w\s]*JOIN/ ) {
            $sql .= q{ };
        }
        elsif ( $from[ $i + 1 ] ) {
            $sql .= q{, };
        }
    }

    return $sql;
}

sub group_by_clause {
    my $self = shift;
    my $dbh  = shift;

    return unless $self->_has_group_by_elements();

    return (
        'GROUP BY '
            . (
            join ', ',
            map { $_->sql_or_alias($dbh) } $self->_group_by()
            )
    );
}

sub having_clause {
    my $self = shift;
    my $dbh  = shift;

    return unless $self->_has_having_elements();

    return (
        'HAVING '
            . (
            join ' ',
            map { $_->sql($dbh) } $self->_having()
            )
    );
}

sub bind_params {
    my $self = shift;

    return (
        (
            map      { $_->bind_params() }
                grep { $_->can('bind_params') }
                $self->select_clause_elements()
        ),

        (
            map  { $_->bind_params() }
            grep { $_->can('bind_params') }
            map  { $self->_get_from($_) }
            sort $self->_from_ids()
        ),

        $self->_where_clause_bind_params(),

        (
            map  { $_->bind_params() }
            grep { $_->can('bind_params') } $self->_having()
        ),
    );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a SELECT query

__END__

=pod

=head1 NAME

Fey::SQL::Select - Represents a SELECT query

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  my $sql = Fey::SQL->new_select();

  # SELECT Part.part_id, Part.part_name
  #   FROM Part JOIN MachinePart
  #        ON Part.part_id = MachinePart.part_id
  #  WHERE MachinePart.machine_id = $value
  # ORDER BY Part.name DESC
  # LIMIT 10
  $sql->select( $part_id, $part_name );
  $sql->from( $Part, $MachinePart );
  $sql->where( $machine_id, '=', $value );
  $sql->order_by( $part_Name, 'DESC' );
  $sql->limit(10);

  print $sql->sql($dbh);

=head1 DESCRIPTION

This class represents a C<SELECT> query.

=head1 METHODS

This class provides the following methods:

=head2 Constructor

To construct an object of this class, call C<< $query->select() >> on
a C<Fey::SQL> object.

=head2 $select->select(...)

This method accepts a list of parameters, which are the things being
selected.

The list can include the following types of elements:

=over 4

=item * plain scalars, including C<undef>

These will be passed to C<< Fey::Literal->new_from_scalar() >>.

=item * C<Fey::Table> objects

If a table is passed, then all of its columns will be included in the
C<SELECT> clause.

=item * C<Fey::Column> objects, and aliases

This specifies an individual column (possibly aliased) to include in
the select.

The C<< $column->is_selectable() >> method must return true for these
objects.

This method can be called multiple times with different elements each
time.

=item * C<Fey::Literal> objects

Any type of literal can be included in a C<SELECT> clause.

=back

=head2 $select->distinct()

If this is called, the generated SQL will start with C<SELECT DISTINCT>. You
cannot call both C<< $select->distinct() >> and C<< $select->distinct_on() >>
for the same query.

=head2 $select->distinct_on($column)

If this is called, the generated SQL will start with C<SELECT DISTINCT ON
(Table.column)>. You cannot call both C<< $select->distinct() >> and C<<
$select->distinct_on() >> for the same query.

=head2 $select->from(...)

This method specifies the C<FROM> clause of the query. It can accept a
variety of argument lists.

=over 4

=item * ($table_or_alias)

If called with a single C<Fey::Table> or table alias object, that
table is included in the C<FROM> clause.

  FROM Part

  FROM Part as Part0

=item * ($select_query)

If called with a single C<Fey::SQL::Select> object, that object's SQL
will be included in the C<FROM> clause as a subselect.

  FROM (SELECT part_id FROM Part) AS SUBSELECT0

=item * ($table1, $table2)

If two tables (or aliases) are passed to this method, these two tables
are included and joined together. The foreign key between these two
tables will be looked up in the C<Fey::Schema> object for the
tables. However, if the tables do not have a foreign key between them,
or have more than one foreign key, an exception is thrown.

  FROM Part, MachinePart
       ON Part.part_id = MachinePart.part_id

=item * ($table1, $table2, $fk)

When joining two tables, you can manually specify the foreign key
which should be used to join them. This is necessary when there are
multiple foreign keys between two tables.

You can also use this to "fake" a foreign key between two tables which
don't really have one, but where it makes sense to join them
anyway. If this paragraph doesn't make sense, don't worry about it ;)

=item * ($table1, $table2, $where_clause)

=item * ($table1, $table2, $fk, $where_clause)

If you want to specify a C<WHERE> clause as part of an inner join, include this
as the last argument when calling C<< $select->from() >>.

To create a standalone C<WHERE> clause suitable for passing to this
method, use the C<Fey::SQL::Where> class.

=item * ($table1, 'left', $table2)

If you want to do an outer join between two tables, pass the two
tables, separated by one of the following string:

=over 8

=item * left

=item * right

=item * full

=back

This will generate the appropriate outer join SQL in the C<FROM>
clause.

  FROM Part
       LEFT OUTER JOIN MachinePart
       ON Part.part_id = MachinePart.part_id

Just as with a normal join, the C<<$select->from() >> will attempt to
automatically find a foreign key between the two tables.

=item * ($table1, 'left', $table2, $fk)

Just as with a normal join, you can manually specify the foreign key
to use for an outer join as well.

=item * ($table1, 'left', $table2, $where_clause)

If you want to specify a C<WHERE> clause as part of an outer join,
include this as the fourth argument when calling C<< $select->from()
>>.

  FROM Part
       LEFT OUTER JOIN MachinePart
       ON Part.part_id = MachinePart.part_id
       AND MachinePart.machine_id = ?

To create a standalone C<WHERE> clause suitable for passing to this
method, use the C<Fey::SQL::Where> class.

=item * ($table1, 'left', $table2, $fk, $where_clause)

You can manually specify a foreign key I<and> include a where clause
in an outer join.

=back

The C<< $select->from() >> method can be called multiple times with
different join options. If you call the method with arguments that it
has already seen, then it will effectively ignore that call.

=head2 $select->where(...)

See the L<Fey::SQL section on WHERE Clauses|Fey::SQL/WHERE Clauses>
for more details.

=head2 $select->group_by(...)

This method accepts a list of elements. Each element can be a
C<Fey::Column> object, a column alias, or a literal function or term.

=head2 $select->having(...)

The C<< $select->having() >> method accepts exactly the same arguments
as the C<< $select->where() >> method.

=head2 $select->order_by(...)

See the L<Fey::SQL section on ORDER BY Clauses|Fey::SQL/ORDER BY
Clauses> for more details.

=head2 $select->limit(...)

See the L<Fey::SQL section on LIMIT Clauses|Fey::SQL/LIMIT Clauses>
for more details.

=head2 $select->sql($dbh)

Returns the full SQL statement which this object represents. A DBI
handle must be passed so that identifiers can be properly quoted.

=head2 $select->bind_params()

See the L<Fey::SQL section on Bind Parameters|Fey::SQL/Bind
Parameters> for more details.

=head2 $select->select_clause_elements

Returns a list of objects, one for each element in the C<SELECT>
clause. These can be C<Fey::Column>s, C<Fey::Column::Alias>es, or any
type of C<Fey::Literal>.

These items are returned in the order in which they will be included
in the C<SELECT> clause.

=head2 $select->select_clause()

Returns the C<SELECT> clause portion of the SQL statement as a string.

=head2 $select->from_clause()

Returns the C<FROM> clause portion of the SQL statement as a string.

=head2 $select->where_clause()

Returns the C<WHERE> clause portion of the SQL statement as a string.

=head2 $select->order_by_clause()

Returns the C<ORDER BY> clause portion of the SQL statement as a
string.

=head2 $select->group_by_clause()

Returns the C<GROUP BY> clause portion of the SQL statement as a
string.

=head2 $select->having_clause()

Returns the C<HAVING> clause portion of the SQL statement as a string.

=head2 $select->limit_clause()

Returns the C<LIMIT> clause portion of the SQL statement as a string.

=head2 $select->sql_or_alias()

=head2 $select->sql_with_alias()

Returns the appropriate SQL snippet.  See L<Fey::Role::HasAliasName>.

=head2 $select->id()

Returns a unique identifier for the select.

=head1 ROLES

=over 4

=item * L<Fey::Role::SQL::HasBindParams>

=item * L<Fey::Role::SQL::HasWhereClause>

=item * L<Fey::Role::SQL::HasOrderByClause>

=item * L<Fey::Role::SQL::HasLimitClause>

=item * L<Fey::Role::SQL::HasAliasName>

=item * L<Fey::Role::SQL::Comparable>

This role allows a C<Fey::SQL::Select> object to be used as a
subselect in C<WHERE> clauses.

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
