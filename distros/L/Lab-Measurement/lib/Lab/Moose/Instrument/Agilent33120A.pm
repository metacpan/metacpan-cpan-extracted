package Lab::Moose::Instrument::Agilent33120A;
$Lab::Moose::Instrument::Agilent33120A::VERSION = '3.910';
#ABSTRACT: Agilent 33120A 15MHz arbitrary waveform generator

use v5.20;


use Moose;
use namespace::autoclean;

extends 'Lab::Moose::Instrument::HP33120A';

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Agilent33120A - Agilent 33120A 15MHz arbitrary waveform generator

=head1 VERSION

version 3.910

=head1 DESCRIPTION

Alias for L<Lab::Moose::Instrument::HP33120A>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by the Lab::Measurement team; in detail:

  Copyright 2023       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
