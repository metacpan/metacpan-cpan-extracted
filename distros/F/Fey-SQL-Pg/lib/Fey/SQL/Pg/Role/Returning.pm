package Fey::SQL::Pg::Role::Returning;
BEGIN {
  $Fey::SQL::Pg::Role::Returning::VERSION = '0.005';
}
# ABSTRACT: A role for SQL statements that have a RETURNING clause
use Moose::Role;
use namespace::autoclean;

use Method::Signatures::Simple;
use MooseX::Params::Validate qw( validated_hash pos_validated_list );

use Fey::Types qw( SelectElement );

has '_return' => (
    traits   => [ 'Array' ],
    is       => 'bare',
    isa      => 'ArrayRef',
    default  => sub { [] },
    handles  => {
        _add_returning_element    => 'push',
        returning_clause_elements => 'elements',
    },
    init_arg => undef,
);

method returning {
    my $count = @_ ? @_ : 1;
    my (@returning) = pos_validated_list(
        \@_,
        ( ( { isa => SelectElement } ) x $count ),
        MX_PARAMS_VALIDATE_NO_CACHE => 1,
    );

    for my $elt ( map { $_->can('columns')
                        ? sort { $a->name() cmp $b->name() } $_->columns()
                        : $_ }
                  map { blessed $_ ? $_ : Fey::Literal->new_from_scalar($_) }
                  @returning )
    {
        $self->_add_returning_element($elt);
    }

    return $self;
}

method returning_clause ($dbh)
{
    return unless $self->returning_clause_elements;

    my $sql = 'RETURNING ';
    $sql .=
        ( join ', ',
          map { $_->sql_with_alias($dbh) }
          $self->returning_clause_elements()
        );

    return $sql
}

1;



__END__
=pod

=encoding utf-8

=head1 NAME

Fey::SQL::Pg::Role::Returning - A role for SQL statements that have a RETURNING clause

=head1 METHODS

=head2 returning

Specify columns to return. See the documentation on C<select> in
L<Fey::SQL::Select> for the exact syntax, as this method takes
the same input

=head2 returning_clause

Returns the C<RETURNING> portion as an SQL string

=head1 DESCRPITION

Many statements in PostgreSQL allow you to specify a C<RETURNING>
clause. This role simply abstracts this part of generation.

=head1 AUTHOR

Oliver Charles <oliver.g.charles@googlemail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

