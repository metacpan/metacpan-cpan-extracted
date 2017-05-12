package Iodef::Pb::Format::Json;
use base 'Iodef::Pb::Format';

use strict;
use warnings;

require JSON::XS;

sub write_out {
    my $self = shift;
    my $args = shift;

    my $array = $self->to_keypair($args);
    my @json_stream;
    push(@json_stream,JSON::XS::encode_json($_)) foreach(@$array);
    my $text = join("\n",@json_stream);
    return $text;
}
1;
