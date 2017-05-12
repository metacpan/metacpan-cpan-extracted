package Enbld::Command::Rehash;

use strict;
use warnings;

use parent qw/Enbld::Command/;

use Try::Lite;

require Enbld::Home;
require Enbld::Error;
require Enbld::App::Configuration;
require Enbld::Target;

sub do {
    my $self = shift;

    my $target_name = $self->validate_target_name( shift @{ $self->{argv} } );

    Enbld::Home->initialize;
    Enbld::App::Configuration->read_file;

    my $config = Enbld::App::Configuration->search_config( $target_name );
    my $target = Enbld::Target->new( $target_name, $config );

    try { $target->rehash } (
            'Enbld::Error' => sub {
            Enbld::Message->alert( $@ );
            return;
            }
            );

    return $target_name;
}

1;