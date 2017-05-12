package Enbld::Command::List;

use strict;
use warnings;

use 5.010001;

use parent qw/Enbld::Command/;

use Encode;

require Enbld::Home;
require Enbld::App::Configuration;

sub do {
    my $self = shift;

    my $target_name = shift @{ $self->{argv} };

	if ( $target_name ) {

		$self->list_target_installed_version( $target_name );

	} else {
		$self->list_all_installed;
	}
}

sub list_all_installed {
	my $self = shift;

    Enbld::Home->initialize;
    Enbld::App::Configuration->read_file;

    my $collection = Enbld::App::Configuration->config;

    if ( ! keys %{ $collection } ) {
        say "Nothing is installed yet.";
    }

    foreach my $name ( sort keys %{ $collection } ) {
        my $config = Enbld::App::Configuration->search_config( $name );
        
        my $line = $name . ' ' x 15;
        
        print substr( $name . ' ' x 15 , 0, 15 );

        my $version;
        if ( $config->enabled ) {
            $version = $config->enabled;
        } else {
            $version = 'Not enabled now...';
        }

        print substr( $version . ' ' x 20, 0, 20 );

        if ( $config->enabled && $config->condition->annotation ) {
            print encode( 'UTF-8', $config->condition->annotation );
        }

        print "\n";
    }

    return $self;
}

sub list_target_installed_version {
	my $self = shift;
	my $target_name = shift;

    Enbld::Home->initialize;
    Enbld::App::Configuration->read_file;

    my $config = Enbld::App::Configuration->search_config( $target_name );

    if ( ! $config ) {
        require Enbld::Error;
        Enbld::Error->throw( "Target '$target_name' is not installed yet.\n" );
    }

    for my $installed ( sort keys %{ $config->installed } ) {
        print $installed . "\n";
    }



	return $self;
}

1;
