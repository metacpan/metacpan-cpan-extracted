package Fey::SQL::Fragment::Join;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Fey::Exceptions qw( param_error );
use Fey::FakeDBI;
use Fey::Types qw( FK OuterJoinType Table WhereClause );
use List::AllUtils qw( pairwise );

use Moose 2.1200;

has '_table1' => (
    is       => 'ro',
    does     => 'Fey::Role::TableLike',
    required => 1,
    init_arg => 'table1',
);

has '_table2' => (
    is        => 'ro',
    does      => 'Fey::Role::TableLike',
    predicate => '_has_table2',
    init_arg  => 'table2',
);

has '_fk' => (
    is        => 'ro',
    isa       => FK,
    init_arg  => 'fk',
    predicate => '_has_fk',
);

has '_outer_type' => (
    is        => 'ro',
    isa       => OuterJoinType,
    predicate => '_has_outer_type',
    init_arg  => 'outer_type',
);

has '_where' => (
    is        => 'ro',
    isa       => WhereClause,
    predicate => '_has_where',
    init_arg  => 'where',
);

sub BUILD {
    my $self = shift;

    param_error 'You cannot join two tables without a foreign key'
        if $self->_has_table2() && !$self->_has_fk();

    return;
}

sub id {
    my $self = shift;

    # This is a rather special case, and handling it separately makes
    # the rest of this method simpler.
    return $self->_table1()->id()
        unless $self->_has_table2();

    my @tables = $self->tables();
    @tables = sort { $a->name() cmp $b->name() } @tables
        unless $self->_is_left_or_right_outer_join();

    my @outer;
    @outer = $self->_outer_type() if $self->_has_outer_type();

    my @where;
    @where = $self->_where()->where_clause( 'Fey::FakeDBI', 'no WHERE' )
        if $self->_has_where();

    return (
        join "\0",
        @outer,
        ( map { $_->id() } @tables ),
        $self->_fk()->id(),
        @where,
    );
}

sub _is_left_or_right_outer_join {
    my $self = shift;

    return $self->_has_outer_type()
        && $self->_outer_type() =~ /^(?:right|left)$/;
}

sub tables {
    my $self = shift;

    return grep {defined} ( $self->_table1(), $self->_table2() );
}

sub sql_with_alias {
    my $self       = shift;
    my $dbh        = shift;
    my $joined_ids = shift;

    my @unseen_tables
        = grep { !$joined_ids->{ $_->id() } } $self->tables();

    # This can happen in the case where we have just one table, and
    # that table is participating in some other join.
    return '' unless @unseen_tables;

    return $self->_table1()->sql_with_alias($dbh)
        unless $self->_has_table2();

    if ( @unseen_tables == 1 ) {
        return $self->_join_one_table( $dbh, @unseen_tables );
    }
    else {
        return $self->_join_both_tables($dbh);
    }
}

# This could produce gibberish for an OUTER JOIN, but that would mean
# that the query is fundamentally wrong anyway (since you can't OUTER
# JOIN a table you've already joined with a normal join previously).
sub _join_one_table {
    my $self         = shift;
    my $dbh          = shift;
    my $unseen_table = shift;

    my $join = '';

    $join .= uc $self->_outer_type() . ' OUTER'
        if $self->_has_outer_type();

    $join .= q{ } if length $join;
    $join .= 'JOIN ';
    $join .= $unseen_table->sql_with_alias($dbh);

    $join .= $self->_on_clause($dbh);
    $join .= $self->_where_clause($dbh);
    $join .= ')';

    return $join;
}

sub _join_both_tables {
    my $self = shift;
    my $dbh  = shift;

    my $join = $self->_table1()->sql_with_alias($dbh);

    $join .= q{ } . uc $self->_outer_type() . ' OUTER'
        if $self->_has_outer_type();

    $join .= ' JOIN ';
    $join .= $self->_table2()->sql_with_alias($dbh);

    $join .= $self->_on_clause($dbh);
    $join .= $self->_where_clause($dbh);
    $join .= ')';

    return $join;
}

sub _on_clause {
    my $self = shift;
    my $dbh  = shift;

    my $on .= ' ON (';

    my @s = @{ $self->_fk()->source_columns() };
    my @t = @{ $self->_fk()->target_columns() };

    for my $p ( pairwise { [ $a, $b ] } @s, @t ) {
        $on .= $p->[0]->sql_or_alias($dbh);
        $on .= ' = ';
        $on .= $p->[1]->sql_or_alias($dbh);
    }

    return $on;
}

sub _where_clause {
    my $self = shift;
    my $dbh  = shift;

    return '' unless $self->_has_where();

    return ' AND ' . $self->_where()->where_clause( $dbh, 'no WHERE' );
}

sub bind_params {
    my $self = shift;

    return unless $self->_has_where();

    return $self->_where()->bind_params();
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a single join in a FROM clause

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::SQL::Fragment::Join - Represents a single join in a FROM clause

=head1 VERSION

version 0.44

=head1 DESCRIPTION

This class represents part of a C<FROM> clause, usually a join, but it
can also represent a single table or subselect.

It is intended solely for internal use in L<Fey::SQL> objects, and as
such is not intended for public use.

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
