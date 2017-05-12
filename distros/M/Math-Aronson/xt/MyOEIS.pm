# Copyright 2010, 2011, 2012 Kevin Ryde

# MyOEIS.pm is shared by several distributions.
#
# MyOEIS.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyOEIS.pm is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyOEIS;
use strict;

# uncomment this to run the ### lines
#use Smart::Comments;

my $without;

sub import {
  shift;
  foreach (@_) {
    if ($_ eq '-without') {
      $without = 1;
    } else {
      die __PACKAGE__." unknown option $_";
    }
  }
}

sub read_values {
  my ($anum, %option) = @_;

  if ($without) {
    return;
  }

  my $seq = eval { require Math::NumSeq::OEIS::File;
                   Math::NumSeq::OEIS::File->new (anum => $anum) };
  if (! $seq) {
    my $error = $@;
    MyTestHelpers::diag ("$anum not available: ", $error);
    return;
  }

  my @bvalues;
  my $count = 0;
  my $lo = 0;
  if (($lo, my $value) = $seq->next) {
    push @bvalues, $value;
    while ((undef, $value) = $seq->next) {
      push @bvalues, $value;
    }
  }

  my $desc = "$anum has ".scalar(@bvalues)." values to $bvalues[-1]";
  if (my $max_count = $option{'max_count'}) {
    if (@bvalues > $max_count) {
      $#bvalues = $option{'max_count'} - 1;
      $desc .= ", shorten to ".scalar(@bvalues);
    }
  }

  if (my $max_value = $option{'max_value'}) {
    if ($max_value ne 'unlimited') {
      for (my $i = 0; $i <= $#bvalues; $i++) {
        if ($bvalues[$i] > $max_value) {
          $#bvalues = $i-1;
          if (@bvalues) {
            $desc .= ", shorten to max ".$bvalues[-1];
          } else {
            $desc .= ", shorten to nothing";
          }
        }
      }
    }
  }
  MyTestHelpers::diag ($desc);

  return (\@bvalues, $lo, $seq->{'filename'});
}

# with Y reckoned increasing downwards
sub dxdy_to_direction {
  my ($dx, $dy) = @_;
  if ($dx > 0) { return 0; }  # east
  if ($dx < 0) { return 2; }  # west
  if ($dy > 0) { return 1; }  # south
  if ($dy < 0) { return 3; }  # north
}

1;
__END__
