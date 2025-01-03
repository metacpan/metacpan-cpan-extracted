package Fey::Role::SetOperation;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Fey::Types qw( ArrayRef Bool SetOperationArg Str );

use MooseX::Role::Parameterized 1.00;
use MooseX::Params::Validate 0.21 qw( pos_validated_list );

parameter keyword => (
    isa      => Str,
    required => 1,
);

with 'Fey::Role::Comparable',
    'Fey::Role::SQL::HasOrderByClause',
    'Fey::Role::SQL::HasLimitClause',
    'Fey::Role::SQL::ReturnsData';

has 'is_all' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
    writer  => '_set_is_all',
);

has '_set_elements' => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => ArrayRef [SetOperationArg],
    default => sub { [] },
    handles => {
        _add_set_elements  => 'push',
        _set_element_count => 'count',
        _set_elements      => 'elements',
    },
    init_arg => undef,
);

sub id {
    return $_[0]->sql('Fey::FakeDBI');
}

sub all {
    $_[0]->_set_is_all(1);
    return $_[0];
}

sub bind_params {
    my $self = shift;
    return map { $_->bind_params } $self->_set_elements();
}

sub select_clause_elements {
    return ( $_[0]->_set_elements() )[0]->select_clause_elements();
}

role {
    my $p     = shift;
    my %extra = @_;

    my $name = lc $p->keyword();

    method 'keyword_clause' => sub {
        my $self = shift;

        my $sql = uc($name);
        $sql .= ' ALL' if $self->is_all();
        return $sql;
    };

    my $clause_method = $name . '_clause';

    method 'sql' => sub {
        my $self = shift;
        my $dbh  = shift;

        return (
            join q{ },
            $self->$clause_method($dbh),
            $self->order_by_clause($dbh),
            $self->limit_clause($dbh),
        );
    };

    method $name => sub {
        my $self = shift;

        my $count = @_;
        $count = 2
            if $count < 2 && $self->_set_element_count() < 2;

        my (@set) = pos_validated_list(
            \@_,
            ( ( { isa => SetOperationArg } ) x $count ),
            MX_PARAMS_VALIDATE_NO_CACHE => 1,
        );

        $self->_add_set_elements(@set);

        return $self;
    };

    method $clause_method => sub {
        my $self = shift;
        my $dbh  = shift;

        return (
            join q{ } . $self->keyword_clause($dbh) . q{ },
            map { '(' . $_->sql($dbh) . ')' } $self->_set_elements()
        );
    };

    with 'Fey::Role::HasAliasName' => {
        generated_alias_prefix => uc $name,
        sql_needs_parens       => 1,
    };
};

1;

# ABSTRACT: A role for things that are a set operation

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::Role::SetOperation - A role for things that are a set operation

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::SetOperation' => { keyword => $keyword };

=head1 DESCRIPTION

Classes which do this role represent a query which can include
multiple C<SELECT> queries or set operations.

=head1 PARAMETERS

=head2 keyword

The SQL keyword for this set operation (i.e. C<UNION>, C<INTERSECT>,
C<EXCEPT>).

=head1 METHODS

This role provides the following methods, where C<$keyword> is the
C<keyword> parameter, above:

=head2 $query->$keyword()

  $union->union($select1, $select2, $select3);

  $union->union($select, $except->except($select2, $select3));

Adds C<SELECT> queries or set operations to the list of queries that this set operation
includes.

A set operation must include at least two queries, so the first time
this is called, at least two arguments must be provided; subsequent
calls do not suffer this constraint.

=head2 $query->all()

Sets whether or not C<ALL> is included in the SQL for this set
operation (e.g.  C<UNION ALL>).

=head2 $query->is_all()

Returns true if C<< $query->all() >> has previously been called.

=head2 $query->keyword_clause()

Returns the SQL keyword and possible C<ALL> for this set operation.

=head2 $query->${keyword}_clause()

  print $query->union_clause();

Returns each of the selects for this set operation, joined by the
C<keyword_clause>.

=head1 ROLES

This class includes C<Fey::Role::SQL::HasOrderByClause>,
C<Fey::Role::SQL::HasLimitClause>, and C<Fey::Role::SQL::HasAliasName>.

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
