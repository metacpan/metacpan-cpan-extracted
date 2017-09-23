package Lab::Moose::Connection::USB;
$Lab::Moose::Connection::USB::VERSION = '3.600';
#ABSTRACT: Connection backend to USB Test & Measurement (USBTMC) bus

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Carp;

use Lab::Moose::Instrument qw/timeout_param read_length_param/;
use USB::TMC;
use namespace::autoclean;

has usbtmc => (
    is       => 'ro',
    isa      => 'USB::TMC',
    writer   => '_usbtmc',
    init_arg => undef,
);

has vid => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has pid => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has serial => (
    is  => 'ro',
    isa => 'Str',
);

has debug_mode => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has write_termchar => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    default => "\n",
);

sub BUILD {
    my $self   = shift;
    my $serial = $self->serial();

    my $usbtmc = USB::TMC->new(
        vid => $self->vid(),
        pid => $self->pid(),
        defined($serial) ? ( serial => $serial ) : (),
        debug_mode => $self->debug_mode(),
    );
    $self->_usbtmc($usbtmc);
}

sub Write {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param,
        command => { isa => 'Str' },
    );

    my $write_termchar = $self->write_termchar() // '';
    my $command        = $args{command} . $write_termchar;
    my $timeout        = $self->_timeout_arg(%args);
    my $usbtmc         = $self->usbtmc();
    $usbtmc->write( data => $command, timeout => $timeout );
}

sub Read {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        read_length_param(),
    );
    my $timeout     = $self->_timeout_arg(%args);
    my $read_length = $self->_read_length_arg(%args);

    my $usbtmc = $self->usbtmc();

    return $usbtmc->read( length => $read_length, timeout => $timeout );
}

sub Clear {
    my ( $self, %args ) = validated_hash( \@_, timeout_param );
    my $timeout = $self->_timeout_arg(%args);
    $self->usbtmc()->clear( timeout => $timeout );
}

with qw/
    Lab::Moose::Connection
    /;

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection::USB - Connection backend to USB Test & Measurement (USBTMC) bus

=head1 VERSION

version 3.600

=head1 SYNOPSIS

 use Lab::Moose;

 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'USB',
     connection_options => {
         vid => 0x0957,
         pid => 0x0607,
         serial => MY47000419', # only needed if vid/pid is ambiguous
     }
 );

=head1 DESCRIPTION

Connection backend based on L<USB::TMC>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
