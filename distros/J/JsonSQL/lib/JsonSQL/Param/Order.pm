# ABSTRACT: JsonSQL::Param::Order object. Stores a Perl representation of an SQL ORDER BY clause for use in JsonSQL::Query objects.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Order;

our $VERSION = '0.4'; # VERSION

use List::Util qw( any );

use JsonSQL::Param::Field;
use JsonSQL::Error;


## These are validated by the JSON schema, but an extra check doesn't hurt.
my @validDirs = ('ASC','DESC');
my @validNullPlacements = ('FIRST','LAST');



sub new {
    my ( $class, $orderhashref, $queryObj, $default_table_rules ) = @_;
    
    my $orderField = JsonSQL::Param::Field->new($orderhashref->{field}, $queryObj, $default_table_rules);
    if ( eval { $orderField->is_error } ) {
        return JsonSQL::Error->new("invalid_fields", "Error creating field $orderhashref->{field} for ORDER BY.");
    } else {
        my $self = {
            _field => $orderField
        };

        ## These are optional parameters. Store if they have been provided.
        my $orderDir = $orderhashref->{order};
        if ( any { $_ eq $orderDir } @validDirs ) {
            $self->{_orderDir} = $orderDir;
        }
        
        my $nullsPlacement = $orderhashref->{nulls} || '';
        if ( any { $_ eq $nullsPlacement } @validNullPlacements ) {
            $self->{_nullsPlacement} = $nullsPlacement;
        }
            
        ## Return the blessed reference.
        bless $self, $class;
        return $self;
    }
}


sub get_orderby {
    my ( $self, $queryObj ) = @_;

    my $orderByField = $self->{_field}->get_field_param($queryObj);

    ## Format the ordering modifiers, if any have been provided.
    my $orderByMod;
    if (defined $self->{_orderDir}) {
        $orderByMod = $self->{_orderDir};
        if (defined $self->{_nullsPlacement}) {
            $orderByMod .= ' ' . $self->{_nullsPlacement};
        }
    } elsif (defined $self->{_nullsPlacement}) {
        $orderByMod = $self->{_nullsPlacement};
    }

    ## If an ordering modifier has been specified, return a hash ref. If not, return a scalar ref.
    if (defined $orderByMod) {
      return [ $orderByField, $orderByMod ];
    } else {
      return $orderByField;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Order - JsonSQL::Param::Order object. Stores a Perl representation of an SQL ORDER BY clause for use in JsonSQL::Query objects.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This module constructs a Perl object representing the ORDER BY parameter of an SQL SELECT statement and has methods for 
extracting the parameters to generate the appropriate SQL string.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item _field => L<JsonSQL::Param::Field>

=item _orderDir => "ASC" or "DESC"

=item _nullsPlacement => "FIRST" or "LAST"

=back

=head3 Generated parameters:

=over

=item $orderByField => <string>

=item $orderByMod => <string>

=back

=head1 METHODS

=head2 Constructor new($orderhashref, $queryObj, $default_table_rules)

Instantiates and returns a new JsonSQL::Param::Order object.

    $orderhashref               => A hashref of field/sortorder/nullplacement properties used to construct the object.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.
    $default_table_rules        => The default whitelist table rules to use to validate access when the table params 
                                   are not provided to the field object. Usually, these are acquired from the table params
                                   of another object (ex: the FROM clause of a SELECT statement).

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_orderby -> ( $orderByField, $orderByMod )

Generates parameters represented by the object for the SQL statement. Returns:

    $orderByField           => The column to sort by.
    $orderByMod             => A string of sort modifiers to place after the column (ex: "ASC NULLS FIRST").

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
