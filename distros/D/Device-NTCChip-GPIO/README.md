# NAME

Device::NTCChip::GPIO - Control the GPIO pins on the original NTC Chip

# VERSION

version 0.100

# SYNOPSIS

This module provides method to control the GPIO pins on the original NTC Chip.  It first scans the
`/sys/class/gpio` location to map the GPIO addresses, then provides methods to turn the pins on or off
or read them.

    use Device::NTCChip::GPIO;

    # Initialise the GPIO interface
    my $gpio = Device::NTCChip::GPIO->new;

    # take the appropriate action
    if ( $action eq "on" ){
        $gpio->relay_on($pin);
    } elsif ( $action eq "off" ){
        $gpio->relay_off($pin);
    } else {
        my $error = "Unknown facility mode: $action";
        die $error;
    }

NTC has gone into liquidation since this module was first written, but it is being made available in the
hope it will be of some use to somebaody.  No original NTC domains exist anymore, but there is this 
community site that provide a lot of info: [http://www.chip-community.org/index.php/Main\_Page](http://www.chip-community.org/index.php/Main_Page).

# METHODS

## turn\_on

Turn a pin on (set it high)

    $gpio->turn_on(3);

## turn\_off

Turn a pin turn off (set it low)

    $gpio->turn_off(3);

## relay\_on

Turn a pin off (set it low)

    $gpio->relay_on(3);

## relay\_off

Turn a pin on (set it high)

    $gpio->relay_off(3);

## read

Read whether a pin is on or off (high or low).

    my $value = $gpio->read(3);

# BUGS/FEATURES

Please report any bugs or feature requests in the issues section of GitHub: 
[https://github.com/Q-Technologies/perl-Log-MixedColor](https://github.com/Q-Technologies/perl-Log-MixedColor). Ideally, submit a Pull Request.

# AUTHOR

Matthew Mallard <mqtech@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
