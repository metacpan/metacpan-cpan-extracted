package Lab::XPRESS::Sweep::DietersCrazyTempSweep;
#ABSTRACT: Dieter's crazy temperature sweep
$Lab::XPRESS::Sweep::DietersCrazyTempSweep::VERSION = '3.899';
use v5.20;

use Lab::XPRESS::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA = ('Lab::XPRESS::Sweep');

sub new {
    my $proto = shift;
    my @args  = @_;
    my $class = ref($proto) || $proto;

    # define default values for the config parameters:
    my $self->{default_config} = {
        id                  => 'Time_sweep',
        interval            => 1,
        points              => [ 0, 10 ],
        duration            => [1],
        stepwidth           => 1,
        mode                => 'continuous',
        allowed_instruments => ['Lab::Instrument::ITC'],
        allowed_sweep_modes => ['continuous'],
    };

    # create self from Sweep basic class:
    $self = $class->SUPER::new( $self->{default_config}, @args );
    bless( $self, $class );

    # check and adjust config values if necessary:
    $self->check_config_paramters();

    # init mandatory parameters:
    $self->{DataFile_counter} = 0;
    $self->{DataFiles}        = ();

    return $self;
}

sub check_config_paramters {
    my $self = shift;

    # No Backsweep allowed; adjust number of Repetitions if Backsweep is 1:
    if ( $self->{config}->{backsweep} == 1 ) {
        $self->{config}->{repetitions} /= 2;
        $self->{config}->{backsweep} = 0;
    }

    # Set loop-Interval to Measurement-Interval:
    $self->{loop}->{interval} = $self->{config}->{interval};

}

sub exit_loop {
    my $self = shift;

    my $T_Probe = $self->{config}->{instrument}->get_value(3);

    if ( $self->{sequence} == 0 ) {

        if ( $T_Probe >= @{ $self->{config}->{points} }[1] ) {
            $self->{config}->{instrument}->set_heateroutput(0);
            $self->{sequence}++;
            foreach my $file ( @{ $self->{DataFiles} } ) {
                $file->start_block();
            }
            $self->skip_LOG();
        }
        elsif ( $T_Probe < 15 ) {
            $self->{config}->{instrument}->set_heateroutput(33)
                ;    # 0..99% of heaterlimit
        }
        elsif ( $T_Probe >= 15 and $T_Probe <= 40 ) {
            $self->{config}->{instrument}->set_heateroutput(56)
                ;    # 0..99% of heaterlimit
        }
        elsif ( $T_Probe > 40 ) {
            $self->{config}->{instrument}->set_heateroutput(70)
                ;    # 0..99% of heaterlimit
        }

    }
    elsif ( $self->{sequence} == 1 ) {
        if ( $T_Probe > @{ $self->{config}->{points} }[1] ) {
            $self->skip_LOG();
        }
        elsif ( $T_Probe <= @{ $self->{config}->{points} }[0] ) {
            return 1;
        }
    }

    return 0;

}

sub get_value {
    my $self = shift;
    return $self->{config}->{instrument}->get_value(3);
}

sub halt {
    return shift;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Sweep::DietersCrazyTempSweep - Dieter's crazy temperature sweep (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Andreas K. Huettel, Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
