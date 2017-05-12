package Enbld::Command;

use strict;
use warnings;

use Module::Load;
use Module::Load::Conditional qw/can_load/;

require Enbld::Message;
require Enbld::Home;
require Enbld::Logger;
require Enbld::App::Configuration;

sub new {
    my $class = shift;

    my $self = {
        cmd         =>  undef,
        argv        =>  undef,
        @_,
    };

    my $module = 'Enbld::Command::' . ucfirst( $self->{cmd} );

    return bless $self, $module if can_load( modules => { $module => undef } );

    die 'ERROR:Unknown command:' . $self->{cmd} . "\n";
}

sub setup {
    Enbld::Home->initialize;
    Enbld::Home->create_build_directory;
    Enbld::Logger->rotate( Enbld::Home->log );

    Enbld::App::Configuration->read_file;
}

sub teardown {
    Enbld::App::Configuration->write_file;
}

sub validate_target_name {
    my ( $self, $target_name ) = @_;

    if ( ! $target_name ) {
        die "ERROR:'$self->{cmd}' command requires target's name argument.\n";
    }

    if ( $target_name =~ /[^a-z0-9]/ ) {
        die "ERROR:target's name '$target_name' is invalid.\n";
    }

    return $target_name;
}

1;
