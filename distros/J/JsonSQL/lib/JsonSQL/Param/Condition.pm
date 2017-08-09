# ABSTRACT: JsonSQL::Param::Condition object. This is a base class used to derive subclasses for parsing condition statements.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Condition;

our $VERSION = '0.41'; # VERSION

use JsonSQL::Error;



sub new {
    my ( $class, $conditionhashref ) = @_;
    
    ## The schema restricts to one condition operator per level of the hashref, so just grab the first key at this level to use as the operator.
    my ( $op ) = keys %{ $conditionhashref };
    my $self = {
        _op => $op
    };
    
    bless $self, $class;
    return $self;
}


sub get_cond {
    my ( $self, $queryObj ) = @_;
    
    my $condObj = $self->get_sql_obj($queryObj);
    my $sql = $condObj->as_sql;
    my @binds = $condObj->bind;

    ## SMELL: Another QueryMaker workaround. Doesn't quote right.
    $sql =~ s/`//g;
    
    return ($sql, \@binds);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Condition - JsonSQL::Param::Condition object. This is a base class used to derive subclasses for parsing condition statements.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This module constructs a Perl object representing the VALUES parameter of an SQL INSERT statement and has methods for 
generating the appropriate SQL string and bind values for use with the L<DBI> module.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item _op => The operator used to construct the condition

(ex: 'and', 'eq', or 'in').

=back

=head3 Generated parameters:

=over

=item $sql => SQL string of the condition

=item $binds => Arrayref of bind values to use with the query.

=back

=head1 METHODS

=head2 Constructor new($conditionhashref)

Instantiates and returns a new JsonSQL::Param::Condition object.

    $conditionhashref           => A hashref of the condition statement keyed by the operator.

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_cond -> ( $sql, $binds )

Generates the SQL statement represented by the object. Returns:

    $sql            => An SQL string of conditional parameters to use with a conditional clause (ex: WHERE or ON).
    $binds          => An arrayref of parameterized values to pass with the query.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
