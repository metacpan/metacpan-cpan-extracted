# ABSTRACT: JsonSQL::Param::Conditions::NullCondition object. Subclass for parsing null conditions.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Conditions::NullCondition;

our $VERSION = '0.4'; # VERSION

use base qw( JsonSQL::Param::Condition );

use SQL::QueryMaker qw( sql_is_null sql_is_not_null );
#use Data::Dumper;

use JsonSQL::Param::Field;
use JsonSQL::Error;


## Define the SQL::QueryMaker methods used for building up SQL condition statements.
my %dispatch = (
    'isnull' => \&sql_is_null,
    'notnull' => \&sql_is_not_null
);



sub new {
    my ( $class, $conditionhashref, $queryObj, $default_table_rules ) = @_;
    
    my $self = $class->SUPER::new($conditionhashref);
    
    my $field = $conditionhashref->{$self->{_op}}->{field};
    my $conditionField = JsonSQL::Param::Field->new($field, $queryObj, $default_table_rules);
    if ( eval { $conditionField->is_error } ) {
        return JsonSQL::Error->new("jsonsql_nullcondition", "Error using field $field in null condition: $conditionField->{message}");
    } else {
        $self->{_field} = $conditionField;
        return $self;
    }
}


sub get_sql_obj {
    my ( $self, $queryObj ) = @_;
    
    if (exists $dispatch{$self->{_op}}) {
        my $field = $self->{_field}->get_field_param($queryObj);
        return $dispatch{$self->{_op}}->($field);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Conditions::NullCondition - JsonSQL::Param::Conditions::NullCondition object. Subclass for parsing null conditions.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This module constructs a Perl object representing the VALUES parameter of an SQL INSERT statement and has methods for 
generating the appropriate SQL string and bind values for use with the L<DBI> module.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item _field => L<JsonSQL::Param::Field>

=back

=head3 Generated parameters:

=over

=item $nullparameter => L<SQL::QueryMaker> object.

=back

=head1 METHODS

=head2 Constructor new($conditionhashref, $queryObj, $default_table_rules)

Instantiates and returns a new JsonSQL::Param::Conditions::NullCondition object.

    $conditionhashref           => A hashref of the condition statement keyed by the operator.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.
    $default_table_rules        => The default whitelist table rules to use to validate access when the table params 
                                   are not provided to the field object. Usually, these are acquired from the table params
                                   of another object (ex: the FROM clause of a SELECT statement).

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_sql_obj -> $nullparameter

Generates parameters represented by the object for the SQL statement. Returns:

    $nullparameter            => The null condition to append to the WHERE clause. Constructed by calling the 
                                 L<SQL::QueryMaker> function defined by the dispatcher with the $field parameter.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
