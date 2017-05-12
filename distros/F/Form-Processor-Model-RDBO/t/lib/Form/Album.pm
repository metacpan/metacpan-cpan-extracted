package Form::Album;

use strict;
use warnings;

use base 'Form::Processor::Model::RDBO';

sub object_class { 'RDBO::Album' }

sub profile {
    my $self = shift;

    return {
        required => { title => 'Text' },
        optional => {
            artist_fk  => 'Select',
            artist_rel => 'Select'
        },
    };
}

1;
