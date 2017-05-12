package Enbld::Command::Outdated;

use strict;
use warnings;

use parent qw/Enbld::Command/;

require Enbld::Home;
require Enbld::App::Configuration;
require Enbld::Target;
require Enbld::Message;

sub do {
    my $self = shift;
  
    Enbld::Home->initialize;
    Enbld::App::Configuration->read_file;

    my %outdated;
    foreach my $name ( keys %{ Enbld::App::Configuration->config } ) {
        my $config = Enbld::App::Configuration->search_config( $name );
        my $target = Enbld::Target->new( $name, $config );

        my $version = eval { $target->is_outdated };

        next if $@;

        if ( $version ) {
            $outdated{$name} = $version;
        }

    }

    if ( ! keys %outdated ) {
        print STDERR "no outdated targets.\n";
    }

    foreach my $name ( sort keys %outdated ) {
        my $config = Enbld::App::Configuration->search_config( $name );

        my $line = $name . ' ' x 15;
        print substr( $line, 0, 15 );
        print $config->enabled;
        print " < ";
        print $outdated{$name};
        print "\n";
    }

    return $self;
}

1;
