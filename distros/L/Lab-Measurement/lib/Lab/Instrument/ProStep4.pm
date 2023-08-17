package Lab::Instrument::ProStep4;
#ABSTRACT: ProStep4 step motor
$Lab::Instrument::ProStep4::VERSION = '3.881';
use v5.20;

use strict;
use Time::HiRes qw/usleep/, qw/time/;
use Lab::Instrument;

our $AXIS                  = 1;
our $RESOLUTION            = 1024;
our $GETRIEBEMULTIPLIKATOR = 0.015;
our $NULL                  = 32768;
our $STEPS_PER_ROUND       = 400;
our $BACKLASH              = 200;
our $AA                    = 200;
our $AE                    = 200;
our $VA                    = 0;
our $VE                    = 30;
our $VM                    = 30;

our %fields = (
    supported_connections => [ 'VISA', 'VISA_RS232', 'RS232', 'DEBUG' ],
    connection_settings   => {
        baudrate  => 9600,
        databits  => 8,
        stopbits  => 1,
        parity    => 'none',
        handshake => 'none',
        termchar  => '\r',
        timeout   => 2,
        inipath   => '',
        logpath   => '',
    },

    device_settings => {
        read_default => 'device',
        pos_mode     => 'ABS',
        speed_max    => 180,
        upper_limit  => 180,
        lower_limit  => -180,

    },

    device_cache => {
        position => undef,
        target   => undef,
    },

    device_cache_order => ['id'],
);

our @ISA = ("Lab::Instrument");

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    #$self->init();

    $self->{active} = 0;
    return $self;
}

sub _device_init {
    my $self = shift;

    $self->query("C:\r\n");
    $self->InitEncoder( $STEPS_PER_ROUND, $RESOLUTION, $NULL );
    $self->InitRamp( $AXIS, $AA, $AE, $VA, $VE, $VM );
    $self->clear();

    $self->init_limits();
}

sub InitEncoder {
    my $self = shift;
    my ( $steps, $res, $null )
        = $self->_check_args( \@_, [ 'steps', 'res', 'null' ] );

    $self->write("encoder: $steps $res $null\r\n");
    my $result = $self->read( { read_length => 300 } );

    return $result;
}

sub InitRamp {
    my $self = shift;

    my ( $axis, $aa, $ae, $va, $ve, $vm )
        = $self->_check_args( \@_, [ 'axis', 'aa', 'ae', 'va', 've', 'vm' ] );

    $self->write("tp: $axis $aa $ae $va $ve $vm\r\n");
    my $result = $self->read( { read_length => 100 } );

    return $result;
}

sub move {
    my $self = shift;

    my ( $position, $speed, $mode )
        = $self->_check_args( \@_, [ 'position', 'speed', 'mode' ] );

    if ( not defined $mode ) {
        $mode = $self->device_settings()->{pos_mode};
    }
    if ( not $mode =~ /ABS|abs|REL|rel/ ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "unexpected value for <MODE> in sub move. expected values are ABS and REL."
        );
    }
    if ( not defined $speed ) {
        $speed = $self->device_settings()->{speed_max};
    }
    if ( not defined $position ) {
        Lab::Exception::CorruptParameter->throw(
            error => $self->get_id() . ": No target given in sub move! " );
    }
    elsif (
        not $position =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ )
    {
        Lab::Exception::CorruptParameter->throw( error => $self->get_id()
                . ": Illegal Value given for POSITION in sub move!" );
    }

    # this sets the upper limit for the positioning speed:
    $speed = abs($speed);
    if ( $speed > $self->device_settings()->{speed_max} ) {
        print new Lab::Exception::CorruptParameter( error =>
                "Warning in sub move: <SPEED> = $speed is too high. Reduce <SPEED> to its maximum value defined by internal limit settings of $self->device_settings()->{speed_max}"
        );
        $speed = $self->device_settings()->{speed_max};
    }

    $speed = $self->angle2steps($speed) / 60;

    # Moving in ABS or REL mode:
    my $CP = $self->get_position();    # get current position
    if (   $mode eq "ABS"
        or $mode eq "abs"
        or $mode eq "ABSOLUTE"
        or $mode eq "absolute" ) {
        if (   $position < $self->device_settings()->{lower_limit}
            or $position > $self->device_settings()->{upper_limit} ) {
            Lab::Exception::CorruptParameter->throw( error =>
                    "unexpected value for NEW POSITION in sub move. Expected values are between "
                    . $self->device_settings()->{lower_limit} . " ... "
                    . $self->device_settings()->{upper_limit} );
        }
        $self->device_cache()->{target} = $position;
        $self->_save_motorlog( $CP, $position );
        $self->save_motorinitdata();
        $self->query(
            "ma$AXIS " . $self->angle2steps($position) . " $speed\r\n" );
    }
    elsif ($mode eq "REL"
        or $mode eq "rel"
        or $mode eq "RELATIVE"
        or $mode eq "relative" ) {
        if (   $CP + $position < $self->device_settings()->{lower_limit}
            or $CP + $position > $self->device_settings()->{upper_limit} ) {
            Lab::Exception::CorruptParameter->throw( error =>
                    "ERROR in sub move.Can't execute move; TARGET POSITION ("
                    . ( $CP + $position )
                    . ") is out of valid limits ("
                    . $self->device_settings()->{lower_limit} . " ... "
                    . $self->device_settings()->{upper_limit}
                    . ")" );
        }
        $self->device_cache()->{target} = $CP + $position;
        $self->_save_motorlog( $CP, $CP + $position );
        $self->save_motorinitdata();
        $self->query(
            "mr$AXIS " . $self->angle2steps($position) . " $speed\r\n" );

    }

    return 1;

}

sub active {
    my $self = shift;

    my $result = $self->get_position();

    return $self->{active};

}

sub wait {
    my $self = shift;

    my $flag = 1;
    local $| = 1;

    while ( $self->active() ) {
        my $current = $self->device_cache()->{position};
        if ( $flag <= 1.1 and $flag >= 0.9 ) {
            print $self->get_id()
                . sprintf( " is sweeping (%.2f\370)\r", $current );
        }
        elsif ( $flag <= 0 ) {
            print $self->get_id()
                . sprintf( " is          (%.2f\370)\r", $current );
            $flag = 2;
        }
        $flag -= 0.1;
        usleep(2e3);
    }

    print "\t\t\t\t\t\t\t\t\t\r";
    $| = 0;

    return 1;

}

sub abort {
    my ($self) = @_;
    while (1) {
        $self->query("sa$AXIS\r\n");
        if ( not $self->active() ) {
            last;
        }
    }
    print "Motor stoped at " . $self->get_position() . "\n";
    return;
}

sub init_limits {
    my $self = shift;
    my $lowerlimit;
    my $upperlimit;

    if ( $self->read_motorinitdata() ) {
        while (1) {
            print
                "Motor-Init data found. Do you want to keep the reference point and the limits? (y/n) ";
            my $input = <>;
            chomp $input;
            if ( $input =~ /YES|yes|Y|y/ ) {
                return 1;
            }
            elsif ( $input =~ /NO|no|N|n/ ) {
                my $result = $self->query("sa$AXIS\r\n");
                my $result = $self->query("nullen\r\n");
                $self->device_settings->{lower_limit} = -360;
                $self->device_settings->{upper_limit} = 360;
                last;
            }
        }
    }

    print "\n\n";
    print "----------------------------------------------\n";
    print "----------- Init Motor ProStep4  -------------\n";
    print "----------------------------------------------\n";
    print "\n";
    print
        "This procedure will help you to initialize the Motor ProStep4 correctly.\n\n";
    print "Steps to go:\n";
    print "  1.) Define the REFERENCE POINT.\n";
    print "  2.) Define the LOWER and UPPER LIMITS for rotation.\n";
    print "  3.) Confirm the LOWER and UPPER LIMITS.\n";
    print "\n\n";

    print "----------------------------\n";
    print "1.) Define the REFERENCE POINT:\n\n";
    print "--> Move the motor position to the REFERENCE POINT.\n";
    print "--> Enter a (relative) angle between -180 ... +180 deg.\n";
    print
        "--> Repeat until you have reached the position you want to define as the REFERENCE POINT.\n";
    print
        "--> Enter 'REF' to confirm the actual position as the REFERENCE POINT.\n\n";

    while (1) {
        print "MOVE: ";
        my $value = <>;
        chomp $value;
        if ( $value eq "REF" or $value eq "ref" ) {

            # set actual position as reference point Zero
            $self->device_cache()->{position} = 0;    # for testing only
            my $result = $self->query("sa$AXIS\r\n");
            my $result = $self->query("nullen\r\n");
            last;
        }
        elsif ( $value =~ /^[+-]?\d+$/ and $value >= -180 and $value <= 180 )
        {
            $self->move( $value, { mode => 'REL' } );
            $self->wait();
        }
        else {
            print
                "Please move the motor position to the REFERENCE POINT. Enter an angle between -188\370 ... +180\370.\n";
        }
    }

    print "----------------------------\n";
    print "2.) Define the LOWER and UPPER LIMITS for rotation:\n\n";
    print "--> Enter LOWER LIMIT\n";
    print "--> Enter UPPER LIMIT\n\n";

    while (1) {
        print "LOWER LIMIT: ";
        my $value = <>;
        chomp $value;
        $lowerlimit = $value;
        $self->device_settings()->{lower_limit} = $lowerlimit;
        print "UPPER LIMIT: ";
        my $value = <>;
        chomp $value;
        $upperlimit = $value;
        $self->device_settings()->{upper_limit} = $upperlimit;

        if ( $lowerlimit < $upperlimit ) {
            last;
        }
        else {
            print "LOWER LIMIT >= UPPER LIMIT. Try again!\n";
        }
    }

    print "----------------------------\n";
    print "3.) Confirm the LOWER and UPPER LIMITS:\n\n";
    print "--> Motor will move to LOWER LIMIT in steps of 10 deg\n";
    print "--> Motor will move to UPPER LIMIT in steps of 10 deg\n";
    print
        "--> Confirm each step with ENTER or type <STOP> to take the actual position as the limit value. \n\n";

    print "Moving to LOWER LIMIT ...\n";
    while (1) {
        print "MOVE +/-10: Please press <ENTER> to confirm.";
        my $input = <>;
        chomp $input;
        if ( $input =~ /stop|STOP/ ) {
            $lowerlimit = $self->get_position();
            last;
        }
        if ( abs( $self->get_position() - $lowerlimit ) >= 10 ) {
            if ( $lowerlimit <= 0 ) {
                $self->move( -10, { mode => 'REL' } );
                $self->wait();
            }
            else {
                $self->move( 10, { mode => 'REL' } );
                $self->wait();
            }
        }
        else {
            $self->move( $lowerlimit, { mode => 'ABS' } );
            $self->wait();
            last;
        }

    }
    print "Reached LOWER LIMIT\n";
    print "Please confirm the position of the LOWER LIMIT: ";
    <>;
    $self->device_settings()->{'lower_limit'} = $lowerlimit;
    print "\n\n";
    print "Moving to REFERENCE POINT ... \n";
    $self->move( 0, { mode => 'ABS' } ) . "\n";
    $self->wait();
    print "Moving to UPPER LIMIT ...\n";

    while (1) {
        print "MOVE +/-10: Please press <ENTER> to confirm.";
        my $input = <>;
        chomp $input;
        if ( $input =~ /stop|STOP/ ) {
            $upperlimit = $self->get_position();
            last;
        }
        if ( abs( $upperlimit - $self->get_position() ) >= 10 ) {
            $self->move( 10, { mode => 'REL' } );
            $self->wait();
        }
        else {
            $self->move( $upperlimit, { mode => 'ABS' } );
            $self->wait();
            last;
        }

    }
    print "Reached UPPER LIMIT\n";
    print "Please confirm the position of the UPPER LIMIT: ";
    <>;
    $self->device_settings()->{'upper_limit'} = $upperlimit;
    print "\n\n";
    $self->save_motorinitdata();

    print "moving to the reference point.\n";
    $self->move( 0, { mode => 'ABS' } );
    $self->wait();
    print "------------------------------------------------------\n";
    print "------------ Motor ProStep4 initialized --------------\n";
    print "------------------------------------------------------\n";
    print "\n\n";

}

sub steps2angle {
    my $self = shift;
    my ($steps) = $self->_check_args( \@_, ['value'] );

    my $angle = $steps * $GETRIEBEMULTIPLIKATOR;
    return $angle;
}

sub angle2steps {
    my $self = shift;
    my ($angle) = $self->_check_args( \@_, ['value'] );

    my $steps = $angle / $GETRIEBEMULTIPLIKATOR;
    return sprintf( "%0.f", $steps );

}

sub get_value {
    my $self = shift;
    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );
    return $self->get_position( { read_mode => $read_mode } );
}

sub get_position {
    my $self = shift;
    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );

    my $cmd = "a" . $AXIS . "?\r\n";
    my $result;

    if (   not defined $read_mode
        or not $read_mode =~ /device|cache|request|fetch/ ) {
        $read_mode = $self->device_settings()->{read_default};
    }

    if ( $read_mode eq 'cache'
        and defined $self->{'device_cache'}->{'position'} ) {
        return $self->{'device_cache'}->{'position'};
    }
    elsif ( $read_mode eq 'request' and $self->{request} == 0 ) {
        $self->{request} = 1;
        $self->write($cmd);
        return;
    }
    elsif ( $read_mode eq 'request' and $self->{request} == 1 ) {
        $result = $self->read();
        $self->write($cmd);
        return;
    }
    elsif ( $read_mode eq 'fetch' and $self->{request} == 1 ) {
        $self->{request} = 0;
        $result = $self->read();
    }
    else {
        if ( $self->{request} == 1 ) {
            $result          = $self->read();
            $self->{request} = 0;
            $result          = $self->query($cmd);
        }
        else {
            $result = $self->query($cmd);
        }
    }

    for ( 0 .. 2 ) {
        if ( $result =~ m/Posi_$AXIS:\s+([+-]?\d+)/ ) {
            $self->device_cache()->{position} = $self->steps2angle($1);
            $self->{active} = 0;
            last;
        }
        elsif ( $result
            =~ m/Soll\/Ist\/Speed_$AXIS:\s+([+-]?\d+)\s+([+-]?\d+)\s+([+-]?\d+)/
            ) {
            $self->device_cache()->{position} = $self->steps2angle($2);
            $self->{active} = 1;
            last;
        }
        else {
            $result
                = $self->connection()->BrutalRead( { read_length => 100 } );
        }
    }

    $self->save_motorinitdata();
    $self->{value} = $self->device_cache()->{position};
    return $self->device_cache()->{position};

}

sub save_motorinitdata {
    my $self = shift;

    open( DUMP, ">C:\\Perl\\site\\lib\\Lab\\Instrument\\ProStep4.ini" )
        ;    #open for write, overwrite

    print DUMP "POSITION: " . $self->device_cache()->{position} . "\n";
    print DUMP "TARGET: " . $self->device_cache()->{target} . "\n";
    print DUMP "SPEED_MAX: " . $self->device_settings()->{speed_max} . "\n";
    print DUMP "UPPER_LIMIT: "
        . $self->device_settings()->{upper_limit} . "\n";
    print DUMP "LOWER_LIMIT: "
        . $self->device_settings()->{lower_limit} . "\n";
    print DUMP "TIMESTAMP: " . time() . "\n";

    close(DUMP);
}

sub _save_motorlog {
    my $self = shift;
    my ( $init_pos, $end_pos )
        = $self->_check_args( \@_, [ 'init_pos', 'end_pos' ] );
    open( DUMP, ">>C:\\Perl\\site\\lib\\Lab\\Instrument\\ProStep4.log" )
        ;    #open for write, overwrite

    print DUMP ( my_timestamp() ) . "\t move: $init_pos -> $end_pos \n";

    close(DUMP);
}

sub read_motorinitdata {
    my $self = shift;

    if (
        not
        open( DUMP, "<C:\\Perl\\site\\lib\\Lab\\Instrument\\ProStep4.ini" ) )
    {
        return 0;
    }
    while (<DUMP>) {
        chomp($_);
        my @line = split( /: /, $_ );
        if ( $line[0] eq 'POSITION' ) {
            $self->device_cache()->{position} = $line[1];
        }
        elsif ( $line[0] eq 'TARGET' ) {
            $self->device_cache()->{target} = $line[1];
        }
        elsif ( $line[0] eq 'SPEED_MAX' ) {
            $self->device_settings()->{speed_max} = $line[1];
        }
        elsif ( $line[0] eq 'UPPER_LIMIT' ) {
            $self->device_settings()->{upper_limit} = $line[1];
        }
        elsif ( $line[0] eq 'LOWER_LIMIT' ) {
            $self->device_settings()->{lower_limit} = $line[1];
        }

    }

    print "\nread MOTOR-INIT-DATA\n";
    print "--------------------\n";
    print "POSITION: " . $self->device_cache()->{position} . "\n";
    print "TARGET: " . $self->device_cache()->{target} . "\n";
    print "SPEED_MAX: " . $self->device_settings()->{speed_max} . "\n";
    print "UPPER_LIMIT: " . $self->device_settings()->{upper_limit} . "\n";
    print "LOWER_LIMIT: " . $self->device_settings()->{lower_limit} . "\n";
    print "--------------------\n";
    return 1;
}

sub my_timestamp {

    my (
        $Sekunden, $Minuten,   $Stunden,   $Monatstag, $Monat,
        $Jahr,     $Wochentag, $Jahrestag, $Sommerzeit
    ) = localtime(time);

    $Monat     += 1;
    $Jahrestag += 1;
    $Monat     = $Monat < 10     ? $Monat     = "0" . $Monat     : $Monat;
    $Monatstag = $Monatstag < 10 ? $Monatstag = "0" . $Monatstag : $Monatstag;
    $Stunden   = $Stunden < 10   ? $Stunden   = "0" . $Stunden   : $Stunden;
    $Minuten   = $Minuten < 10   ? $Minuten   = "0" . $Minuten   : $Minuten;
    $Sekunden  = $Sekunden < 10  ? $Sekunden  = "0" . $Sekunden  : $Sekunden;
    $Jahr += 1900;

    return "$Stunden:$Minuten:$Sekunden  $Monatstag.$Monat.$Jahr\n";

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::ProStep4 - ProStep4 step motor

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Christian Butschkow, Stefan Geissler
            2014-2015  Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
