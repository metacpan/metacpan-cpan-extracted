# ABSTRACT: JsonSQL::Param::OrderBy object. Stores an array of JsonSQL::Param::Order objects to use for constructing JsonSQL::Query objects.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::OrderBy;

our $VERSION = '0.4'; # VERSION

use JsonSQL::Param::Order;
use JsonSQL::Error;

#use Data::Dumper;



sub new {
    my ( $class, $orderarrayref, $queryObj, $default_table_rules ) = @_;
    
    my $self = [];
    my @orderby_errors;
    
    for my $orderhashref ( @{ $orderarrayref } ) {
        my $orderByObj = JsonSQL::Param::Order->new($orderhashref, $queryObj, $default_table_rules);
        if ( eval { $orderByObj->is_error } ) {
            push(@orderby_errors, $orderByObj->{message});
        } else {
            push (@{ $self }, $orderByObj);
        }
    }
    
    if ( @orderby_errors ) {
        my $err = "Could not parse all order objects: \n\t";
        $err .= join("\n\t", @orderby_errors);
        return JsonSQL::Error->new("invalid_orderby", $err);
    } else {
        bless $self, $class;
        return $self;
    }
}


sub get_ordering {
    my ( $self, $queryObj ) = @_;
    
    my @orderingArray = map { $_->get_orderby } @{ $self };
    
    return \@orderingArray;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::OrderBy - JsonSQL::Param::OrderBy object. Stores an array of JsonSQL::Param::Order objects to use for constructing JsonSQL::Query objects.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This module constructs a Perl object container of L<JsonSQL::Param::Order> objects.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item Array of L<JsonSQL::Param::Order> objects.

=back

=head3 Generated parameters:

=over

=item $orderingArray => \@arrayref

=back

=head1 METHODS

=head2 Constructor new($orderarrayref, $queryObj, $default_table_rules)

Instantiates and returns a new JsonSQL::Param::OrderBy object, which is an array of L<JsonSQL::Param::Order> objects.

    $orderarrayref              => An arrayref of order hashes used to construct the object.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.
    $default_table_rules        => The default whitelist table rules to use to validate access when the table params 
                                   are not provided to the field object. Usually, these are acquired from the table params
                                   of another object (ex: the FROM clause of a SELECT statement).

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_ordering -> \@orderingArray

Generates parameters represented by the object for the SQL statement. Returns:

    $orderingArray           => Arrayref of ordering parameters to use for the query. Constructed from child L<JsonSQL::Param::Order> objects.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
