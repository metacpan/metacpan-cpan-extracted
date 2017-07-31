# ABSTRACT: JsonSQL::Param::Conditions::RangeCondition object. Subclass for parsing range conditions.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Conditions::RangeCondition;

our $VERSION = '0.4'; # VERSION

use base qw( JsonSQL::Param::Condition );

use SQL::QueryMaker qw( sql_between sql_not_between );
#use Data::Dumper;

use JsonSQL::Param::Field;
use JsonSQL::Error;


## Define the SQL::QueryMaker methods used for building up SQL condition statements.
my %dispatch = (
    'bt' => \&sql_between,
    'nb' => \&sql_not_between
);



sub new {
    my ( $class, $conditionhashref, $queryObj, $default_table_rules ) = @_;
    
    my $self = $class->SUPER::new($conditionhashref);
    my @condition_errors;
    
    my $field = $conditionhashref->{$self->{_op}}->{field};
    my $conditionField = JsonSQL::Param::Field->new($field, $queryObj, $default_table_rules);
    if ( eval { $conditionField->is_error } ) {
        push(@condition_errors, "Error using field $field in range condition: $conditionField->{message}");
    } else {
        $self->{_field} = $conditionField;
    }
    
    my $minvalue = $conditionhashref->{$self->{_op}}->{minvalue};
    if ( ref ($minvalue) eq 'HASH' ) {
        my $conditionMin = JsonSQL::Param::Field->new($minvalue, $queryObj, $default_table_rules);
        if ( eval { $conditionMin->is_error } ) {
            push(@condition_errors, "Error using field $field in range condition as min value: $conditionMin->{message}");
        } else {
            $self->{_minvalue} = $conditionMin;
        }
    } else {
        $self->{_minvalue} = $minvalue;
    }

    my $maxvalue = $conditionhashref->{$self->{_op}}->{maxvalue};
    if ( ref ($maxvalue) eq 'HASH' ) {
        my $conditionMax = JsonSQL::Param::Field->new($maxvalue, $queryObj, $default_table_rules);
        if ( eval { $conditionMax->is_error } ) {
            push(@condition_errors, "Error using field $field in range condition as max value: $conditionMax->{message}");
        } else {
            $self->{_maxvalue} = $conditionMax;
        }
    } else {
        $self->{_maxvalue} = $maxvalue;
    }
    
    if ( @condition_errors ) {
        my $err = "Error(s) constructing JsonSQL Condition object: \n\t";
        $err .= join("\n\t", @condition_errors);
        return JsonSQL::Error->new("jsonsql_rangecondition", $err);
    } else {
        return $self;
    }
}


sub get_sql_obj {
    my ( $self, $queryObj ) = @_;
    
    if (exists $dispatch{$self->{_op}}) {
        my $field = $self->{_field}->get_field_param($queryObj);

        my $minvalue; 
        if (ref $self->{_minvalue} eq 'JsonSQL::Param::Field') {
                $minvalue = $self->{_minvalue}->get_field_param($queryObj);
        } else {
                $minvalue = $self->{_minvalue};
        }

        my $maxvalue; 
        if (ref $self->{_maxvalue} eq 'JsonSQL::Param::Field') {
                $maxvalue = $self->{_maxvalue}->get_field_param($queryObj);
        } else {
                $maxvalue = $self->{_maxvalue};
        }

        return $dispatch{$self->{_op}}->($field, $minvalue, $maxvalue);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Conditions::RangeCondition - JsonSQL::Param::Conditions::RangeCondition object. Subclass for parsing range conditions.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This module constructs a Perl object representing the VALUES parameter of an SQL INSERT statement and has methods for 
generating the appropriate SQL string and bind values for use with the L<DBI> module.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item _field => L<JsonSQL::Param::Field>

=item _minvalue => <scalar> or L<JsonSQL::Param::Field>

=item _maxvalue => <scalar> or L<JsonSQL::Param::Field>

=back

=head3 Generated parameters:

=over

=item $rangeparameter => L<SQL::QueryMaker> object.

=back

=head1 METHODS

=head2 Constructor new($conditionhashref, $queryObj, $default_table_rules)

Instantiates and returns a new JsonSQL::Param::Conditions::RangeCondition object.

    $conditionhashref           => A hashref of the condition statement keyed by the operator.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.
    $default_table_rules        => The default whitelist table rules to use to validate access when the table params 
                                   are not provided to the field object. Usually, these are acquired from the table params
                                   of another object (ex: the FROM clause of a SELECT statement).

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_sql_obj -> $rangeparameter

Generates parameters represented by the object for the SQL statement. Returns:

    $rangeparameter           => The range condition to append to the WHERE clause. Constructed by calling the 
                                 L<SQL::QueryMaker> function defined by the dispatcher with the $field, $minvalue, and $maxvalue
                                 parameters.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
