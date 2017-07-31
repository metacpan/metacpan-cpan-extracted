# ABSTRACT: JsonSQL::Param::Joins object. Stores an array of JsonSQL::Param::Join objects to use for constructing JsonSQL::Query objects.



use strict;
use warnings;
use 5.014;

package JsonSQL::Param::Joins;

our $VERSION = '0.4'; # VERSION

use JsonSQL::Param::Join;
use JsonSQL::Error;



sub new {
    my ($class, $joinsarrayref, $queryObj) = @_;
    
    my $self = [];
    
    my @join_errors;
    for my $joinhashref ( @{ $joinsarrayref } ) {
        my $joinObj = JsonSQL::Param::Join->new($joinhashref, $queryObj);
        if ( eval { $joinObj->is_error } ) {
            push(@join_errors, $joinObj->{message});
        } else {
            push (@{ $self }, $joinObj);
        }
    }
    
    if ( @join_errors ) {
        my $err = "Could not parse all join objects: \n\t";
        $err .= join("\n\t", @join_errors);
        return JsonSQL::Error->new("invalid_joins", $err);
    } else {
        bless $self, $class;
        return $self;
    }
}


sub get_joins {
    my ( $self, $queryObj ) = @_;
    
    my @joinsArray = map { $_->get_join($queryObj) } @{ $self };
    
    return \@joinsArray;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Param::Joins - JsonSQL::Param::Joins object. Stores an array of JsonSQL::Param::Join objects to use for constructing JsonSQL::Query objects.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This module constructs a Perl object container of L<JsonSQL::Param::Join> objects.

=head1 DESCRIPTION

=head3 Object properties:

=over

=item Array of L<JsonSQL::Param::Join> objects.

=back

=head3 Generated parameters:

=over

=item $joinsArray => \@arrayref

=back

=head1 METHODS

=head2 Constructor new($joinsarrayref, $queryObj)

Instantiates and returns a new JsonSQL::Param::Joins object, which is an array of L<JsonSQL::Param::Join> objects.

    $joinsarrayref              => An arrayref of join hashes used to construct the object.
    $queryObj                   => A reference to the JsonSQL::Query object that will own this object.

Returns a JsonSQL::Error object on failure.

=head2 ObjectMethod get_joins -> \@joinsArray

Generates parameters represented by the object for the SQL statement. Returns:

    $joinsArray           => Arrayref of joins to use for the query. Constructed from child L<JsonSQL::Param::Join> objects.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
