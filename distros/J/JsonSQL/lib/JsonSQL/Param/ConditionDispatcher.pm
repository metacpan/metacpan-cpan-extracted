# ABSTRACT: A dispatcher module that parses condition statements to create the appropriate JsonSQL Condition objects.


use strict;
use warnings;
use 5.014;

package JsonSQL::Param::ConditionDispatcher;

our $VERSION = '0.41'; # VERSION

use Class::Load qw( try_load_class );
use List::Util qw( any );

use JsonSQL::Error;


## Define the subclasses that support different condition operators.
my %opmap = (
    'TestCondition' => ['eq','ne','gt','ge','lt','le'],
    'RangeCondition' => ['bt','nb'],
    'EnumCondition' => ['in','ni'],
    'NullCondition' => ['isnull','notnull'],
    'LogicCondition' => ['and','or']
);



sub parse {
    my ( $caller, $conditionhashref, $queryObj, $default_table_rules ) = @_;
    
    ## The schema restricts to one condition operator per level of the hashref, so just grab the first key at this level to use as the operator.
    my ( $op ) = keys %{ $conditionhashref };
    
    ## Determine the appropriate JsonSQL Condition subclass for this operator.
    my $class = "JsonSQL::Param::Conditions::";
    for my $classObj ( keys %opmap ) {
        if ( any { $_ eq $op } @{ $opmap{$classObj} }) {
            $class .= $classObj;
        }
    }

    ## Load the class and return a new instance if successful. Otherwise return a JsonSQL::Error object.
    my ( $success, $err ) = try_load_class($class);
    if ( $success ) {
        return $class->new($conditionhashref, $queryObj, $default_table_rules);
    } else {
        return JsonSQL::Error->new("jsonsql_condition", $err);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::ConditionDispatcher - A dispatcher module that parses condition statements to create the appropriate JsonSQL Condition objects.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This is a supporting module used by L<JsonSQL::Query> modules for parsing condition operators as parameters for conditional
clauses.

To use this:

    my $condObj = JsonSQL::Param::ConditionDispatcher->parse($conditionhashref, $queryObj, $default_table_rules);
    if ( eval { $condObj->is_error } ) {
        return "Could not create condition object: $condObj->{message}";
    } else {
        ...
    }

The $conditionhashref must contain a single key which is the operator for the condition statement. The operator gets mapped to the
appropriate module to load as defined in the %opmap hash. The conditional modules are subclasses of JsonSQL::Param::Condition and
reside in JsonSQL::Param::Conditions. The value of the operator key is a hash of args to apply to the operator. For example, a TestCondition
needs to have "field" and "value" properties.

The collection of conditional modules is fairly complete, but others can be created if need be.

=head1 METHODS

=head2 Dispatcher parse($conditionhashref, $queryObj, $default_table_rules) -> JsonSQL::Param::Condition

Serves as a dispatcher to load the appropriate JsonSQL::Param::Conditions:: class, and create a new instance which is then returned.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
