package Math::Round::SignificantFigures;
use strict;
use warnings;
use POSIX qw{ceil floor};
require Exporter;

our $VERSION      = '0.01';
our @ISA          = qw(Exporter);
my @figs          = qw{roundsigfigs ceilsigfigs floorsigfigs};
my @digs          = qw{roundsigdigs ceilsigdigs floorsigdigs};
our %EXPORT_TAGS = (
                     figs => \@figs,
                     digs => \@digs,
                     all => [@figs, @digs],
                   );
our @EXPORT_OK   = (@figs, @digs);
our @EXPORT      = qw{};

=head1 NAME

Math::Round::SignificantFigures - Perl package for rounding numbers to a specified number of Significant Figures

=head1 SYNOPSIS

  use Math::Round::SignificantFigures qw{roundsigfigs};
  print roundsigfigs(555.555, 3), "\n";

=head1 DESCRIPTION


Math::Round::SignificantFigures supplies functions that will round numbers based on significant figures. 

This package spans the controversy whether people prefer to call significant figures or significant digits.  You may export either or both but, I called the package significant figures since that is the page for Wikipedia.

=head1 FUNCTIONS

The exporter group :figs exports the roundsigfigs, ceilsigfigs, floorsigfigs functions. The exporter group :digs exports the roundsigdigs, ceilsigdigs, floorsigdigs functions.  The exporter group :all exports all six functions

=cut

#head2 _floor_or_ceil_by_significant_digits
#
#The function _floor_or_ceil_by_significant_digits was mostly gleaned from https://stackoverflow.com/questions/202302/rounding-to-an-arbitrary-number-of-significant-digits.  The function roundToSignificantFigures code sample appears to be in the public domain.
#
#cut

sub _floor_or_ceil_by_significant_figures {
  my $num       = shift;
  my $sigfigs   = shift || 3; #undef default and zero does not make any sense
  my $ceiling   = shift || 0; #-1 floor, 0 round, 1 ceil
  return $num if $num == 0;
  my $half      = $num < 0 ? -0.5 : 0.5;
  my $d         = ceil(log(abs($num))/log(10));
  my $power     = $sigfigs - $d;
  my $magnitude = 10 ** $power;
  my $shifted   = $ceiling > 0 ? ceil($num * $magnitude)
                : $ceiling < 0 ? floor($num * $magnitude)
                : int($num * $magnitude + $half); #round
  return $shifted / $magnitude;
}

=head2 roundsigfigs, roundsigdigs

Rounds a number given the number and a number of significant figures.

=cut

sub roundsigfigs {
  my $num = shift;
  my $sigfigs   = shift;
  return _floor_or_ceil_by_significant_figures($num, $sigfigs, 0);
}

sub roundsigdigs {roundsigfigs(@_)};

=head2 floorsigfigs, floorsigdigs

Rounds a number toward -inf given the number and a number of significant figures.

=cut

sub floorsigfigs {
  my $num = shift;
  my $sigfigs   = shift;
  return _floor_or_ceil_by_significant_figures($num, $sigfigs, -1);
}

sub floorsigdigs {floorsigfigs(@_)};

=head2 ceilsigfigs, ceilsigdigs

Rounds a number toward +inf given the number and a number of significant figures.

=cut

sub ceilsigfigs {
  my $num = shift;
  my $sigfigs   = shift;
  return _floor_or_ceil_by_significant_figures($num, $sigfigs, 1);
}

sub ceilsigdigs {ceilsigfigs(@_)};

=head1 SEE ALSO

L<Math::Round> supplies functions that will round numbers in different ways.

L<Math::SigDig> allows you to edit numbers to a significant number of digits.

L<https://en.wikipedia.org/wiki/Significant_figures#Rounding_to_significant_figures>

L<https://stackoverflow.com/questions/202302/rounding-to-an-arbitrary-number-of-significant-digits>

=head1 AUTHOR

Michael R. Davis, MRDVT

=head1 COPYRIGHT AND LICENSE

MIT LICENSE

Copyright (C) 2022 by Michael R. Davis

=cut

1;
