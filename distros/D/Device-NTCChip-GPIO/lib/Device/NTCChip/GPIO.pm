# Author: Matthew Mallard
# Website: www.q-technologies.com.au
# Date: 6th October 2016
#
# ABSTRACT: Control the GPIO pins on the original NTC Chip


package Device::NTCChip::GPIO;
use Moose;
use Moose::Exporter;
use 5.10.0;

#use Log::MixedColor;
#use MooseX::Storage;
#use Data::Dumper;
use File::Spec::Functions;

with Storage(
    'format' => 'JSON',
    'io'     => 'File',
    traits   => ['DisableCycleDetection']
);

#has 'log' => (
#is  => 'rw',
#isa => 'Log::MixedColor',
#);

#has 'verbose' => (
#is        => 'rw',
#isa       => 'Bool',
#default   => 0,
#predicate => 'is_verbose',
#);

#has 'debug' => (
#is        => 'rw',
#isa       => 'Bool',
#default   => 0,
#predicate => 'is_debug',
#);

has 'label' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    default   => "pcf8574a",
    predicate => 'has_label',
);

has 'devpath' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    default   => "/sys/class/gpio",
    predicate => 'has_devpath',
);

has 'gpiopath' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_gpiopath',
);

has 'baseaddr' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_baseaddr',
);

has 'numaddr' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_numaddr',
);

sub BUILD {
    my $self = shift;
    my $args = shift;

    #$self->log( Log::MixedColor->new( $args ) );
    $self->_find_addrs();

}

sub export_all_pins {
}

sub unexport_all_pins {
}


sub turn_on {
    my $self = shift;
    my $pin  = shift;
    say "Turning on pin $pin";
    $self->set_pin_value( $pin, 1 );

}



sub turn_off {
    my $self = shift;
    my $pin  = shift;
    say "Turning off pin $pin";
    $self->set_pin_value( $pin, 0 );
}



sub relay_on {

    # Relays reverse the logic
    my $self = shift;
    my $pin  = shift;
    say "Turning on relay $pin";
    $self->set_pin_value( $pin, 0 );

}



sub relay_off {

    # Relays reverse the logic
    my $self = shift;
    my $pin  = shift;
    say "Turning off relay $pin";
    $self->set_pin_value( $pin, 1 );
}


sub read {
    my $self = shift;
    my $pin  = shift;
    $self->export_pin($pin);
    $self->set_pin_direction( $pin, 'in' );
    #say Dumper( $self->get_pin_direction($pin) );
    #say Dumper( $self->get_pin_value($pin) );

    #$self->unexport_pin($pin);
    return $self->get_pin_value($pin);

}

sub export_pin {
    my $self = shift;
    my $pin  = shift;
    my $ref  = $pin + $self->baseaddr;
    say "Making sure pin $pin is exported";

    # Only export pin if it is not already exported
    if ( !-e "/sys/class/gpio/gpio$ref" ) {
        open SYS, ">/sys/class/gpio/export" or die $!;
        say SYS $ref;
        close SYS;
    }
}

sub unexport_pin {
    my $self = shift;
    my $pin  = shift;
    my $ref  = $pin + $self->baseaddr;
    say "Unexporting pin $pin";
    open SYS, ">/sys/class/gpio/unexport" or die $!;
    say SYS $ref;
    close SYS;
}

sub get_pin_direction {
    my $self = shift;
    my $pin  = shift;
    my $ref  = $pin + $self->baseaddr;
    open SYS, "</sys/class/gpio/gpio$ref/direction" or die $!;
    chomp( my @direction = <SYS> );
    close SYS;

    #say Dumper( \@direction );
    return $direction[0];
}

sub get_pin_value {
    my $self = shift;
    my $pin  = shift;
    my $ref  = $pin + $self->baseaddr;
    open SYS, "</sys/class/gpio/gpio$ref/value" or die $!;
    chomp( my @reading = <SYS> );
    close SYS;

    #say Dumper( \@reading );
    return $reading[0];
}

sub set_pin_direction {
    my $self      = shift;
    my $pin       = shift;
    my $direction = shift;
    my $ref       = $pin + $self->baseaddr;
    open SYS, ">/sys/class/gpio/gpio$ref/direction" or die $!;
    say SYS $direction;
    close SYS;
}

sub set_pin_value {
    my $self  = shift;
    my $pin   = shift;
    my $value = shift;
    my $ref   = $pin + $self->baseaddr;
    $self->export_pin($pin);
    $self->set_pin_direction( $pin, 'out' );
    open SYS, ">/sys/class/gpio/gpio$ref/value" or die $!;
    say SYS $value;
    close SYS;
}

sub _find_addrs {
    my $self = shift;

    opendir( GD, $self->devpath )
      or die "Could not read " . $self->devpath . " " . $!;
    my @contents = grep !/^\./, readdir GD;
    for my $subdir (@contents) {
        my $file = catfile( $self->devpath, $subdir, "label" );
        if ( -f $file ) {
            open IN, "<$file" or die "Could not read " . $file . " " . $!;
            chomp( my $content = join( '', <IN> ) );
            if ( $content eq $self->label ) {
                $self->gpiopath( catfile( $self->devpath, $subdir ) );
                last;
            }
        }
    }
    closedir GD;

    if ( $self->has_gpiopath ) {
        say $self->gpiopath;
        $self->baseaddr(
            $self->_get_num_from_file( catfile( $self->gpiopath, "base" ) ) );
        $self->numaddr(
            $self->_get_num_from_file( catfile( $self->gpiopath, "ngpio" ) ) );
    }

}

sub _get_num_from_file {
    my $self = shift;
    my $file = shift;

    if ( -f $file ) {
        open B, "<$file" or die "Could not read " . $file . " " . $!;
        chomp( my $content = join( '', <B> ) );
        $content =~ s/\s+//g;
        if ( $content =~ /^(\d+)$/ ) {
            return $1;    # untainted
        }
        else {
            die "Unexpected error: $file has unexpected contents";
        }
    }
    else {
        die "Unexpected error: $file does not exist";
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::NTCChip::GPIO - Control the GPIO pins on the original NTC Chip

=head1 VERSION

version 0.101

=head1 SYNOPSIS

This module provides method to control the GPIO pins on the original NTC Chip.  It first scans the
F</sys/class/gpio> location to map the GPIO addresses, then provides methods to turn the pins on or off
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
community site that provide a lot of info: L<http://www.chip-community.org/index.php/Main_Page>.

=head1 METHODS

=head2 turn_on

Turn a pin on (set it high)

    $gpio->turn_on(3);

=head2 turn_off

Turn a pin turn off (set it low)

    $gpio->turn_off(3);

=head2 relay_on

Turn a pin off (set it low)

    $gpio->relay_on(3);

=head2 relay_off

Turn a pin on (set it high)

    $gpio->relay_off(3);

=head2 read

Read whether a pin is on or off (high or low).

    my $value = $gpio->read(3);

=head1 BUGS/FEATURES

Please report any bugs or feature requests in the issues section of GitHub: 
L<https://github.com/Q-Technologies/perl-Device-NTCChip-GPIO>. Ideally, submit a Pull Request.

=head1 AUTHOR

Matthew Mallard <mqtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
