package DoubleBlind;

use 5.005;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DoubleBlind ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = '0.01';

# Preloaded methods go here.

sub shuffle ($;$) {
  my ($n, $s) = (shift, shift);
  defined $s or $s = 1;
  my @out = ($s .. $s+$n-1);
  while ($n) {	# Unshuffled stuff is at indices 0..$n-1
    my $pick = int rand $n--;
    @out[$n, $pick] = @out[$pick, $n];
  }
  \@out;
}

# A good number is: square between 3000000 and 9999999, it has no zeros,
# digits (up to 0.001) are repeated no more than twice,
# last N digits of the square are as requested, fractional part of the
# square is between 0.2 and 0.8 (to avoid rounding errors)

sub good_number ($;$) {
  my ($targ, $N) = (shift, shift);
  defined $N or $N = 1;
  my $s = 1 + int sqrt 3000000;
  my $e = int sqrt 9699999;
  my $R = int(0.5 + 10**$N);
 picking:
  { my $pick = sprintf '%.3f', $s + rand $e - $s;
    redo if $pick =~ /0/;
    my $a = $pick**2;
    my $f = $a - int $a;
    redo if $f < 0.2 or $f > 0.8;
    #warn "T $pick ==> $a\n";
    my $ai = int $a;
    redo unless $ai - $R*int($ai/$R) == $targ;
    #warn "Try $pick ==> $a\n";
    my %seen;
    ++$seen{$_} <= 2 or redo picking for split //, $pick;
    #warn "Got $pick ==> $a\n";
    return $pick;
  }
}

sub process_shuffled ($$$) {
  my ($callback, $c, $start) = (shift,shift,shift);
  #defined $start or $start = ($c =~ /^10+$/ ? 0 : 1);
  my $len = length($start + $c - 1);
  my $l = shuffle $c, $start;
  for my $n (0..$#$l) {
    my $label = good_number $l->[$n], $len;
    $callback->($n+1, $l->[$n], $label);
  }
  $l = $start + $c - 1;
  <<EOD;
$c items generated.  Each item numbers has a "secret" id ($start to $l),
and a "public" label (which is a number about 2000 with 3 digits after
the decimal dot - or the decimal comma).  To extract the id from the label,
calculate the square of the label, and take the last $len digits before the
decimal dot (or the decimal comma).
EOD
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DoubleBlind - Perl extension for data-obfuscation in double-blind experiments.

=head1 SYNOPSIS

  use DoubleBlind;

  sub cb($$$) { my ($n, $id, $label) = (shift, shift, shift);
                rename "f$id.txt", "g$label.txt" or die; }
  print process_shuffled \&cb, 55, 1;

=head1 DESCRIPTION

The intent is to simplify double-blind experiments in a "friendly"
environment, when it is I<known> that the experimentator would not try
to I<consciously> break the "coding".  (For example, this may work when
one does experiments on oneself, or when the generated "label" can be
hidden from the subject.)  The decoding can be easily done using
a calculator, but (with exception of major computational savants) cannot
be done unconsciously.

Several items are generated; each one has a "secret" id (which is an
integer from user-specified interval), and a "public" label (which is a
decimal fraction).  A caller-supplied callback function is executed with
these data; it is supposed that it would prepare the experimental data,
and would mark it with the label.

In the simplest case, the callback would do all the work itself.  For
example, given files with names F<f1.txt> .. F<f55.txt>, this code
would rename them to files with names similar to F<g2342.461.txt>:

  sub cb($$$) {
    my ($n, $id, $label) = (shift, shift, shift);
    rename "f$id.txt", "g$label.txt" or die;
  }
  print process_shuffled \&cb, 55, 1;

(additionally, it would output the decoding instructions).  In more
complicated cases, the callback might, e.g., output instructions for a
third party to label the experimental data.

As an additional convenience, the items are supplied to the callback in
a randomized order (the call order is the argument $n to the callback above).
(For example, one could apply one of 55 transformations to each of the
files above basing on the number $n.)

It should work for up to 1e4 items.  (For best result, use 0 for the start
index if the number of items is a power of 10; the top item number should
not exceed 999999.)  Since no attempt of speed optimization is done, large
collections of items may require some computational resources.

=head2 process_shuffled($callback, $items, $start)

Generates $items items, each with an item ID, and an item label.  An item ID
is one of $items consecutive integers starting at $start.  An item label is a
decimal fraction about 2000 with 3 places after the decimal separator.
The item ID can be restored as the last N digits before the decimal separator
in the square of the label (here the last item has N digits).

For example, the label 1766.433 (its square is 3120285.543489) may correspond
to the id 285 if the ids are between 1 and 5000.  (For decoding, the
calculator should better keep an extra digit after the separation when
it emits the square; errors up to 2 units at this position are tolerated.)
In absense of calculator, the squaring can be done with Perl as in

  perl -wle "print 1766.433**2"

The callback is a reference to a function taking 3 arguments: the call number
(increasing from 1 to $items), the id, and the label.

=head2 EXPORT

None by default.

=head1 SEE ALSO

The file F<ex.pl> in the distribution contains a complete real-life example of
usage to check which audio storing options are suitable for your acoustic
environment.  Together with instructions inside this script, one can
create a CD with double-blind sample of 

=head1 AUTHOR

Ilya Zakharevich, E<lt>ilyaz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ilya Zakharevich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
