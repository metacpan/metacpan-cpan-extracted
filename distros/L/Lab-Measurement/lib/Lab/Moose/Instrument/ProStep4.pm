package Lab::Moose::Instrument::ProStep4;
$Lab::Moose::Instrument::ProStep4::VERSION = '3.904';
#ABSTRACT: ProStep4 step motor
#TODO: Documentation!!!

use v5.20;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter validated_no_param_setter setter_params /;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';


#has AXIS => (
#	is	    => 'ro',
#	isa     => 'Int',
#	default => 1
#);
#
#has RESOLUTION => (
#	is		=> 'ro',
#	isa		=> 'Int',
#	default => 1024
#);
#
#has GETRIEBEMULTIPLIKATOR => (
#	is		=> 'ro',
#	isa		=> 'Num',
#	default => 0.015 
#);
#
#has NULL => (
#	is		=> 'ro',
#	isa		=> 'Int',
#	default => 32768 
#);
#
#has STEPS_PER_ROUND => (
#	is		=> 'ro',
#	isa		=> 'Int',
#	default => 400 
#);
#
#has BACKLASH => (
#	is		=> 'ro',
#	isa		=> 'Int',
#	default => 200 
#);
#
#has AA => (
#	is		=> 'ro',
#	isa		=> 'Int',
#	default => 200 
#);
#
#has AE => (
#	is		=> 'ro',
#	isa		=> 'Int',
#	default => 200 
#);
#
#has VA => (
#	is		=> 'ro',
#	isa		=> 'Int',
#	default => 0 
#);
#
#has VE => (
#	is		=> 'ro',
#	isa		=> 'Int',
#	default => 30
#);
#
#has VM => (
#	is		=> 'ro',
#	isa		=> 'Int',
#	default => 30
#);

has on => (
	is  	=> 'rw',
	isa 	=> 'Int',
	default => 0
);

has request => (
	is 		=> 'rw',
	isa		=> 'Int',
	default => 0
);

has value => (
	is		=> 'rw',
	isa		=> 'Int',
);

# Save all important data in hashes for better readability
my %device_props = (
	AXIS                  => 1,
	RESOLUTION            => 1024,
	GETRIEBEMULTIPLIKATOR => 0.015,
	NULL                  => 32768,
	STEPS_PER_ROUND       => 400,
	BACKLASH              => 200,
	AA                    => 200,
	AE                    => 200,
	VA                    => 0,
	VE                    => 30,
	VM                    => 30,
);

my %device_settings = (
	read_default => 'device',
	pos_mode	 => 'ABS',
	speed_max	 => 180,
	upper_limit  => 180,
	lower_limit  => -180,
);

my %device_cache = (
	position => undef,
	target   => undef,
);

sub BUILD {
	my $self = shift;

# Since RS232 was dropped in Moose, only the VISA connection is left.
# In the original driver just the termchar was set... 
# Is the enable_read_termchar() necessary?
	$self->connection->set_termchar( termchar => "\r" );
	$self->connection->enable_read_termchar();
}

sub _device_init {
	my $self = shift;

	$self->query("C:\r\n");
    $self->InitEncoder( $device_props{'STEPS_PER_ROUND'},
						$device_props{'RESOLUTION'},
						$device_props{'NULL'}
					  );
    $self->InitRamp( $device_props{'AXIS'}, $device_props{'AA'},
					 $device_props{'AE'}, $device_props{'VA'},
					 $device_props{'VE'}, $device_props{'VM'}
				   );
    $self->clear();

    $self->init_limits();
}

sub InitEncoder {
	my ( $self, %args ) = validated_getter(
		\@_,
		steps => { isa => 'Lab::Moose::Int' },
		res   => { isa => 'Lab::Moose::Int' },
		null  => { isa => 'Lab::Moose::Int' },
	);

	my ( $steps, $res, $null )
		= delete @args{ qw/steps res null/ };

    $self->write( command => "encoder: $steps $res $null\r\n" );
    my $result = $self->read( command => { read_length => 300 } );

    return $result;
}

sub InitRamp {
	my ( $self, %args ) = validated_getter(
		\@_,
		axis => { isa => 'Lab::Moose::Int' },
		aa   => { isa => 'Lab::Moose::Int' },
		ae   => { isa => 'Lab::Moose::Int' },
		va   => { isa => 'Lab::Moose::Int' },
		ve   => { isa => 'Lab::Moose::Int' },
		vm   => { isa => 'Lab::Moose::Int' },
	);

	my ( $axis, $aa, $ae, $va, $ve, $vm, )
		= delete @args{ qw/axis aa ae va ve vm/ };

    $self->write( command => "tp: $axis $aa $ae $va $ve $vm\r\n" );
    my $result = $self->read( command => { read_length => 100 } );

    return $result;
}

sub move {
	my ( $self, %args ) = validated_getter(
		\@_,
		position => {isa => 'Lab::Moose::Int' },
		speed    => {isa => 'Lab::Moose::Int' },
		mode     => {isa => 'Lab::Moose::Int' },
	);

	my ( $position, $speed, $mode )
		= delete @args{ qw/position speed mode/ };

    if ( not defined $mode ) {
        $mode = $device_settings{'pos_mode'};
    }
    if ( not $mode =~ /ABS|abs|REL|rel/ ) {
    	croak "unexpected value for <MODE> in sub move.
               expected values are ABS and REL."
    }
    if ( not defined $speed ) {
        $speed = $device_settings{speed_max};
    }
    if ( not defined $position ) {
            croak $self->get_id() . ": No target given in sub move!"
    }
    elsif (
        not $position =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ )
    {
        croak $self->get_id()
                . ": Illegal Value given for POSITION in sub move!"
    }

    # this sets the upper limit for the positioning speed:
    $speed = abs($speed);
    if ( $speed > $device_settings{speed_max} ) {
    	warn "Warning in sub move: <SPEED> = $speed is too high.
              Reduce <SPEED> to its maximum value defined by internal
              limit settings of $device_settings{speed_max}";
        $speed = $device_settings{speed_max};
    }

    $speed = $self->angle2steps($speed) / 60;

    # Moving in ABS or REL mode:
    my $CP = $self->get_position();

    if (   $mode eq "ABS"
        or $mode eq "abs"
        or $mode eq "ABSOLUTE"
        or $mode eq "absolute" ) {
        if (   $position < $device_settings{lower_limit}
            or $position > $device_settings{upper_limit} ) {
        		croak "unexpected value for NEW POSITION in sub move.
                       Expected values are between "
                    . $device_settings{lower_limit} . " ... "
                    . $device_settings{upper_limit}
        }
        $device_cache{target} = $position;
        $self->_save_motorlog( $CP, $position );
        $self->save_motorinitdata();
        $self->query(
            command => "ma$device_props{'AXIS'} "
                       . $self->angle2steps($position) . " $speed\r\n" );
    }
    elsif ($mode eq "REL"
        or $mode eq "rel"
        or $mode eq "RELATIVE"
        or $mode eq "relative" ) {
        if (   $CP + $position < $device_settings{lower_limit}
            or $CP + $position > $device_settings{upper_limit} ) {
                    croak "ERROR in sub move.
                           Can't execute move; TARGET POSITION ("
                    . ( $CP + $position )
                    . ") is out of valid limits ("
                    . $device_settings{lower_limit} . " ... "
                    . $device_settings{upper_limit}
                    . ")"
        }
        $device_cache{target} = $CP + $position;
        $self->_save_motorlog( $CP, $CP + $position );
        $self->save_motorinitdata();
        $self->query(
            command => "mr$device_props{'AXIS'} "
                        . $self->angle2steps($position) . " $speed\r\n" );

    }

    return 1;

}

sub active {
    my $self = shift;

    my $result = $self->get_position();

    return $self->active;

}

sub wait {
    my $self = shift;

    my $flag = 1;
	# ???
    local $| = 1;

    while ( $self->active() ) {
        my $current = $device_cache{position};
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
    my $self = shift;
    while(1) {
        $self->query( command => "sa$device_props{'AXIS'}\r\n" );
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
                "Motor-Init data found.
                 Do you want to keep the reference point
                 and the limits? (y/n) ";
            my $input = <>;
            chomp $input;
            if ( $input =~ /YES|yes|Y|y/ ) {
                return 1;
            }
            elsif ( $input =~ /NO|no|N|n/ ) {
				# ??? 
                my $result = $self->query(command => "sa$device_props{'AXIS'}\r\n");
                $result = $self->query(command => "nullen\r\n");
                $device_settings{lower_limit} = -360;
                $device_settings{upper_limit} = 360;
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
            $device_cache{position} = 0;    # for testing only
			# ???
            my $result = $self->query(command => "sa$device_props{'AXIS'}\r\n");
            $result = $self->query(command => "nullen\r\n");
            last;
        }
        elsif ( $value =~ /^[+-]?\d+$/ and $value >= -180 and $value <= 180 )
        {
            $self->move( $value, { mode => 'REL' } );
            $self->wait();
        }
        else {
            print
                "Please move the motor position to the REFERENCE POINT. Enter an angle between -180\370 ... +180\370.\n";
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
        $device_settings{lower_limit} = $lowerlimit;
        print "UPPER LIMIT: ";
        $value = <>;
        chomp $value;
        $upperlimit = $value;
        $device_settings{upper_limit} = $upperlimit;

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
                $self->move( command => "-10, { mode => 'REL' }" );
                $self->wait();
            }
            else {
                $self->move( command => "10, { mode => 'REL' }" );
                $self->wait();
            }
        }
        else {
            $self->move( command => "$lowerlimit, { mode => 'ABS' }" );
            $self->wait();
            last;
        }

    }
    print "Reached LOWER LIMIT\n";
    print "Please confirm the position of the LOWER LIMIT: ";
    <>;
    $device_settings{'lower_limit'} = $lowerlimit;
    print "\n\n";
    print "Moving to REFERENCE POINT ... \n";
    $self->move( command => "0, { mode => 'ABS' }" );
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
            $self->move( command => "10, { mode => 'REL' }" );
            $self->wait();
        }
        else {
            $self->move( command => "$upperlimit, { mode => 'ABS' }" );
            $self->wait();
            last;
        }

    }
    print "Reached UPPER LIMIT\n";
    print "Please confirm the position of the UPPER LIMIT: ";
    <>;
    $device_settings{'upper_limit'} = $upperlimit;
    print "\n\n";
    $self->save_motorinitdata();

    print "moving to the reference point.\n";
    $self->move( command => "0, { mode => 'ABS' }" );
    $self->wait();
    print "------------------------------------------------------\n";
    print "------------ Motor ProStep4 initialized --------------\n";
    print "------------------------------------------------------\n";
    print "\n\n";

}

sub steps2angle {
	my ( $self, %args ) = validated_hash(
		\@_,
		steps => { isa => 'Num' },
	);

	my $steps = delete @args{qw/steps/};

    my $angle = $steps * $device_props{GETRIEBEMULTIPLIKATOR};
    return $angle;
}

sub angle2steps {
	my ( $self, %args ) = validated_hash(
		\@_,
		angle => { isa => 'Num' },
	);
	
	my $angle = delete @args{qw/angle/};

    my $steps = $angle / $device_props{GETRIEBEMULTIPLIKATOR};
    return sprintf( "%0.f", $steps );
}

sub get_value {
	my ( $self, %args ) = validated_hash(
		\@_,
		read_mode => { isa => enum( [qw/device|cache|request|fetch/] ) },
	);
	
	my $read_mode = delete @args{qw/read_mode/};

    return $self->get_position( command => "read_mode => $read_mode" );
}

sub get_position {
	my ( $self, %args ) = validated_hash(
		\@_,
		read_mode => { isa => enum( [qw/device|cache|request|fetch/] ) },
	);

	my $read_mode = delete @args{qw/read_mode/};

    my $cmd = "a" . $device_props{'AXIS'} . "?\r\n";
    my $result;

    if (   not defined $read_mode
        or not $read_mode =~ /device|cache|request|fetch/ ) {
        $read_mode = $device_settings{read_default};
    }

    if ( $read_mode eq 'cache'
        and defined $self->{'device_cache'}->{'position'} ) {
        return $device_cache{'position'};
    }
    elsif ( $read_mode eq 'request' and $self->{request} == 0 ) {
        $self->{request} = 1;
        $self->write($cmd);
        return;
    }
    elsif ( $read_mode eq 'request' and $self->{request} == 1 ) {
        $result = $self->read();
        $self->write( command => "$cmd" );
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
            $result          = $self->query( command => "$cmd" );
        }
        else {
            $result = $self->query( command => "$cmd" );
        }
    }

    for ( 0 .. 2 ) {
        if ( $result =~ m/Posi_$device_props{'AXIS'}:\s+([+-]?\d+)/ ) {
            $device_cache{position} = $self->steps2angle(command => "$1" );
            $self->{active} = 0;
            last;
        }
        elsif ( $result
            =~ m/Soll\/Ist\/Speed_$device_props{'AXIS'}:\s+([+-]?\d+)\s+([+-]?\d+)\s+([+-]?\d+)/
            ) {
            $device_cache{position} = $self->steps2angle( command => "$2" );
            $self->{active} = 1;
            last;
        }
        else {
            $result
				# ???
                = $self->connection()->BrutalRead( command => "{ read_length => 100 }" );
        }
    }

    $self->save_motorinitdata();
    $self->{value} = $device_cache{position};
    return $device_cache{position};

}

sub save_motorinitdata {
    my $self = shift;

	open my $dump, '>', "C:\\Perl\\site\\lib\\Lab\\Instrument\\ProStep4.ini"
		or croak "Can't open ini file!";

    print {$dump} "POSITION: " . $device_cache{position} . "\n";
    print {$dump} "TARGET: " . $device_cache{target} . "\n";
    print {$dump} "SPEED_MAX: " . $device_settings{speed_max} . "\n";
    print {$dump} "UPPER_LIMIT: "
        . $device_settings{upper_limit} . "\n";
    print {$dump} "LOWER_LIMIT: "
        . $device_settings{lower_limit} . "\n";
	# ??? Problem mit time()
    print {$dump} "TIMESTAMP: " . time() . "\n";

    close $dump;
}

sub _save_motorlog {
	my ( $self, %args ) = validated_getter(
		\@_,
		init_pos => { isa => 'Num' },
		end_pos  => { isa => 'Num' },
	);
	
	my ( $init_pos, $end_pos )
		= delete @args{qw/init_pos end_pos/};
	
	open my $log, '>>', "C:\\Perl\\site\\lib\\Lab\\Instrument\\ProStep4.log"
		or croak "Can't open log file!";

    print {$log} ( my_timestamp() ) . "\t move: $init_pos -> $end_pos \n";

    close $log;
}

sub read_motorinitdata {
    my $self = shift;

	open my $init_file, '<', "C:\\Perl\\site\\lib\\Lab\\Instrument\\ProStep4.ini"
		or croak "Can't open init file!";

    while (<$init_file>) {
        chomp($_);
        my @line = split( /: /, $_ );
        if ( $line[0] eq 'POSITION' ) {
            $device_cache{position} = $line[1];
        }
        elsif ( $line[0] eq 'TARGET' ) {
            $device_cache{target} = $line[1];
        }
        elsif ( $line[0] eq 'SPEED_MAX' ) {
            $device_settings{speed_max} = $line[1];
        }
        elsif ( $line[0] eq 'UPPER_LIMIT' ) {
            $device_settings{upper_limit} = $line[1];
        }
        elsif ( $line[0] eq 'LOWER_LIMIT' ) {
            $device_settings{lower_limit} = $line[1];
        }

    }

    print "\nread MOTOR-INIT-DATA\n";
    print "--------------------\n";
    print "POSITION: " . $device_cache{position} . "\n";
    print "TARGET: " . $device_cache{target} . "\n";
    print "SPEED_MAX: " . $device_settings{speed_max} . "\n";
    print "UPPER_LIMIT: " . $device_settings{upper_limit} . "\n";
    print "LOWER_LIMIT: " . $device_settings{lower_limit} . "\n";
    print "--------------------\n";
    return 1;
}

sub my_timestamp {

	# ??? Ersatz für localtime
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

=encoding utf8
=head1 SYNOPSIS

=head1 NAME

Lab::Moose::Instrument::ProStep4 - ProStep4 step motor

=head1 VERSION

version 3.904

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by the Lab::Measurement team; in detail:

  Copyright 2022-2023  Mia Schambeck


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
