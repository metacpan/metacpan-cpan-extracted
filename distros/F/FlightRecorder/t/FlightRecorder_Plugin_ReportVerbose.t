use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

FlightRecorder::Plugin::ReportVerbose

=cut

=abstract

Verbose FlightRecorder Report Generator

=cut

=includes

method: generate

=cut

=synopsis

  package main;

  use FlightRecorder;
  use FlightRecorder::Plugin::ReportVerbose;

  my $f = FlightRecorder->new;
  my $r = FlightRecorder::Plugin::ReportVerbose->new(flight_recorder => $f);

  $f->begin('main');
  $f->debug('something happened');
  $f->end;

  my $reporter = $r;

=cut

=attributes

level: rw, opt, Enum[qw(debug info warn error fatal)]
flight_recorder: ro, req, InstanceOf['FlightRecorder']

=cut

=inherits

FlightRecorder::Plugin::Report

=cut

=description

This package provides a mechanism for converting a L<FlightRecorder> event log
into a human-readable report.

=cut

=method generate

The generate method generates a verbose report of activity captured by
L<FlightRecorder>.

=signature generate

generate() : Str

=example-1 generate

  # given: synopsis

  $r->generate

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('FlightRecorder::Plugin::ReportVerbose');
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
  my $process = qr/\[\d+\]/;
  my $begin = qr/BEGIN/;

  my $line1 = join ' ', (
    $dow,
    $mon,
    $day,
    $time,
    $year,
    $context,
    $level,
    $process,
    $begin
  );

  like $result, qr/$line1/;
  like $result, qr/In \(eval \d+\) at line #\d+/;

  like $result,
    qr/\{\n\s\scontext: 'main',\n\s\smessage: 'main began'\n\}/;
  like $result,
    qr/\{\n\s\scontext: 'main',\n\s\smessage: 'something happened'\n\}/;
  like $result,
    qr/\{\n\s\scontext: 'main',\n\s\smessage: 'main ended'\n\}/;

  like $result, qr/package: 'main'/;
  like $result, qr/process: \d+/;
  like $result, qr/subroutine: '\(eval\)'/;
  like $result, qr/timestamp: \d+/;
  like $result, qr/version: 'no-version'/;

  $result
});

ok 1 and done_testing;
