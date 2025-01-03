package Fey::Role::SQL::HasLimitClause;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Scalar::Util qw( blessed );

use Fey::Types qw( PosInteger PosOrZeroInteger Undef );

use Moose::Role;
use MooseX::Params::Validate 0.21 qw( pos_validated_list );

has '_limit' => (
    is        => 'rw',
    writer    => '_set_limit',
    predicate => '_has_limit',
);

has '_offset' => (
    is        => 'rw',
    writer    => '_set_offset',
    predicate => '_has_offset',
);

sub limit {
    my $self = shift;
    my ( $limit, $offset ) = pos_validated_list(
        \@_,
        { isa => ( PosInteger | Undef ) },
        {
            isa      => PosOrZeroInteger,
            optional => 1,
        },
    );

    $self->_set_limit($limit)
        if defined $limit;
    $self->_set_offset($offset)
        if defined $offset;

    return $self;
}

sub limit_clause {
    my $self = shift;

    return unless $self->_has_limit() || $self->_has_offset();

    my $sql = '';

    $sql .= 'LIMIT ' . $self->_limit()
        if $self->_has_limit();
    $sql .= q{ }
        if $self->_has_limit() && $self->_has_offset();
    $sql .= 'OFFSET ' . $self->_offset()
        if $self->_has_offset();

    return $sql;
}

1;

# ABSTRACT: A role for queries which can include a LIMIT clause

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::Role::SQL::HasLimitClause - A role for queries which can include a LIMIT clause

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::SQL::HasLimitClause';

=head1 DESCRIPTION

Classes which do this role represent a query which can include a
C<LIMIT> clause.

=head1 METHODS

This role provides the following methods:

=head2 $query->limit()

See the L<Fey::SQL section on LIMIT Clauses|Fey::SQL/LIMIT Clauses>
for more details.

=head2 $query->limit_clause()

Returns the C<LIMIT> clause portion of the SQL statement as a string.

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
