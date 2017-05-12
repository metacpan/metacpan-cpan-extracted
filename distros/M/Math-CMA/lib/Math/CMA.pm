package Math::CMA;

use 5.010000;
use strict;
use warnings;
use List::Util qw/min max sum/;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  central_moving_averages
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.1';

sub central_moving_averages {
  my $smoothing = shift;
  my @series = @{shift()};
  my $count = min($smoothing, $#series);
  my $left = -$count;
  my $right = $count;
  my $sum = 0;
  my @result;

  return @series unless $count > 0;

  # sum first element and window to the right
  for (0 .. $count) {
    $sum += $series[$_];
  }

  # head
  while ($left < 0) {
    push @result, $sum / ($right + 1);
    $left++;
    $sum += $series[++$right] if $right < $#series;
  }

  # middle part
  while (1) {
    push @result, $sum / ($right - $left + 1);
    $sum -= $series[$left++];
    last if $right >= $#series;
    $sum += $series[++$right];
  }

  # tail
  while (@result < @series) {
    push @result, $sum / ($right - $left + 1);
    $sum -= $series[$left++];
  }

  @result;
}

1;
__END__

=head1 NAME

Math::CMA - Central Moving Average noise removal

=head1 SYNOPSIS

  use Math::CMA 'central_moving_averages';
  my @averaged = central_moving_averages(2, [1, 2, 3, 4, 5]);
  # returns (2, 2.5, 3, 3.5, 4)

=head1 DESCRIPTION

The C<central_moving_averages> function takes a smoothing distance
and an array reference and returns a list that averages all values
in the input over the distance value, in other words, it returns
for each value in the input the arithmetic mean of that value plus
$distance many values before and $distance many values after it. A
practical application would be smoothing time series data.

=head2 EXPORTS

The function C<central_moving_averages> on request, none by default.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Moving_average>

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2012 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
