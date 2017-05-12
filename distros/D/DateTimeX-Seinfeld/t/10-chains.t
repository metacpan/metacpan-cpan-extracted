#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-chains.t
# Copyright 2012 Christopher J. Madsen
#
# Test calculation of Seinfeld chain length
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Test::More 0.88 tests => 10;

use DateTimeX::Seinfeld ();

#---------------------------------------------------------------------
sub dt # Trivial parser to create DateTime objects
{
  my %dt = qw(time_zone UTC);
  @dt{qw( year month day hour minute second )} = split /\D+/, $_[0];
  while (my ($k, $v) = each %dt) { delete $dt{$k} unless defined $v }
  DateTime->new(\%dt);
} # end dt

#---------------------------------------------------------------------
sub test
{
  my $name     = (ref($_[0]) ? undef : shift);
  my $args     = shift;
  my $chains   = (ref($_[0]) eq 'HASH' ? shift : undef);
  my $dates    = shift;
  my $expected = shift;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my %args;
  @args{qw(start_date increment skip)} = @$args;

  while (my ($k, $v) = each %args) { delete $args{$k} unless defined $v }

  $args{start_date} = dt($args{start_date});

  my $seinfeld = DateTimeX::Seinfeld->new( \%args );

  $_ = dt($_) for @$dates;
  my $got = $seinfeld->find_chains($dates, $chains);

  unless (is_deeply($got, $expected, $name)) {
    diag("Full result:\n");
    for my $type (qw(longest last)) {
      diag(sprintf "   %-7s => {\n", $type);
      my $entry = $got->{$type};

      for my $key (qw(start_period end_period start_event end_event
                      length num_events)) {
        my $value = $entry->{$key} // next;
        if (ref $value) {
          $value = $value->ymd . ' ' . $value->hms;
          $value =~ s/:00$//;
          $value =~ s/ 00:00$//;
          $value = "dt('$value')";
        }
        diag(sprintf "     %-12s => %s,\n", $key, $value);
      } # end for $key
      diag("   },\n");
    } # end for $type

    for my $key (qw(marked_periods total_periods)) {
      diag(sprintf "   %-14s => %d,\n", $key, $got->{$key});
    }
  } # end unless test successful
} # end test

#---------------------------------------------------------------------
sub both
{
  my ($info) = @_;

  return (longest => $info, last => $info);
} # end both

#---------------------------------------------------------------------

test(['2012-01-01', { weeks => 1 }],
 [qw(
   2012-01-02
   2012-01-10
   2012-01-18
   2012-01-26
   2012-02-03
   2012-02-11
   2012-02-19
   2012-02-27
   2012-03-06
   2012-03-14
   2012-03-22
   2012-03-30
 )],
 {
   longest => {
     start_period => dt('2012-01-01'),
     end_period   => dt('2012-02-12'),
     start_event  => dt('2012-01-02'),
     end_event    => dt('2012-02-11'),
     length       => 6,
     num_events   => 6,
   },
   last    => {
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-01'),
     start_event  => dt('2012-02-19'),
     end_event    => dt('2012-03-30'),
     length       => 6,
     num_events   => 6,
   },
   marked_periods => 12,
   total_periods  => 13,
 }
);

#---------------------------------------------------------------------
test('continue search',
 ['2012-01-01', { weeks => 1 }],
 {
   longest => {
     start_period => dt('2012-01-01'),
     end_period   => dt('2012-02-12'),
     start_event  => dt('2012-01-02'),
     end_event    => dt('2012-02-11'),
     length       => 6,
     num_events   => 6,
   },
   last    => {
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-01'),
     start_event  => dt('2012-02-19'),
     end_event    => dt('2012-03-30'),
     length       => 6,
     num_events   => 6,
   },
   marked_periods => 12,
   total_periods  => 13,
 },
 [qw(
   2012-04-07
 )],
 {
   both({
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-08'),
     start_event  => dt('2012-02-19'),
     end_event    => dt('2012-04-07'),
     length       => 7,
     num_events   => 7,
   }),
   marked_periods => 13,
   total_periods  => 14,
 }
);

#---------------------------------------------------------------------
test('continue with incomplete data',
 ['2012-01-01', { weeks => 1 }],
 {
   longest => {
     start_period => dt('2012-01-01'),
     length       => 6,
   },
   last    => {
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-01'),
     length       => 6,
   },
 },
 [qw(
   2012-04-07
 )],
 {
   both({
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-08'),
     end_event    => dt('2012-04-07'),
     length       => 7,
     num_events   => 1,
   }),
   marked_periods => 1,
   total_periods  => 1,
 }
);

#---------------------------------------------------------------------
test('continue with overlap',
 ['2012-01-01', { weeks => 1 }],
 {
   longest => {
     start_period => dt('2012-01-01'),
     end_period   => dt('2012-02-12'),
     start_event  => dt('2012-01-02'),
     end_event    => dt('2012-02-11'),
     length       => 6,
     num_events   => 6,
   },
   last    => {
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-01'),
     start_event  => dt('2012-02-19'),
     end_event    => dt('2012-03-30'),
     length       => 6,
     num_events   => 6,
   },
   marked_periods => 12,
   total_periods  => 13,
 },
 [qw(
   2012-03-31
   2012-04-07
   2012-04-10
   2012-04-16
 )],
 {
   both({
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-22'),
     start_event  => dt('2012-02-19'),
     end_event    => dt('2012-04-16'),
     length       =>  9,
     num_events   => 10,
   }),
   marked_periods => 15,
   total_periods  => 16,
 }
);

#---------------------------------------------------------------------
test('continue from empty results',
 ['2012-01-01', { weeks => 1 }],
 {
   marked_periods => 0,
   total_periods  => 0,
 },
 [qw(
   2012-01-02
   2012-01-10
   2012-01-18
   2012-01-26
   2012-02-03
   2012-02-11
   2012-02-19
   2012-02-27
   2012-03-06
   2012-03-14
   2012-03-22
   2012-03-30
 )],
 {
   longest => {
     start_period => dt('2012-01-01'),
     end_period   => dt('2012-02-12'),
     start_event  => dt('2012-01-02'),
     end_event    => dt('2012-02-11'),
     length       => 6,
     num_events   => 6,
   },
   last    => {
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-01'),
     start_event  => dt('2012-02-19'),
     end_event    => dt('2012-03-30'),
     length       => 6,
     num_events   => 6,
   },
   marked_periods => 12,
   total_periods  => 13,
 }
);

#---------------------------------------------------------------------
test('continue from empty hash',
 ['2012-01-01', { weeks => 1 }],
 {},
 [qw(
   2012-01-02
   2012-01-10
   2012-01-18
   2012-01-26
   2012-02-03
   2012-02-11
   2012-02-19
   2012-02-27
   2012-03-06
   2012-03-14
   2012-03-22
   2012-03-30
 )],
 {
   longest => {
     start_period => dt('2012-01-01'),
     end_period   => dt('2012-02-12'),
     start_event  => dt('2012-01-02'),
     end_event    => dt('2012-02-11'),
     length       => 6,
     num_events   => 6,
   },
   last    => {
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-01'),
     start_event  => dt('2012-02-19'),
     end_event    => dt('2012-03-30'),
     length       => 6,
     num_events   => 6,
   },
   marked_periods => 12,
   total_periods  => 13,
 }
);

#---------------------------------------------------------------------
test(['2012-01-01', { weeks => 1 }],
 [qw(
   2012-01-02
   2012-01-10
   2012-01-18
   2012-01-26
   2012-02-03
   2012-02-11
   2012-02-19
   2012-02-27
   2012-03-06
   2012-03-14
   2012-03-22
   2012-03-30
   2012-04-04
 )],
 {
   both({
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-08'),
     start_event  => dt('2012-02-19'),
     end_event    => dt('2012-04-04'),
     length       => 7,
     num_events   => 7,
   }),
   marked_periods => 13,
   total_periods  => 14,
 }
);

#---------------------------------------------------------------------
test(['2012-01-01', { days => 1 }],
 [qw(
   2012-02-02
   2012-02-03
   2012-02-04
   2012-02-05
   2012-02-06
   2012-02-07
   2012-02-08
   2012-02-09
   2012-02-10
   2012-02-11
   2012-02-12
   2012-02-13
   2012-02-14
   2012-02-15
   2012-02-16
   2012-02-17
   2012-02-18
   2012-02-19
   2012-02-21
   2012-02-22
   2012-02-23
   2012-02-24
   2012-02-25
   2012-02-26
 )],
 {
   longest => {
     start_period => dt('2012-02-02'),
     end_period   => dt('2012-02-20'),
     start_event  => dt('2012-02-02'),
     end_event    => dt('2012-02-19'),
     length       => 18,
     num_events   => 18,
   },
   last    => {
     start_period => dt('2012-02-21'),
     end_period   => dt('2012-02-27'),
     start_event  => dt('2012-02-21'),
     end_event    => dt('2012-02-26'),
     length       => 6,
     num_events   => 6,
   },
   marked_periods => 24,
   total_periods  => 57,
 }
);

#---------------------------------------------------------------------
test(['2012-01-02', { days => 1}, sub { shift->day_of_week == 7 } ],
 [qw(
   2012-02-02
   2012-02-03
   2012-02-04
   2012-02-05
   2012-02-06
   2012-02-07
   2012-02-08
   2012-02-09
   2012-02-10
   2012-02-11
   2012-02-12
   2012-02-13
   2012-02-14
   2012-02-15
   2012-02-16
   2012-02-17
   2012-02-18
   2012-02-19
   2012-02-20
   2012-02-22
   2012-02-23
   2012-02-24
   2012-02-25
   2012-02-26
 )],
 {
   longest => {
     start_period => dt('2012-02-02'),
     end_period   => dt('2012-02-21'),
     start_event  => dt('2012-02-02'),
     end_event    => dt('2012-02-20'),
     length       => 16,
     num_events   => 19,
   },
   last    => {
     start_period => dt('2012-02-22'),
     end_period   => dt('2012-02-28'),
     start_event  => dt('2012-02-22'),
     end_event    => dt('2012-02-26'),
     length       => 5,
     num_events   => 5,
   },
   marked_periods => 21,
   total_periods  => 49,
 }
);

#---------------------------------------------------------------------
test(['2012-01-01', { weeks => 1 }],
 [],
 {
   marked_periods => 0,
   total_periods  => 0,
 }
);

#---------------------------------------------------------------------
done_testing;
