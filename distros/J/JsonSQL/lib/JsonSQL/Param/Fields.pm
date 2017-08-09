# ABSTRACT: JsonSQL::Param::Fields object. Stores an array of JsonSQL::Param::Field objects to use for constructing JsonSQL::Query objects.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Fields;

our $VERSION = '0.41'; # VERSION

use JsonSQL::Param::Field;
use JsonSQL::Error;



sub new {
    my ( $class, $fieldsarrayref, $queryObj, $default_table_rules ) = @_;
    
    my $self = [];
    my @field_errors;
    
    for my $fieldhashref ( @{ $fieldsarrayref } ) {
        my $fieldObj = JsonSQL::Param::Field->new($fieldhashref, $queryObj, $default_table_rules);
        if ( eval { $fieldObj->is_error } ) {
            push(@field_errors, "Error creating field $fieldhashref->{column}: $fieldObj->{message}");
        } else {
            push (@{ $self }, $fieldObj);
        }
    }
    
    if ( @field_errors ) {
        my $err = "Could not parse all field objects: \n\t";
        $err .= join("\n\t", @field_errors);
        return JsonSQL::Error->new("invalid_fields", $err);
    } else {
        bless $self, $class;
        return $self;
    }
}


sub get_fields {
    my ( $self, $queryObj ) = @_;
    
    my @fieldsArray = map { $_->get_field_param($queryObj) } @{ $self };
    
    return \@fieldsArray;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Fields - JsonSQL::Param::Fields object. Stores an array of JsonSQL::Param::Field objects to use for constructing JsonSQL::Query objects.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This module constructs a Perl object container of L<JsonSQL::Param::Field> objects.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item Array of L<JsonSQL::Param::Field> objects.

=back

=head3 Generated parameters:

=over

=item $fieldsArray => \@arrayref

=back

=head1 METHODS

=head2 Constructor new($fieldsarrayref, $queryObj, $default_table_rules)

Instantiates and returns a new JsonSQL::Param::Fields object, which is an array of L<JsonSQL::Param::Field> objects.

    $fieldsarrayref             => An arrayref of field hashes used to construct the object.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.
    $default_table_rules        => The default whitelist table rules to use to validate access when the table params 
                                   are not provided to the field object. Usually, these are acquired from the table params
                                   of another object (ex: the FROM clause of a SELECT statement).

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_fields -> \@fieldsArray

Generates parameters represented by the object for the SQL statement. Returns:

    $fieldsArray           => Arrayref of field identifiers to use for the query. Constructed from child L<JsonSQL::Param::Field> objects.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
