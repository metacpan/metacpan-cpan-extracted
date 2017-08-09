# ABSTRACT: JsonSQL::Param::Join object. Stores a Perl representation of an SQL join expression for use in JsonSQL::Query objects.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Join;

our $VERSION = '0.41'; # VERSION

use JsonSQL::Param::Table;
use JsonSQL::Error;



sub new {
    my ( $class, $joinhashref, $queryObj ) = @_;
    
    my $self = {};
    my @join_errors;
    
    # The join FROM table is just a JsonSQL::Param::Table, so we can inherit the error handling.
    my $joinFrom = JsonSQL::Param::Table->new($joinhashref->{from}, $queryObj);
    if ( eval { $joinFrom->is_error } ) {
        push(@join_errors, "Error creating join FROM table $joinhashref->{from}->{table}: $joinFrom->{message}");
    } else {
        $self->{_joinFrom} = $joinFrom;
    }
    
    # Same with the join TO table.
    my $joinTo = JsonSQL::Param::Table->new($joinhashref->{to}, $queryObj);
    if ( eval { $joinTo->is_error } ) {
        push(@join_errors, "Error creating join TO table $joinhashref->{to}->{table}: $joinTo->{message}");
    } else {
        $self->{_joinTo} = $joinTo;
    }

    ## SMELL: more fixes to work around QueryMaker bugs
    for ( $joinhashref->{jointype} ) {
        when("outerleft") { $self->{_joinType} = "LEFT"; }
        when("outerright") { $self->{_joinType} = "RIGHT"; }
        when("outerfull") { $self->{_joinType} = "FULL"; }
        when("inner") { $self->{_joinType} = "INNER"; }
        when("cross") { $self->{_joinType} = "CROSS"; }
    }
    
    if (defined $joinhashref->{on}) {
        my $joinOn = JsonSQL::Param::ConditionDispatcher->parse($joinhashref->{on}, $queryObj);
        if ( eval { $joinOn->is_error } ) {
            push(@join_errors, "Error creating join ON condition: $joinOn->{message}");
        } else {
            $self->{_joinCondition} = $joinOn;
        }
    }
    
    if ( @join_errors ) {
        my $err = "Error(s) constructing JOIN object: \n\t";
        $err .= join("\n\t", @join_errors);
        return JsonSQL::Error->new("invalid_joins", $err);
    } else {
        bless $self, $class;
        return $self;
    }
}


sub get_join {
    my ( $self, $queryObj ) = @_;

    my $joinFrom = $self->{_joinFrom}->get_table_param($queryObj);
    my $joinParams = {
        type => $self->{_joinType},
        table => $self->{_joinTo}->get_table_param($queryObj)
    };
    
    if (defined $self->{_joinCondition}) {
        ## SMELL: SQL::Maker doesn't support SQL::QueryMaker objects for JOIN ON
        ## So, we build up the expression manually
        ## Note: the JOIN condition is not parameterized, but this should be ok because the schema forces it to be based on 
        ##  field identifiers, which are always quoted. It would be nice to do this in a cleaner way, but first have to 
        ##  remove SQL::Maker dependency.
        my ($sql, $bind) = $self->{_joinCondition}->get_cond($queryObj);
        my $condition = $sql =~ s/\?/$bind->[0]/r;
        $condition =~ s/`//g;
        $joinParams->{condition} = $condition;
    }
    
    ## Return join as a hash ref.
    return { $joinFrom => $joinParams };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Join - JsonSQL::Param::Join object. Stores a Perl representation of an SQL join expression for use in JsonSQL::Query objects.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This module constructs a Perl object representing a JOIN parameter of an SQL SELECT statement and has methods for 
extracting the parameters to generate the appropriate SQL string.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item _joinFrom => L<JsonSQL::Param::Table>

=item _joinTo => L<JsonSQL::Param::Table>

=item _joinType => "inner" || "outerleft" || "outerright" || "outerfull" || "cross"

=item _joinCondition => L<JsonSQL::Param::Condition>

=back

=head3 Generated parameters:

=over

=item { $joinFrom => $joinParams }

=back

=head1 METHODS

=head2 Constructor new($joinhashref, $queryObj)

Instantiates and returns a new JsonSQL::Param::Join object.

    $joinhashref                => A hashref of fromtable/totable/jointype/joincondition properties used to construct the object.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_join -> { $joinFrom => $joinParams }

Generates parameters represented by the object for the SQL statement. Returns:

    $joinFrom           => The table to JOIN from.
    $joinParams         => The parameters defining the join.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
