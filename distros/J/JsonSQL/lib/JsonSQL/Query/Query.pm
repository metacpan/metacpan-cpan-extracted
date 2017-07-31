# ABSTRACT: JSON query base class. Provides the quote_identifier method for escaping table and column identifiers.


use strict;
use warnings;
use 5.014;

package JsonSQL::Query::Query;

our $VERSION = '0.4'; # VERSION

use JsonSQL::Validator;



sub new {
    my ( $class, $query_rulesets, $json_schema ) = @_;
    
    ## DB specific values can be used in the future, but for now we are setting this to a common default.
    my $self = {
        _quoteChar => "'"
    };
    
    # Get a JsonSQL::Validator object with the provided $json_schema and $query_rulesets.
    my $validator = JsonSQL::Validator->new($json_schema, $query_rulesets);
    if ( eval { $validator->is_error } ) {
        return $validator;
    }
    
    # Save a reference to the JsonSQL::Validator for future processing of whitelisting rule sets.
    $self->{_validator} = $validator;
    
    bless $self, $class;
    return $self;
}


sub quote_identifier {
    my ( $self, $identifier ) = @_;
    
    ## This was taken and modified from Perl's DBI class.
    my $quote = $self->{_quoteChar};
    if ( defined $identifier ) {
        $identifier =~ s/$quote/$quote$quote/g;
        $identifier = qq($quote$identifier$quote);
    }
    
    return $identifier;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Query::Query - JSON query base class. Provides the quote_identifier method for escaping table and column identifiers.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This is a base module used to construct JsonSQL::Query modules. It is not meant to be instantiated directly.
Instead have a look at,

=over

=item * L<JsonSQL::Query::Select>

=item * L<JsonSQL::Query::Insert>

=back

You can also create your own subclass...

=head1 METHODS

=head2 Constructor new($query_rulesets, $json_schema) -> JsonSQL::Query::Query

Creates a JsonSQL::Validator object using the supplied $query_rulesets and $json_schema and stores a reference to use for future
validation and whitelist checking purposes. See L<JsonSQL::Validator> for more information.

    $query_rulesets     => The whitelist rule sets to be associated with this JsonSQL::Query object.
    $json_schema        => The name of the JSON schema to use for validation of the query.

=head2 ObjectMethod quote_identifier($identifier) -> quoted $identifier

Since table and column identifiers cannot be parameterized by most databases they have to be quoted. This method
is used during SQL query construction to quote non-parameterized identifiers.

    $identifier         => The identifier string to quote.

    Ex:
        Column1     => 'Column1'
        Co'lumn1    => 'Co''lumn1' 

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
