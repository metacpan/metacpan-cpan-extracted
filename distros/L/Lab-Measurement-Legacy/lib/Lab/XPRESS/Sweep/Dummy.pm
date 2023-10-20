package Lab::XPRESS::Sweep::Dummy;
#ABSTRACT: Dummy sweep
$Lab::XPRESS::Sweep::Dummy::VERSION = '3.899';
use v5.20;

use Lab::XPRESS::Sweep;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA = ('Lab::XPRESS::Sweep');

sub new {
    my $proto = shift;
    my $code  = shift;
    my @args  = @_;
    my $class = ref($proto) || $proto;
    my $self->{default_config} = { id => 'Dummy_sweep' };
    $self = $class->SUPER::new(
        $self->{default_config},
        $self->{default_config}
    );
    bless( $self, $class );

    $self->{code} = $code;

    return $self;
}

sub start {
    my $self = shift;
    return $self->{code}->($self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Sweep::Dummy - Dummy sweep (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Stefan Geissler
            2013       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
