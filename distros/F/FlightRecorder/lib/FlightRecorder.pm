package FlightRecorder;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

with 'Data::Object::Role::Pluggable';
with 'Data::Object::Role::Throwable';

our $VERSION = '0.06'; # VERSION

# ATTRIBUTES

has 'auto' => (
  is => 'ro',
  isa => 'Maybe[FileHandle]',
  def => sub{\*STDOUT},
);

has 'head' => (
  is => 'ro',
  isa => 'Str',
  opt => 1,
);

has 'item' => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1,
);

has 'refs' => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1,
  new => 1
);

fun new_refs($self) {
  {}
}

has 'logs' => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  opt => 1,
  new => 1
);

fun new_logs($self) {
  []
}

has level => (
  is => 'rw',
  isa => 'Enum[qw(debug info warn error fatal)]',
  def => 'debug'
);

has 'format' => (
  is => 'rw',
  isa => 'Str',
  opt => 1,
  def => '{head_timestamp} [{head}] @{head_level} {head_message}'
);

has 'zeros' => (
  is => 'ro',
  isa => 'Int',
  opt => 1,
  def => 4
);

# METHODS

method begin(Str $name) {
  $self->context($name);
  $self->message('debug', join(' ', $self->name, 'began'), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method branch(Str $name) {
  my $class = ref $self;
  my $data = $self->serialize;

  $self = $class->new($data);

  $self->context($name);
  $self->message('debug', join(' ', $self->name, 'began'), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method context(Str $name) {
  my $head = $self->next_refs;

  $self->refs->{$head} = $name;
  $self->{head} = $head;

  return $self;
}

method data(HashRef[Str] $data) {
  my $item = $self->item;

  push @{$item->{data}}, $data;

  return $self;
}

method debug(Str @messages) {
  $self->message('debug', join(' ', @messages), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method end() {
  $self->message('debug', join(' ', $self->name, 'ended'), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method error(Str @messages) {
  $self->message('error', join(' ', @messages), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method fatal(Str @messages) {
  $self->message('fatal', join(' ', @messages), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method head_file() {
  my $item = $self->item;

  return $item->{file};
}

method head_line() {
  my $item = $self->item;

  return $item->{line};
}

method head_name() {
  my $item = $self->item;

  return $item->{name};
}

method head_context() {
  my $item = $self->item;

  return $item->{context};
}

method head_process() {
  my $item = $self->item;

  return $item->{process};
}

method head_package() {
  my $item = $self->item;

  return $item->{package};
}

method head_version() {
  my $item = $self->item;

  return $item->{version};
}

method head_subroutine() {
  my $item = $self->item;

  return $item->{subroutine};
}

method head_timestamp() {
  my $item = $self->item;
  my $time = $item->{timestamp};

  return scalar(localtime($time));
}

method head_message() {
  my $item = $self->item;

  return $item->{message};
}

method head_level() {
  my $item = $self->item;

  return $item->{level};
}

method info(Str @messages) {
  $self->message('info', join(' ', @messages), [1,2]);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method initialize(Tuple[Int, Int] $frames) {
  my $index = ($$frames[0] == 0 && $$frames[1] == 1) ? [2,3] : [3,4];

  $self->context('main');
  $self->message('debug', join(' ', $self->name, 'began'), $index);

  $self->output($self->auto) if $self->auto;

  return $self;
}

method levels() {
  my @levels = qw(debug info warn error fatal);
  my %levels = map +($levels[$_], $_), 0..$#levels;

  return {%levels};
}

method loggable(Str $target_level) {
  my $levels = $self->levels;

  my $loggable_level = $self->level;

  return int($$levels{$target_level} >= $$levels{$loggable_level});
}

method logline() {
  my $item = $self->item;
  my $format = $self->format;
  my @tokens = $format =~ m/\{(\w+)\}/g;

  $format =~ s/\{$_\}/$self->token($_)/ge for @tokens;

  return $format;
}

method message(Str $level, Str $message, Tuple[Int, Int] $frames = [0,1]) {
  my $process = $$;
  my $caller = [caller($$frames[0])];
  my $file = $caller->[1];
  my $line = $caller->[2];
  my $context = $self->head || $self->initialize($frames)->head;
  my $package = $caller->[0];
  my $subroutine = (caller($$frames[1]))[3];
  my $timestamp = time;
  my $version = $caller->[0] ? $caller->[0]->VERSION : undef;
  my $name = $self->name;

  my $entry = {
    context => $context,
    data => [],
    file => $file,
    level => $level,
    line => $line,
    message => $message,
    name => $name,
    package => $package,
    process => $process,
    subroutine => $subroutine,
    timestamp => $timestamp,
    version => $version
  };

  push @{$self->{logs}}, $entry;

  $self->{item} = $entry;

  return $self;
}

method name() {
  my $head = $self->head;

  return $self->refs->{$head};
}

method next_name() {

  return $self->next_from_logs($self->logs);
}

method next_refs() {

  return $self->next_from_hash($self->refs);
}

method next_from_hash(HashRef $hash) {
  my $zeros = $self->zeros;

  return sprintf "%0${zeros}d", (keys %$hash) + 1;
}

method next_from_logs(ArrayRef $logs) {
  my $zeros = $self->zeros;

  return sprintf "%0${zeros}d", (@$logs) + 1;
}

method output(FileHandle $handle = \*STDOUT) {
  my $logline = $self->logline;

  print $handle $logline, "\n" if $self->loggable($self->head_level);

  return $logline;
}

method report(Str $name, Str $level = $self->level) {
  my %args = (level => $level, flight_recorder => $self);

  return $self->plugin("report_$name" => (%args));
}

method serialize() {
  my $data = {};

  $data->{head} = $self->head;
  $data->{level} = $self->level;
  $data->{logs} = $self->logs;
  $data->{refs} = $self->refs;
  $data->{zeros} = $self->zeros;

  return $data;
}

method succinct(Str $level = $self->level) {

  return $self->report('succinct', $level);
}

method switch(Str $name) {
  my $context = {reverse %{$self->refs}}->{$name};
  my $selected = [grep {$$_{context} eq $context} @{$self->logs}];

  if (@$selected) {
    $self->{head} = $context;
    $self->{item} = $selected->[-1];
  }

  return $self;
}

method token(Str $name) {
  my $item = $self->item;

  return $self->$name if $self->can($name);

  return "{$name}";
}

method verbose(Str $level = $self->level) {

  return $self->report('verbose', $level);
}

method warn(Str @messages) {
  $self->message('warn', join(' ', @messages), [1,2]);

  return $self;
}

1;

=encoding utf8

=head1 NAME

FlightRecorder

=cut

=head1 ABSTRACT

Logging for Distributed Systems

=cut

=head1 SYNOPSIS

  package main;

  use FlightRecorder;

  my $f = FlightRecorder->new(
    auto => undef
  );

  # $f->begin('try');
  # $f->debug('something happend');
  # $f->end;

=cut

=head1 DESCRIPTION

This package provides a simple mechanism for logging events with context,
serializing and distributing the event logs, and producing a transcript of
activity to provide insight into the behavior of distributed systems.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Pluggable>

L<Data::Object::Role::Throwable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 auto

  auto(Maybe[FileHandle])

This attribute is read-only, accepts C<(Maybe[FileHandle])> values, and is optional.

=cut

=head2 format

  format(Str)

This attribute is read-write, accepts C<(Str)> values, and is optional.

=cut

=head2 head

  head(Str)

This attribute is read-write, accepts C<(Str)> values, and is optional.

=cut

=head2 item

  item(HashRef)

This attribute is read-only, accepts C<(HashRef)> values, and is optional.

=cut

=head2 level

  level(Enum[qw(debug info warn error fatal)])

This attribute is read-only, accepts C<(Enum[qw(debug info warn error fatal)])> values, and is optional.

=cut

=head2 logs

  logs(ArrayRef[HashRef])

This attribute is read-only, accepts C<(ArrayRef[HashRef])> values, and is optional.

=cut

=head2 refs

  refs(HashRef)

This attribute is read-only, accepts C<(HashRef)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 begin

  begin(Str $label) : Object

The begin method creates and logs a new context.

=over 4

=item begin example #1

  # given: synopsis

  $f->begin('test')

=back

=cut

=head2 branch

  branch(Str $label) : Object

The branch method creates and returns a new L<FlightRecorder> object which
shares the event log with the parent object. This method creates a new context
when called.

=over 4

=item branch example #1

  # given: synopsis

  $f->begin('test')->branch('next')

=back

=cut

=head2 data

  data(HashRef[Str] $data) : Object

The data method associates arbitrary metadata with the last event.

=over 4

=item data example #1

  # given: synopsis

  $f->debug('something happened')->data({
    error => 'unknown at ./example line 10'
  });

=back

=cut

=head2 debug

  debug(Str @message) : Object

The debug method logs a C<debug> level event with context.

=over 4

=item debug example #1

  # given: synopsis

  $f->debug('something happened')

=back

=cut

=head2 end

  end() : Object

The end method logs the end of the current context.

=over 4

=item end example #1

  # given: synopsis

  $f->begin('main')->end

=back

=cut

=head2 error

  error(Str @message) : Object

The error method logs an C<error> level event with context.

=over 4

=item error example #1

  # given: synopsis

  $f->error('something happened')

=back

=cut

=head2 fatal

  fatal(Str @message) : Object

The fatal method logs a C<fatal> level event with context.

=over 4

=item fatal example #1

  # given: synopsis

  $f->fatal('something happened')

=back

=cut

=head2 info

  info(Str @message) : Object

The info method logs an C<info> level event with context.

=over 4

=item info example #1

  # given: synopsis

  $f->info('something happened')

=back

=cut

=head2 output

  output(FileHandle $handle) : Str

The output method outputs the last event using the format defined in the
C<format> attribute. This method is called automatically after each log-event
if the C<auto> attribute is set, which is by default set to C<STDOUT>.

=over 4

=item output example #1

  # given: synopsis

  $f->begin('test')->output

=back

=over 4

=item output example #2

  package main;

  use FlightRecorder;

  my $f = FlightRecorder->new;

  $f->begin('try');

  # $f->output

  $f->debug('something happened');

  # $f->output

  $f->end;

  # $f->output

=back

=cut

=head2 report

  report(Str $name, Str $level) : Object

The report method loads and returns the specified report plugin.

=over 4

=item report example #1

  # given: synopsis

  $f->report('verbose')

=back

=over 4

=item report example #2

  # given: synopsis

  $f->report('succinct', 'fatal')

=back

=cut

=head2 serialize

  serialize() : HashRef

The serialize method normalizes and serializes the event log and returns it as
a C<hashref>.

=over 4

=item serialize example #1

  # given: synopsis

  $f->begin('main')->serialize

=back

=cut

=head2 succinct

  succinct() : Object

The succinct method loads and returns the
L<FlightRecorder::Plugin::ReportSuccinct> report plugin.

=over 4

=item succinct example #1

  # given: synopsis

  $f->succinct

=back

=cut

=head2 switch

  switch(Str $name) : Object

The switch method finds and sets the current context based on the name
provided.

=over 4

=item switch example #1

  # given: synopsis

  $f->begin('main')->begin('test')->switch('main')

=back

=cut

=head2 verbose

  verbose() : Object

The verbose method loads and returns the
L<FlightRecorder::Plugin::ReportVerbose> report plugin.

=over 4

=item verbose example #1

  # given: synopsis

  $f->verbose

=back

=cut

=head2 warn

  warn(Str @message) : Object

The warn method logs a C<warn> level event with context.

=over 4

=item warn example #1

  # given: synopsis

  $f->warn('something happened')

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
