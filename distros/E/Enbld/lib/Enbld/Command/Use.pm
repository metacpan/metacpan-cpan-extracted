package Enbld::Command::Use;

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
    my $target_version = shift @{ $self->{argv} };

    if ( ! $target_version ) {
        die( Enbld::Error->new( "'use' command requires version param." ) );
    }

    Enbld::Home->initialize;
    Enbld::App::Configuration->read_file;

    my $config = Enbld::App::Configuration->search_config( $target_name );
    my $target = Enbld::Target->new( $target_name, $config );

    my $used = try {
        return $target->use( $target_version );
    } ( 'Enbld::Error' => sub {
        Enbld::Message->alert( $@ );
        return;
        }
      );

    if ( $used ) {
        Enbld::App::Configuration->set_config( $used );
        Enbld::App::Configuration->write_file;
    }

    return $used;
}

1;
