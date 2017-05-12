package Fey::Role::SQL::HasOrderByClause;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Fey::Types qw( ArrayRef OrderByElement );
use Scalar::Util qw( blessed );

use Moose::Role;
use MooseX::Params::Validate 0.21 qw( pos_validated_list );

has '_order_by' => (
    traits  => ['Array'],
    is      => 'bare',
    isa     => ArrayRef,
    default => sub { [] },
    handles => {
        _add_order_by_elements => 'push',
        _has_order_by_elements => 'count',
        _order_by              => 'elements',
    },
    init_arg => undef,
);

sub order_by {
    my $self = shift;

    my $count = @_ ? @_ : 1;
    my (@by) = pos_validated_list(
        \@_,
        ( ( { isa => OrderByElement } ) x $count ),
        MX_PARAMS_VALIDATE_NO_CACHE => 1,
    );

    $self->_add_order_by_elements(@by);

    return $self;
}

sub order_by_clause {
    my $self = shift;
    my $dbh  = shift;

    return unless $self->_has_order_by_elements();

    my $sql = 'ORDER BY ';

    my @elt = $self->_order_by();

    for my $elt (@elt) {
        if ( !blessed $elt ) {
            $sql .= q{ } . uc $elt;
        }
        else {
            $sql .= ', ' if $elt != $elt[0];
            $sql .= $elt->sql_or_alias($dbh);
        }
    }

    return $sql;
}

1;

# ABSTRACT: A role for queries which can include a ORDER BY clause

__END__

=pod

=head1 NAME

Fey::Role::SQL::HasOrderByClause - A role for queries which can include a ORDER BY clause

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::SQL::HasOrderByClause';

=head1 DESCRIPTION

Classes which do this role represent a query which can include a
C<ORDER BY> clause.

=head1 METHODS

This role provides the following methods:

=head2 $query->order_by()

See the L<Fey::SQL section on ORDER BY Clauses|Fey::SQL/ORDER BY
Clauses> for more details.

=head2 $query->order_by_clause()

Returns the C<ORDER BY> clause portion of the SQL statement as a
string.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
