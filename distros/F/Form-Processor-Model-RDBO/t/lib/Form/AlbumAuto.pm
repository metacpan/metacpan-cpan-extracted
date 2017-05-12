package Form::AlbumAuto;

use strict;
use warnings;

use base 'Form::Processor::Model::RDBO';

sub object_class { 'RDBO::Album' }

sub profile {
    my $self = shift;

    return {
        auto_optional => [qw/ extra /],
        required => { title => 'Text' },
        optional => {
            artist_fk  => 'Auto',
            artist_rel => 'Auto'
        },
    };
}

1;
