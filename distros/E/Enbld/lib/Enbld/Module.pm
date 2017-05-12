package Enbld::Module;

use strict;
use warnings;

use Module::Load::Conditional qw/can_load/;

require Enbld::Message;
require Enbld::Error;

sub new {
    my $class = shift;

    my $self = {
        name            =>  undef,
        path            =>  undef,
        module_file     =>  undef,
        install_command =>  undef,
        @_,
    };
    
    my $module = 'Enbld::Module::' . ucfirst( $self->{name} );
    can_load( modules => { $module => 0 } ) or
        Enbld::Error->throw( "no module for target '$self->{name}'" );

    bless $self, $module;

    $self->initialize;

    return $self;
}

sub install {
    my $self = shift;

    require Enbld::Logger;
    my $logfile = Enbld::Logger->logfile;

    my $start_msg = "----> Start install modules for '$self->{name}'.";
    Enbld::Message->notify( $start_msg );

    my $cmd = $self->install_command;

    Enbld::Message->notify( "--> $cmd" );
    system( "$cmd >> $logfile 2>&1" );

    if ( $? >> 8 ) {
        my $err = "Build fail.Command:$cmd return code:" . ( $? >> 8 );
        Enbld::Error->throw( $err );
    }

    my $end_msg = "----> Finish install modules for '$self->{name}'.";
    Enbld::Message->notify( $end_msg );

    return $self;
}

sub install_command {
    # virtual method
}

sub initialize {
    # virtual method
}

1;
