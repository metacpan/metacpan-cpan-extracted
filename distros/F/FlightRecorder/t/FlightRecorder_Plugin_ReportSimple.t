use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

FlightRecorder::Plugin::ReportSimple

=cut

=abstract

Simple FlightRecorder Report Generator

=cut

=includes

method: generate
method: output

=cut

=synopsis

  package main;

  use FlightRecorder;
  use FlightRecorder::Plugin::ReportSimple;

  my $f = FlightRecorder->new(auto => undef);
  my $r = FlightRecorder::Plugin::ReportSimple->new(flight_recorder => $f);

  $f->begin('main');
  $f->debug('something happened');
  $f->end;

  my $reporter = $r;

=cut

=libraries

Types::Standard

=cut

=inherits

FlightRecorder::Plugin::Report

=cut

=attributes

flight_recorder: ro, req, InstanceOf['FlightRecorder']
level: rw, opt, Enum[qw(debug info warn error fatal)]

=cut

=description

This package provides a mechanism for converting a L<FlightRecorder> event log
into a printable report.

=cut

=method generate

The generate method generates a simple report of activity captured by
L<FlightRecorder>.

=signature generate

generate() : Str

=example-1 generate

  # given: synopsis

  $r->generate

=cut

=method output

The output method generates a verbose report of activity captured by
L<FlightRecorder> and prints it to STDOUT.

=signature output

output() : Str

=example-1 output

  # given: synopsis

  $r->output

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('FlightRecorder::Plugin::ReportSimple');
  ok $result->isa('FlightRecorder::Plugin::Report');
  ok $result->flight_recorder;
  is $result->level, 'debug';

  $result
});

$subs->example(-1, 'generate', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  my $dow = qr/[a-zA-Z]{3,4}/;
  my $mon = qr/[a-zA-Z]{3,4}/;
  my $day = qr/\d{1,2}/;
  my $time = qr/\d{2}:\d{2}:\d{2}/;
  my $year = qr/\d{4}/;
  my $context = qr/\[\d{4}\]/;
  my $level = qr/\@debug/;
  my $string = qr/.*/;

  my $line1 = join qr/\s+/, (
    $dow,
    $mon,
    $day,
    $time,
    $year,
    $context,
    $level,
    $string
  );

  like $result, qr/$line1/;
});

ok 1 and done_testing;
