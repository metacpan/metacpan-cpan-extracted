package Enbld::Command::Install;

use strict;
use warnings;

use 5.010001;

use parent qw/Enbld::Command/;

use Try::Lite;

require Enbld::App::Configuration;
require Enbld::Error;
require Enbld::Exception;
require Enbld::Message;
require Enbld::Target;
require Enbld::Logger;
require Enbld::Condition;

sub do {
    my $self = shift;

    my $target_name = $self->validate_target_name( shift @{ $self->{argv} } );
    my $version = shift @{ $self->{argv} };

    $self->setup;

    my $config = Enbld::App::Configuration->search_config( $target_name );
    my $target = Enbld::Target->new( $target_name, $config );

    my $installed = try {
            return $target->install( $version );
    } ( 'Enbld::Error' => sub {
        Enbld::Message->alert( $@ );

        if ( $^O ne 'darwin' ) {
            say "If you run Enbld at Linux or BSD, there is a possibility " .
            "that the Software which depends is not installed.";
        }

        say "\nPlease check build logile:" . Enbld::Logger->logfile;

		return;
        }
      );

    if ( $installed ) {
        Enbld::App::Configuration->set_config( $installed );
    }

    $self->teardown;

    return $installed;
}

1;
