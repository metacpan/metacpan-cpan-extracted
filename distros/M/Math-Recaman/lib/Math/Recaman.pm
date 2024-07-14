package Math::Recaman;

use 5.006;
use strict;
use warnings;

use Exporter qw/import/;

our $VERSION = '1.6';
our $USING_INTSPAN;
our @EXPORT_OK=qw(recaman recaman_a008336);

BEGIN {
    eval {  require Set::IntSpan };
    $USING_INTSPAN=0;
    unless ($@) {
        Set::IntSpan->import();
        $USING_INTSPAN = 1;
    }
}

our @checks = (0, 1, 3, 6, 2, 7, 13, 20, 12, 21,
                 11, 22, 10, 23, 9, 24, 8, 25, 43,
                 62, 42, 63, 41, 18, 42, 17, 43, 16,
                 44, 15, 45, 14, 46, 79, 113, 78, 114,
                 77, 39, 78, 38, 79, 37, 80, 36, 81,
                 35, 82, 34, 83, 33, 84, 32, 85, 31,
                 86, 30, 87, 29, 88, 28, 89, 27, 90,
                 26, 91, 157, 224, 156, 225, 155);

our @a008336_checks = (1, 1, 2, 6, 24, 120, 20, 140, 1120, 10080, 1008, 11088, 924,
                  12012, 858, 12870, 205920, 3500640, 194480, 3695120,
                  184756, 3879876, 176358, 4056234, 97349616, 2433740400,
                  93605400, 2527345800, 90262350, 2617608150, 87253605,
                  2704861755, 86555576160, 2856334013280);

=encoding utf8

=head1 NAME

Math::Recaman - Calculate numbers in Recamán's sequence

=head1 SYNOPSIS

    use Math::Recaman qw(recaman);

    recaman(100);                             # print the first 100 numbers in Recamán's sequence
    recaman(1000, sub { push @nums, shift }); # collect the first 1000 numbers into an array
    my @array = recaman(10);                  # Returns the first 10 Recaman numbers as an array

=head1 DESCRIPTION

Recamán's sequence is a well known sequence defined by a recurrence relation.

It is named after its inventor, Colombian mathematician Bernado Recamán Santos by Neil Sloane,
creator of the On-Line Encyclopedia of Integer Sequences (OEIS). The OEIS entry for this sequence is A005132.

The sequence is defined as

  aₙ = 0         if n = 0
  aₙ = aₙ₋₁ - n  if aₙ₋₁ - n > 0 and is not already in the sequence
  aₙ = aₙ₋₁ + n  otherwise

It is known to produce quite aethetically pleasing outputs if plotted as an image or as music.

See more:

=over 4

=item OEIS

L<https://oeis.org/A005132>

=item  Wikipedia

L<https://en.wikipedia.org/wiki/Recam%C3%A1n%27s_sequence>

=item Numberphile on YouTube

L<https://www.youtube.com/watch?v=FGC5TdIiT9U>

=back

=head1 METHODS

=head2 recaman <target> [callback]

Takes a target number to calculate to. If nothing is given the method returns immediately.

By default it prints each number out on a new line.

You can optionally pass in a anonymous subroutine which will be called for each new number in the sequence
with the arguments C<number>, C<count> and C<max seen so far>.

If you do not pass an anonymous subroutine and if you call this subroutine expecting an array in return then nothing will be printed.

=cut

sub recaman {
  my @seen;
  my @values;

  my $target   = shift || return;
  my $callback = shift || (wantarray ? sub { push @values, shift } : sub { print $_[0]."\n" });

  my $increment = sub { $seen[$_[0]]++ };
  my $present   = sub { $seen[$_[0]]   };
  my $set;
  if ($USING_INTSPAN) {
    $set = Set::IntSpan->new;
    $increment = sub { $set->insert($_[0]) };
    $present   = sub { $set->member($_[0]) };
  }

  my $num     = 1;
  my $pointer = 0;
  my $max     = 0;
  while ($num<=$target) {
    $increment->($pointer);
    $callback->($pointer, $num, $max) if defined $callback;
    my $next = $pointer - $num;
    $next = $pointer+$num if $next<0 || $present->($next);
    $pointer = $next;
    $num++;
    $max = $pointer if $pointer>$max;
  }
  return @values;
}

=head2 recaman_a008336 <target> [callback]

There is another sequence invented by Recamán, less known, defined as:

  a₁   = 1
  aₙ₊₁ = aₙ/n  if n divides aₙ
  aₙ₊₁ = naₙ   otherwise

Takes a target number to calculate to. If nothing is given the method returns immediately.

By default it prints each number out on a new line.

You can optionally pass in a anonymous subroutine which will be called for each new number in the sequence
with the arguments C<number>, C<count> and C<max seen so far>.

If you do not pass an anonymous subroutine and if you call this subroutine expecting an array in return then nothing will be printed.

=cut
sub recaman_a008336 {
    my @values;

    my $target   = shift || return 0;
    my $callback = shift || (wantarray ? sub { push @values, shift } : sub { print $_[0]."\n" });

    return 0 if $target<1;

    my $num     = 0;
    my $pointer = 0;
    my $max     = 0;
    while ($num<$target) {
        if ($num < 2) {
            $pointer = 1;
        } elsif (($pointer%$num)==0) {
            $pointer = $pointer/$num;
        } else {
            $pointer = $pointer*$num;
        }
        # print "$num) $pointer\n";
        $callback->($pointer, $num, $max);
        $num++;
        $max = $pointer if $pointer>$max;
    }
    return @values;
}

=head1 Using Set::IntSpan

If the module L<Set::IntSpan> is installed then that will be used for keeping track of the sequence.

This should make it more efficient for very long sequences.

You can check to see if the module is using L<Set::IntSpan> by checking the variable C<$Math::Recaman::USING_INTSPAN>.

You can disable using the module even if it's installed by setting the variable C<$Math::Recaman::USING_INTSPAN> to C<0> before calling the C<recaman> function.

=cut

=head1 AUTHOR

Simon Wistow, C<< <simon at thegestalt.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-recaman at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Recaman>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can also open issues on GitHub at L<https://github.com/simonwistow/Math-Recaman>.

=head1 VERSION

Version 0.01

=cut

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Recaman

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Recaman>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Math-Recaman>

=item * Search CPAN

L<https://metacpan.org/release/Math-Recaman>

=item * GitHub

L<https://github.com/simonwistow/Math-Recaman>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Simon Wistow.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Math::Recaman
