#!/usr/bin/perl

# Copyright    : Copyright (c) 2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.

use strict;
use warnings;
use HiPi qw( :pca9685 );
use HiPi::Interface::PCA9685;

our $VERSION ='0.65';

use Getopt::Long;

my $options = {
    panleft     => undef,
    panright    => undef,
    tiltup      => undef,
    tiltdown    => undef,
    pan         => undef,
    tilt        => undef,
    postion     => 0,
    delay       => 1000,
    centre      => 0,
    address     => 0x40,
    'external-clock' => 0,
};

GetOptions ( $options,
    'panleft|l:i',
    'panright|r:i',
    'tiltup|u:i',
    'tiltdown|d:i',
    'tilt|t:i',
    'pan|p:i',
    'position|n!',
    'delay|s:i',
    'centre|center|c!',
    'address|a:o',
    'external-clock:f'
);


my $pwm = HiPi::Interface::PCA9685->new(
    address        => $options->{address},
    external_clock => $options->{'external-clock'},
);

# same as inbuilt type PCA_9685_SERVOTYPE_SG90
my $servotype = $pwm->register_servotype(
    pulse_min         => 550,
    pulse_max         => 2350,
    degree_range      => 160,
    degree_min        => 15,
    degree_max        => 165,
);

my $tchan = 0;
my $pchan = 1;

my $tpos = $pwm->get_servo_degrees($tchan, $servotype);
my $ppos = $pwm->get_servo_degrees($pchan, $servotype);

if($options->{panleft}) {
    my $newpan = $ppos + $options->{panleft};
    do_pan( $newpan );
}

if($options->{panright}) {
    my $newpan = $ppos - $options->{panright};
    do_pan( $newpan );
}

if($options->{tiltup}) {
    my $newtilt = $tpos - $options->{tiltup};
    do_tilt( $newtilt );
}

if($options->{tiltdown}) {
    my $newtilt = $tpos + $options->{tiltdown};
    do_tilt( $newtilt );
}

if(defined($options->{pan})) {
    do_pan( $options->{pan} );
}

if(defined($options->{tilt})) {
    do_tilt( $options->{tilt} );
}

if($options->{centre}) {
    do_pan( 90 );
    do_tilt( 90 );
}

if($options->{position}) {
    # runs last - get the info again
    $tpos = $pwm->get_servo_degrees($tchan, $servotype);
    $ppos = $pwm->get_servo_degrees($pchan, $servotype);
    print qq(PCA9685 registers read: tilt $tpos, pan $ppos\n);
}

sub do_pan {
    my $pan = shift;
    $ppos = $pwm->set_servo_degrees($pchan, $servotype, $pan, $options->{delay});
}

sub do_tilt {
    my $tilt = shift;
    $tpos = $pwm->set_servo_degrees($tchan, $servotype, $tilt, $options->{delay});
}

1;
__END__