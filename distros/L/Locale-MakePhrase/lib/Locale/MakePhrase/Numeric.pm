package Locale::MakePhrase::Numeric;
our $VERSION = 0.1;
our $DEBUG = 0;

=head1 NAME

Locale::MakePhrase::Numeric - Numeric translation/stringification

=head1 SYNOPSIS

This module provides the functionality to translate and/or stringify
a numeric, into something suitable for the string being translated.

=head1 API

The following class-functions are provided:

=cut

use strict;
use warnings;
use base qw(Exporter);
use Data::Dumper;
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw( stringify);
local $Data::Dumper::Indent = 1 if $DEBUG;

# Common formatting types
sub DOT       { return [ '.','' ,'-','' ]; }
sub COMMA     { return [ ',','' ,'-','' ]; }
sub DOT_COMMA { return [ '.',',','-','' ]; }
sub COMMA_DOT { return [ ',','.','-','' ]; }

#--------------------------------------------------------------------------

=head2 $string stringify($number,$options)

This class-function implements the stringification of a number to a
suitable output format.  The $options parameter is used to control
the formatting behaviour:

=over 2

=item C<numeric_format>

The formatting appled to the number; this must be an array reference
containing 4 elements:

=over 3

=item 1.

decimal seperator

=item 2.

thousand's seperator

=item 3.

when the value is negative, the symbol shown to the left of the
number

=item 4.

when the value is negative, the symbol shown to the right of the
number

=back

=item C<width>

Set the number of characters used in the output.

=item C<precision>

Set the maximum number of decimal places processed.

=item C<fixed>

Set this to true to make the output use a fixed number of decimal
places, irrespective if the values are all zeros.  Use this in
conjunction with the C<precision> setting.

=item C<scientific>

Set this value to true to make the number show exponential notation.

=item C<leading_zeros>

Set this to true to make the output display zeros; combine this
with the C<width> setting.

=back

=cut

sub stringify {
  shift if (@_ == 3);
  my ($number,$options) = @_;
  my $format = $options->{numeric_format};
  $format = DOT unless $format;
  print STDERR "Stringify format: '".join("' '",@$format)."'\n" if $DEBUG > 3;
  my $negative = $number < 0 ? 1 : 0;
  $number = abs($number);

  # Don't let the %G of sprintf, turn ten million (or bigger) into something like 1E+007
  # Otherwise, try to apply various formatting options.
  if (!$options->{fixed} and !$options->{scientific} and $number < 10_000_000_000 and $number == int($number)) {
    $number += 0;  # Just use normal integer stringification.
  } else {
    my $mode = "%";
    $mode .= $options->{width} if (exists $options->{width});
    if (exists $options->{precision}) {
      $mode .= ".".$options->{precision};
    } else {
      $mode .= ".15";
    }
    if ($options->{fixed}) {
      $mode .= "F";
    } else {
      $mode .= "G";
    }
    $number = CORE::sprintf($mode,$number);
    if(!$options->{fixed} and !$options->{scientific} and $number < 10_000_000_000 and $number == int($number)) {
      $number += 0;  # Just use normal integer stringification.
    }
  }

  # We optionally apply numeric formatting (eg: put comma's into big numbers)
  if ($format) {

    # has the format defined a seperator, we add them
    if ($format->[1]) {
      # The initial \d+ gobbles as many digits as it can, and then we
      # backtrack so it un-eats the rightmost three, and then we
      # insert the comma there.
      while( $number =~ s/^(\d+)(\d{3})/$1_$2/s ) {1}

      my $t = $format->[0];
      if ($t eq '_') {
        $number =~ s/_/#/g;
        $number =~ s/\./_/;
        $t = $format->[1];
        $number =~ s/#/$t/g;
      } else {
        $number =~ s/\./$t/;
        $t = $format->[1];
        $number =~ s/_/$t/g;
      }
    } else {
      my $t = $format->[0];
      $number =~ s/\./$t/ if ($t ne '.');
    }
  }

  # do we want leading zero's
  $number = tr< ><0> if ($options->{leading_zeros});

  # apply negative-formatting
  $number = $format->[2].$number.$format->[3] if $negative;

  return $number;
}

1;
__END__
#--------------------------------------------------------------------------

=head1 NOTES

If the number is purely an integer, you have not set the C<fixed> or
C<scientific> settings, we try to keep the number from turning into
its scientific notation (ie: we try to stop big numbers turning into
something like 1.04E+09).

=cut

