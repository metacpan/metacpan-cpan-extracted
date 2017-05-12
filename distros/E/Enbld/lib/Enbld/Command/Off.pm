package Enbld::Command::Off;

use strict;
use warnings;

use parent qw/Enbld::Command/;

use Try::Lite;

require Enbld::Home;
require Enbld::App::Configuration;
require Enbld::Error;
require Enbld::Exception;
require Enbld::Target;

sub do {
    my $self = shift;

    my $target_name = $self->validate_target_name( shift @{ $self->{argv} } );

    Enbld::Home->initialize;
    Enbld::App::Configuration->read_file;

    my $config = Enbld::App::Configuration->search_config( $target_name );
    my $target = Enbld::Target->new( $target_name, $config );

    my $offed = try {
        return $target->off;
    } ( 'Enbld::Error' => sub {
        Enbld::Message->notify( $@ );
        return;
        }
      );

    if ( $offed ) {
        Enbld::App::Configuration->set_config( $offed );
    } 

    Enbld::App::Configuration->write_file;

    return $offed;
}

1;
