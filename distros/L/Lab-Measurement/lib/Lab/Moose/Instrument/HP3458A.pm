package Lab::Moose::Instrument::HP3458A;
$Lab::Moose::Instrument::HP3458A::VERSION = '3.682';
#ABSTRACT: HP 3458A digital multimeter

use 5.010;
use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common
);

sub BUILD {
    my $self = shift;
    $self->clear();    # FIXME: does this change any settings?!
    $self->set_end( value => 'ALWAYS' );
}


sub get_value {
    my ( $self, %args ) = validated_hash(
        \@_,
        setter_params(),
    );
    return $self->read(%args);
}


cache nplc => ( getter => 'get_nplc' );

sub get_nplc {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_nplc( $self->query( command => "NPLC?", %args ) );
}

sub set_nplc {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );
    $self->write( command => "NPLC $value", %args );
    $self->cached_nplc($value);
}

cache nrdgs        => ( getter => 'get_nrdgs' );
cache sample_event => ( getter => 'get_sample_event' );


sub get_nrdgs {
    my ( $self, %args ) = validated_getter( \@_ );
    my $result = $self->query( command => "NRDGS?", %args );
    my ( $points, $event ) = split( /,/, $result );
    $self->cached_nrdgs($points);
    $self->cached_sample_event($event);
    return $points;
}

sub set_nrdgs {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Int' },
    );
    my $sample_event = $self->cached_sample_event();
    $self->write( command => "NRDGS $value,$sample_event", %args );
    $self->cached_nrdgs($value);
}


sub get_sample_event {
    my ( $self, %args ) = validated_getter( \@_ );
    my $result = $self->query( command => "NRDGS?", %args );
    my ( $points, $event ) = split( /,/, $result );
    $self->cached_nrdgs($points);
    $self->cached_sample_event($event);
    return $event;
}

sub set_sample_event {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/AUTO EXTSYN SYN TIMER LEVEL LINE/] ) },
    );
    my $points = $self->cached_nrdgs();
    $self->write( command => "NRDGS $points,$value", %args );
    $self->cached_sample_event($value);
}


cache tarm_event => ( getter => 'get_tarm_event' );

sub get_tarm_event {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_tarm_event(
        $self->query( command => "TARM?", %args ) );
}

sub set_tarm_event {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/AUTO EXT SGL HOLD SYN/] ) },
    );
    $self->write( command => "TARM $value", %args );
    $self->cached_tarm_event($value);
}


cache trig_event => ( getter => 'get_trig_event' );

sub get_trig_event {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_trig_event(
        $self->query( command => "TRIG?", %args ) );
}

sub set_trig_event {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/AUTO EXT SGL HOLD SYN LEVEL LINE/] ) },
    );
    $self->write( command => "TRIG $value", %args );
    $self->cached_trig_event($value);
}


cache end => ( getter => 'get_end' );

sub get_end {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->cached_end( $self->query( command => "END?", %args ) );
}

sub set_end {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/OFF ON ALWAYS/] ) }
    );
    $self->write( command => "END $value" );
    $self->cached_trig_event($value);
}


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::HP3458A - HP 3458A digital multimeter

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $dmm = instrument(
     type => 'HP3458A',
     connection_type => 'LinuxGPIB',
     connection_options => {
         gpib_address => 12,
         timeout => 10, # if not given, use connection's default timeout
     }
 );

 $dmm->set_sample_event(value => 'SYN');
 $dmm->set_nplc(value => 2);
 
 my $value = $dmm->get_value();

=head1 METHODS

=head2 get_value

 my $value = $dmm->get_value();

Read multimeter output value.

=head2 get_nplc/set_nplc

 $dmm->set_nplc(value => 10);
 $nplc = $dmm->get_nplc();

Get/Set integration time in Number of Power Line Cycles.

=head2 get_nrdgs/set_nrdgs

 $dmm->set_nrdgs(value => 2);
 $nrdgs = $dmm->get_nrdgs();

Get/Set number of readings taken per trigger/sample event.

=head2 get_sample_event/set_sample_event

 $dmm->set_sample_event(value => 'SYN');
 $sample_event = $dmm->get_sample_event();

Get/Set sample event.

=head2 get_tarm_event/set_tarm_event

 $dmm->set_tarm_event(value => 'EXT');
 $tarm_event = $dmm->get_tarm_event();

Get/Set trigger arm event.

=head2 get_trig_event/set_trig_event

 $dmm->set_trig_event(value => 'EXT');
 $trig_event = $dmm->get_trig_event();

Get/Set trigger event.

=head2 get_end/set_end

 $dmm->set_end(value => 'ALWAYS');
 $end = $dmm->get_end();

Get/Set control of GPIB End Or Identify (EOI) function.
This driver sets this to 'ALWAYS' on startup.

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
