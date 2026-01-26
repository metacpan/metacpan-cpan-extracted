package Hash::Util::Set::PP;
use strict;
use warnings;

use Exporter   qw[import];
use List::Util qw[all any];

our $VERSION   = '0.01';
our @EXPORT_OK = qw[ keys_union
                     keys_intersection
                     keys_difference
                     keys_symmetric_difference
                     keys_disjoint
                     keys_equal
                     keys_subset
                     keys_proper_subset
                     keys_superset
                     keys_proper_superset
                     keys_any
                     keys_all
                     keys_none ];

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub keys_union(\%\%) {
  my ($x, $y) = @_;
  my %z; @z{
    keys %$x,
    keys %$y
  } = ();
  return keys %z;
}

sub keys_intersection(\%\%) {
  my ($x, $y) = @_;
  ($x, $y) = ($y, $x) if (keys %$x > keys %$y);
  return grep { exists $y->{$_} } keys %$x;
}

sub keys_difference(\%\%) {
  my ($x, $y) = @_;
  return grep { not exists $y->{$_} } keys %$x;
}

sub keys_symmetric_difference(\%\%) {
  my ($x, $y) = @_;
  return (
    (grep { not exists $y->{$_} } keys %$x),
    (grep { not exists $x->{$_} } keys %$y),
  );
}

sub keys_disjoint(\%\%) {
  my ($x, $y) = @_;
  ($x, $y) = ($y, $x) if (keys %$x > keys %$y);
  return not any { exists $y->{$_} } keys %$x;
}

sub keys_equal(\%\%) {
  my ($x, $y) = @_;
  return keys %$x == keys %$y && all { exists $y->{$_} } keys %$x;
}

sub keys_subset(\%\%) {
  my ($x, $y) = @_;
  return keys %$x <= keys %$y && all { exists $y->{$_} } keys %$x;
}

sub keys_proper_subset(\%\%) {
  my ($x, $y) = @_;
  return keys %$x < keys %$y && all { exists $y->{$_} } keys %$x;
}

sub keys_superset(\%\%) {
  my ($x, $y) = @_;
  return &keys_subset($y, $x);
}

sub keys_proper_superset(\%\%) {
  my ($x, $y) = @_;
  return &keys_proper_subset($y, $x);
}

sub keys_any(\%@) {
  my $x = shift;
  return any { exists $x->{$_} } @_;
}

sub keys_all(\%@) {
  my $x = shift;
  return all { exists $x->{$_} } @_;
}

sub keys_none(\%@) {
  my $x = shift;
  return not any { exists $x->{$_} } @_;
}

BEGIN {
  delete @Hash::Util::Set::PP::{qw(all any)};
}

1;
