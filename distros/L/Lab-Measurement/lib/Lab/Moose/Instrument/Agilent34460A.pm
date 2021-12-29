package Lab::Moose::Instrument::Agilent34460A;
$Lab::Moose::Instrument::Agilent34460A::VERSION = '3.802';
#ABSTRACT: Agilent 34460A TrueVolt series digital multimeter.

use v5.20;


use warnings;
use strict;

use Moose;

extends 'Lab::Moose::Instrument::HP34410A';

# this still needs a bit of research
#
#around default_connection_options => sub {
#    my $orig     = shift;
#    my $self     = shift;
#    my $options  = $self->$orig();
#    my $usb_opts = { vid => 0x2a8d, pid => 0x0201 };
#    $options->{USB} = $usb_opts;
#    $options->{'VISA::USB'} = $usb_opts;
#    return $options;
#};

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Agilent34460A - Agilent 34460A TrueVolt series digital multimeter.

=head1 VERSION

version 3.802

=head1 DESCRIPTION

Inherits from L<Lab::Moose::Instrument::HP34410A>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
