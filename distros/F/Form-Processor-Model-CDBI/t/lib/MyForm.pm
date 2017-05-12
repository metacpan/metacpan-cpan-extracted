package MyForm;
use strict;
use warnings;
use base 'Form::Processor::Model::CDBI';

# Define the object we are working on

sub object_class { 'CDBI::User' }

sub profile {
    return {
        required => {
            name    => 'Text',
            # These are fetched and validate from the database
            state   => 'Select',
            roles   => 'Multiple',
        },
        optional => {
            # Text field so can use options below
            favorite_number   => 'Select',
        },
    };
}

sub options_favorite_color {
    return [
        1   => 'One',
        2   => 'Two',
        3   => 'Three',
    ];
}

1;
