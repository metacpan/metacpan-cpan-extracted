package Form::User;

use strict;
use warnings;
use base 'Form::Processor::Model::DOD';

# Define the object we are working on

sub object_class { 'Model::User' }

sub profile {
    return {
        required => {
            name       => 'Text',
            # These are fetched and validate from the database
            state      => 'Select',
            married_on => 'Text',
        },
        optional => {
            # Text field so can use options below
            favorite_number   => 'Select',
        },
    };
}

sub options_state { 
    return [ drunk => 'drunk', sober => 'sober' ];
}

sub options_favorite_number {
    return [
        1   => 'One',
        2   => 'Two',
        3   => 'Three',
    ];
}

1;

