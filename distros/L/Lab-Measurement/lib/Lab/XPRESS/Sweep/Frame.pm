package Lab::XPRESS::Sweep::Frame;
#ABSTRACT: Frames for nested sweep structures
$Lab::XPRESS::Sweep::Frame::VERSION = '3.881';
use v5.20;

use Time::HiRes qw/usleep/, qw/time/;
use strict;
use Lab::Exception;
use Lab::Generic;

our @ISA = ('Lab::Generic');

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    bless( $self, $class );

    $self->{slave_counter} = 0;
    $self->{slaves}        = ();

    return $self;
}

sub start {
    my $self = shift;

    if ( not defined $self->{master} ) {
        Lab::Exception::Warning->throw( error => "no master defined" );
    }
    else {
        $self->{master}->start();
    }

}

sub abort {
    my $self = shift;

    if ( defined $self->{master} ) {
        $self->{master}->abort();
    }
}

sub pause {
    return shift;
}

sub add_master {
    my $self = shift;
    $self->{master} = shift;

    my $type = ref( $self->{master} );
    if ( not $type =~ /^Lab::XPRESS::Sweep/ ) {
        Lab::Exception::Warning->throw(
            error => "Master is not of type Lab::XPRESS::Sweep . " );
    }
    return $self;
}

sub add_slave {
    my $self  = shift;
    my $slave = shift;

    if ( not defined $self->{master} ) {
        Lab::Exception::Warning->throw(
            error => "no master defined when called add_slave()." );
    }

    $self->{master}->add_slave($slave);

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Sweep::Frame - Frames for nested sweep structures

=head1 VERSION

version 3.881

=head1 SYNOPSIS

	use Lab::XPRESS::hub;
	my $hub = new Lab::XPRESS::hub();
	
	my $frame = $hub->Frame();
	
	$frame->add_master($sweep_0);
	
	$frame->add_slave($sweep_1);
	$frame->add_slave($sweep_2);
	$frame->add_slave($sweep_3);
	
	$frame->start();

.

=head1 DESCRIPTION

Parent: Lab::XPRESS::Sweep

The Lab::XPRESS::Sweep::Frame class implements a module to organize a nested sweep structure in the Lab::XPRESS::Sweep framework.

The Frame object has no parameters.
.

=head1 CONSTRUCTOR

	my $frame = $hub->Frame();

Instantiates a new Frame object.

.

=head1 METHODS

=head2 add_master

	$frame->add_master($sweep);

use this methode to add a master sweep to the frame object. A Frame accepts only a single master sweep.

.

=head2 add_slave

	$frame->add_slave($sweep);

use this methode to add a slave sweep to the frame object. A Frame can have several slave sweeps.

The order in which the slave sweeps are added to the frame object, defines the sequence in which the individual slave sweeps will be executed.

	$frame->add_slave($sweep_1);
	$frame->add_slave($sweep_2);
	$frame->add_slave($sweep_3);

The frame object accepts also another frame object as a slave sweep. This way you can build up a multi level nested sweep structure.

	my $inner_frame = $hub->Frame();
	my $outer_frame = $hub->Frame();
	
	$inner_frame->add_master($sweep_0);
	
	$inner_frame->add_slave($sweep_1);
	$inner_frame->add_slave($sweep_2);
	$inner_frame->add_slave($sweep_3);
	
	
	$outer_frame->add_master($sweep_10);
	
	$outer_frame->add_slave($sweep_11);
	$outer_frame->add_slave($inner_frame);
	$outer_frame->add_slave($sweep_11);
	
	
	$outer_frame->start();

.

=head2 start

	$frame->start();

use this methode to execute the nested sweeps.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Stefan Geissler
            2013       Andreas K. Huettel, Christian Butschkow, Stefan Geissler
            2014       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
