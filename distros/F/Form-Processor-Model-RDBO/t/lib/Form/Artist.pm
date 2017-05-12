package Form::Artist;

use strict;
use warnings;

use base 'Form::Processor::Model::RDBO';

sub object_class { 'RDBO::Artist' }

sub profile {
    my $self = shift;

    return {
        required => { name   => 'Text' },
        optional => {
            albums => 'Multiple',
            genres => 'Multiple'
        },
        unique => [ qw/ name / ]
    };
}

1;
