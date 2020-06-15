package FlightRecorder::Plugin::ReportVerbose;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;

extends 'FlightRecorder::Plugin::Report';

our $VERSION = '0.08'; # VERSION

# METHODS

method format() {
  my @template;

  push @template, '{item_timestamp}';
  push @template, '[{item_context}]';
  push @template, '@{item_level}';
  push @template, '[{item_process}]';
  push @template, "BEGIN\n\n{item_report}\n\nEND\n";

  return join ' ', @template;
}

method item_report(HashRef $item) {
  my @info;

  my $file = $self->item_file($item);
  my $line = $self->item_line($item);

  push @info, "In $file at line #$line", "";

  push @info, $self->item_dump({
    context => $self->item_name($item),
    message => $self->item_message($item)
  });

  push @info, $self->item_dump({
    package => $self->item_package($item),
    process => $self->item_process($item),
    subroutine => $self->item_subroutine($item),
    version => $self->item_version($item),
    timestamp => $item->{timestamp}
  });

  for my $include (@{$item->{data}}) {
    push @info, $self->item_dump($include);
  }

  my $report = join "\n", @info;

  chomp $report;

  return $report;
}

1;

=encoding utf8

=head1 NAME

FlightRecorder::Plugin::ReportVerbose

=cut

=head1 ABSTRACT

Verbose FlightRecorder Report Generator

=cut

=head1 SYNOPSIS

  package main;

  use FlightRecorder;
  use FlightRecorder::Plugin::ReportVerbose;

  my $f = FlightRecorder->new(auto => undef);
  my $r = FlightRecorder::Plugin::ReportVerbose->new(flight_recorder => $f);

  $f->begin('main');
  $f->debug('something happened');
  $f->end;

  my $reporter = $r;

=cut

=head1 DESCRIPTION

This package provides a mechanism for converting a L<FlightRecorder> event log
into a human-readable report.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<FlightRecorder::Plugin::Report>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 flight_recorder

  flight_recorder(InstanceOf['FlightRecorder'])

This attribute is read-only, accepts C<(InstanceOf['FlightRecorder'])> values, and is required.

=cut

=head2 level

  level(Enum[qw(debug info warn error fatal)])

This attribute is read-write, accepts C<(Enum[qw(debug info warn error fatal)])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 generate

  generate() : Str

The generate method generates a verbose report of activity captured by
L<FlightRecorder>.

=over 4

=item generate example #1

  # given: synopsis

  $r->generate

=back

=cut

=head2 output

  output() : Str

The output method generates a verbose report of activity captured by
L<FlightRecorder> and prints it to STDOUT.

=over 4

=item output example #1

  # given: synopsis

  $r->output

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/flight-recorder/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/flight-recorder/wiki>

L<Project|https://github.com/iamalnewkirk/flight-recorder>

L<Initiatives|https://github.com/iamalnewkirk/flight-recorder/projects>

L<Milestones|https://github.com/iamalnewkirk/flight-recorder/milestones>

L<Contributing|https://github.com/iamalnewkirk/flight-recorder/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/flight-recorder/issues>

=cut
