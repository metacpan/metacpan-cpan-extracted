# ABSTRACT: JSON schema base class. Used as a dispatcher for loading JSON schema objects used by JsonSQL::Validator.


use strict;
use warnings;
use 5.014;

package JsonSQL::Schemas::Schema;

our $VERSION = '0.4'; # VERSION

use Class::Load qw( try_load_class );
use JSON::Parse qw( parse_json );

use JsonSQL::Error;



sub new {
    my $class = shift;
    
    my $self = {};
    
    bless $self, $class;
    return $self;
}


sub load_schema {
    my ( $caller, $jsonSchema ) = @_;
    
    my $class = "JsonSQL::Schemas::" . $jsonSchema;
    
    my ( $success, $err ) = try_load_class($class);
    if ( $success ) {
        my $schema = $class->new;
        
        # When parsing JSON, need to trap parsing errors.
        my $schemaObj = eval {
            return parse_json($schema->{_json});
        };
        
        if ( $@ ) {
            return JsonSQL::Error->new("json_schema", "Schema is invalid JSON at: $@");
        } else {
            return $schemaObj;
        }
    } else {
        return JsonSQL::Error->new("json_schema", $err);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JsonSQL::Schemas::Schema - JSON schema base class. Used as a dispatcher for loading JSON schema objects used by JsonSQL::Validator.

=head1 VERSION

version 0.4

=head1 SYNOPSIS

This is a supporting module used by L<JsonSQL::Validator> for loading JSON schemas.

To use this:

    my $schema = JsonSQL::Schemas::Schema->load_schema(<schema_name>);
    if ( eval { $schema->is_error } ) {
        return "Could not load JSON schema: $schema->{message}";
    } else {
        ...
    }

<schemaname> must be a module residing in JsonSQL::Schemas that is a subclass of this one. See, for example,

=over

=item * L<JsonSQL::Schemas::select>

=item * L<JsonSQL::Schemas::insert>

=back

If you desire other JSON schemas you can create your own...

=head1 METHODS

=head2 Constructor new -> JsonSQL::Schemas::Schema

An inherited constructor for creating the blessed object reference. This should not be called directly. Instead use load_schema.

=head2 Dispatcher load_schema($jsonSchema) -> JsonSQL::Schemas<schema>

Serves as a dispatcher method to load the appropriate subclass for the specified $jsonSchema.

    $jsonSchema         => The name of the JSON schema to load.

=head1 AUTHOR

Chris Hoefler <bhoefler@draper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Hoefler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
