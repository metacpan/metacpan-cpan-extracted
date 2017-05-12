package Math::PercentChange;
use warnings;
use strict;
use Carp;
use Scalar::Util qw/dualvar/;

=head1 NAME

Math::PercentChange - calculate the percent change between two values

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

  use Math::PercentChange qw(percent_change);
  my $from = 10;
  my $to   = 5;
  my $diff = percent_change($from, $to);               # -50
  
  use Math::PercentChange qw(f_percent_change);
  my $from = 10;
  my $to   = 15;
  my $diff = f_percent_change($from, $to, "%.03f");    # 50.000%
# or
  my $diff = f_percent_change($from, $to, "%.03f", 1); # 50.000
=cut

our (@ISA, @EXPORT_OK);
BEGIN {
  require Exporter;
  @ISA = qw(Exporter);
  @EXPORT_OK = qw(percent_change f_percent_change);
}

=head2 percent_change 

Calculate the percent change between two values.  Returns the percent difference.

=cut

sub percent_change {
  my ($from, $to) = @_;
  return unless $from;
  return if int($from) == 0;

  if ($from == 0 && $to == 0) {
    return 0;
  }
  my $diff = (($to - $from) / abs($from)) * 100;
  return $diff;
}

=head2 f_percent_change 

Calculate the percent change.  Returns a L<dualvar|Scalar::Util>.  When used in numeric context, returns an unformatted percentage value.  When used in string context, returns a formatted sprintf value.  

Formatting options for sprintf can be passed as a third argument.  If no formatting option is passed, the default rounds to two decimal places ("%.2f") and appends a percent sign.  

Passing a fourth argument (1) will prevent the routine from appending a percent sign.

=cut

sub f_percent_change {
  my ($from, $to, $format, $no_ps) = @_;
  return unless $from;
  return if int($from) == 0;

  $format = '%.2f' unless $format; # TODO: Validate format

  my $ps;
  if ($no_ps) {
    $ps = '';
  }
  else {
    $ps = '%';
  }

  my $pc;
  if ($from == 0 && $to == 0) {
    $pc = 0;
  }
  else {
    $pc = (($to - $from) / abs($from)) * 100;
  }
  return dualvar $pc, sprintf($format, $pc) . $ps;
}

=head1 AUTHOR

Mike Baas E<lt>mbaas@cpan.orgE<gt>

=cut

=head1 ACKNOWLEDGEMENTS 
 
This extremely simple code was taken from Mark Jason Dominus' correction of David Wheeler's blog post on the subject matter of 'How To Calculate Percentage Change Between Two Values'. See http://www.justatheory.com/learn/math/percent_change.html for the original posting.

=cut

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;

