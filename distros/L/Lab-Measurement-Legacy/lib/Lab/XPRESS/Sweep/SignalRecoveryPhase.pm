package Lab::XPRESS::Sweep::SignalRecoveryPhase;
$Lab::XPRESS::Sweep::SignalRecoveryPhase::VERSION = '3.899';
#ABSTRACT: Signal recovery lock in phase sweep

use v5.20;

use Lab::XPRESS::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA = ('Lab::XPRESS::Sweep');

sub new {
    my $proto                  = shift;
    my @args                   = @_;
    my $class                  = ref($proto) || $proto;
    my $self->{default_config} = {
        id                  => 'Power_Sweep',
        filename_extension  => 'POW=',
        interval            => 1,
        points              => [],
        rate                => [1],
        mode                => 'step',
        allowed_instruments => ['Lab::Instrument::SignalRecovery726x'],
        allowed_sweep_modes => [ 'list', 'step' ],
        number_of_points    => [undef]
    };

    $self = $class->SUPER::new( $self->{default_config}, @args );
    bless( $self, $class );

    return $self;
}

sub go_to_sweep_start {
    my $self = shift;

    # go to start:
    $self->{config}->{instrument}
        ->set_refpha( { value => @{ $self->{config}->{points} }[0] } );
}

sub start_continuous_sweep {
    my $self = shift;

    return;

}

sub go_to_next_step {
    my $self = shift;

    $self->{config}->{instrument}->set_refpha(
        { value => @{ $self->{config}->{points} }[ $self->{iterator} ] } );

}

sub exit_loop {
    my $self = shift;

    if ( $self->{config}->{mode} =~ /step|list/ ) {
        if (
            not
            defined @{ $self->{config}->{points} }[ $self->{iterator} + 1 ] )
        {
            return 1;
        }
        else {
            return 0;
        }
    }
}

sub get_value {
    my $self = shift;
    return $self->{config}->{instrument}->get_refpha();
}

sub exit {
    my $self = shift;
    $self->{config}->{instrument}->abort();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Sweep::SignalRecoveryPhase - Signal recovery lock in phase sweep (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

	use Lab::XPRESS::hub;
	my $hub = new Lab::XPRESS::hub();
	
	
	my $lia = ...
	
	my $sweep_voltage = $hub->Sweep('SignalRecoveryPhase',
		{
		instrument => $lia,
		points => [0,10],
		stepwidth => [1],
		mode => 'step',		
		backsweep => 0 
		});

.

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

Parent: Lab::XPRESS::Sweep

The Lab::XPRESS::Sweep::SignalRecoveryPhase

=head1 CAVEATS/BUGS

probably none

=head1 SEE ALSO

=over 4

=item L<Lab::XPRESS::Sweep>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2021       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
