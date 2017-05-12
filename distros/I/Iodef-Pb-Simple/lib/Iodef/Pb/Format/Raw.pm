package Iodef::Pb::Format::Raw;
use base 'Iodef::Pb::Format';

use strict;
use warnings;

sub write_out {
    my $self = shift;
    my $args = shift;

    my $array = $self->to_keypair($args);
    return $array;
}
1;
