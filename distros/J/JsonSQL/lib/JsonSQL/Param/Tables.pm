# ABSTRACT: JsonSQL::Param::Tables object. Stores an array of JsonSQL::Param::Table objects to use for constructing JsonSQL::Query objects.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Tables;

our $VERSION = '0.41'; # VERSION

use JsonSQL::Param::Table;
use JsonSQL::Error;



sub new {
    my ( $class, $tablesarrayref, $queryObj ) = @_;
    
    my $self = [];
    my @table_errors;
    
    for my $tablehashref ( @{ $tablesarrayref } ) {
        my $tableObj = JsonSQL::Param::Table->new($tablehashref, $queryObj);
        if ( eval { $tableObj->is_error } ) {
            push(@table_errors, "Error creating table $tablehashref->{table}: $tableObj->{message}");
        } else {
            push (@{ $self }, $tableObj);
        }
    }
    
    if ( @table_errors ) {
        my $err = "Could not parse all table objects: \n\t";
        $err .= join("\n\t", @table_errors);
        return JsonSQL::Error->new("invalid_tables", $err);
    } else {
        bless $self, $class;
        return $self;
    }
}


sub get_tables {
    my ( $self, $queryObj ) = @_;
    
    my @tablesArray = map { $_->get_table_param($queryObj) } @{ $self };
    
    return \@tablesArray;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Tables - JsonSQL::Param::Tables object. Stores an array of JsonSQL::Param::Table objects to use for constructing JsonSQL::Query objects.

=head1 VERSION

version 0.41

=head1 SYNOPSIS

This module constructs a Perl object container of L<JsonSQL::Param::Table> objects.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item Array of L<JsonSQL::Param::Table> objects.

=back

=head3 Generated parameters:

=over

=item $tablesArray => \@arrayref

=back

=head1 METHODS

=head2 Constructor new($tablesarrayref, $queryObj)

Instantiates and returns a new JsonSQL::Param::Tables object, which is an array of L<JsonSQL::Param::Table> objects.

    $tablesarrayref             => An arrayref of table hashes used to construct the object.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_tables -> \@tablesArray

Generates parameters represented by the object for the SQL statement. Returns:

    $tablesArray           => Arrayref of table identifiers to use for the query. Constructed from child L<JsonSQL::Param::Table> objects.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
