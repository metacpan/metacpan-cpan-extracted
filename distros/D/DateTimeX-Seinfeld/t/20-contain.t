#! /usr/bin/perl
#---------------------------------------------------------------------
# 20-contain.t
# Copyright 2012 Christopher J. Madsen
#
# Test the period_containing method
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Test::More 0.88 tests => 12;

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
my $seinfeld;

sub t
{
  my ($date, $expected) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $got = $seinfeld->period_containing( dt($date) );

  is($got, dt($expected), "$date $expected");
} # end t

#---------------------------------------------------------------------

$seinfeld = DateTimeX::Seinfeld->new(
  start_date => dt('2012-01-01'),
  increment  => { weeks => 1 }
);

t qw(2012-01-02 2012-01-01);
t qw(2012-01-07 2012-01-01);
t qw(2012-01-08 2012-01-08);
t qw(2012-02-07 2012-02-05);
t qw(2012-02-26 2012-02-26);

t qw(2012-01-07T23:59:59 2012-01-01);

#---------------------------------------------------------------------
$seinfeld = DateTimeX::Seinfeld->new(
  start_date => dt('2012-01-01'),
  increment  => { days => 1 }
);

t qw(2012-01-02 2012-01-02);
t qw(2012-01-07 2012-01-07);
t qw(2012-01-08 2012-01-08);
t qw(2012-02-07 2012-02-07);
t qw(2012-02-26 2012-02-26);

t qw(2012-01-07T23:59:59 2012-01-07);

#---------------------------------------------------------------------
done_testing;
