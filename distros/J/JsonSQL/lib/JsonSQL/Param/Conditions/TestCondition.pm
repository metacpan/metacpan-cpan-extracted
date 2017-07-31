# ABSTRACT: JsonSQL::Param::Conditions::TestCondition object. Subclass for parsing test conditions (ex: 'eq', 'gt', etc).



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Conditions::TestCondition;

our $VERSION = '0.4'; # VERSION

use base qw( JsonSQL::Param::Condition );

use SQL::QueryMaker qw( sql_eq sql_ne sql_gt sql_ge sql_lt sql_le );
#use Data::Dumper;

use JsonSQL::Param::Field;
use JsonSQL::Error;


## Define the SQL::QueryMaker methods used for building up SQL condition statements.
my %dispatch = (
    'eq' => \&sql_eq,
    'ne' => \&sql_ne,
    'gt' => \&sql_gt,
    'ge' => \&sql_ge,
    'lt' => \&sql_lt,
    'le' => \&sql_le
);



sub new {
    my ( $class, $conditionhashref, $queryObj, $default_table_rules ) = @_;
    
    my $self = $class->SUPER::new($conditionhashref);
    my @condition_errors;
    
    my $field = $conditionhashref->{$self->{_op}}->{field};
    my $conditionField = JsonSQL::Param::Field->new($field, $queryObj, $default_table_rules);
    if ( eval { $conditionField->is_error } ) {
        push(@condition_errors, "Error using field $field in test condition: $conditionField->{message}");
    } else {
        $self->{_field} = $conditionField;
    }
    
    my $value = $conditionhashref->{$self->{_op}}->{value};
    if ( ref ($value) eq 'HASH' ) {
        my $conditionValue = JsonSQL::Param::Field->new($value, $queryObj, $default_table_rules);
        if ( eval { $conditionValue->is_error } ) {
            push(@condition_errors, "Error using field $value in test condition: $conditionValue->{message}");
        } else {
            $self->{_value} = $conditionValue;
        }
    } else {
        $self->{_value} = $value;
    }

    if ( @condition_errors ) {
        my $err = "Error(s) constructing JsonSQL Condition object: \n\t";
        $err .= join("\n\t", @condition_errors);
        return JsonSQL::Error->new("jsonsql_testcondition", $err);
    } else {
        return $self;
    }
}


sub get_sql_obj {
    my ( $self, $queryObj ) = @_;
    
    if (exists $dispatch{$self->{_op}}) {
        my $field = $self->{_field}->get_field_param($queryObj);
        my $value;
        
        if (ref $self->{_value} eq 'JsonSQL::Param::Field') {
            $value = $self->{_value}->get_field_param($queryObj);
        } else {
            $value = $self->{_value};
        }
        
        return $dispatch{$self->{_op}}->($field => $value);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Conditions::TestCondition - JsonSQL::Param::Conditions::TestCondition object. Subclass for parsing test conditions (ex: 'eq', 'gt', etc).

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This module constructs a Perl object representing the VALUES parameter of an SQL INSERT statement and has methods for 
generating the appropriate SQL string and bind values for use with the L<DBI> module.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item _field => L<JsonSQL::Param::Field>

=item _value => <scalar> or L<JsonSQL::Param::Field>

=back

=head3 Generated parameters:

=over

=item $testparameter => L<SQL::QueryMaker> object.

=back

=head1 METHODS

=head2 Constructor new($conditionhashref, $queryObj, $default_table_rules)

Instantiates and returns a new JsonSQL::Param::Conditions::TestCondition object.

    $conditionhashref           => A hashref of the condition statement keyed by the operator.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.
    $default_table_rules        => The default whitelist table rules to use to validate access when the table params 
                                   are not provided to the field object. Usually, these are acquired from the table params
                                   of another object (ex: the FROM clause of a SELECT statement).

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_sql_obj -> $testparameter

Generates parameters represented by the object for the SQL statement. Returns:

    $testparameter            => The test condition to append to the WHERE clause. Constructed by calling the 
                                 L<SQL::QueryMaker> function defined by the dispatcher with the $field and $value
                                 parameters.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
