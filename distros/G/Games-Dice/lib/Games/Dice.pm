use strict;
use warnings;
package Games::Dice;
# ABSTRACT: Perl module to simulate die rolls
$Games::Dice::VERSION = '0.045';
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( roll roll_array);

# Preloaded methods go here.

# Win32 has crummy built in rand() support
# So let's use something that's decent and pure perl
use if $^O eq "MSWin32", 'Math::Random::MT::Perl' => qw(rand);

sub roll ($) {
    my($line, $dice_string, $sign, $offset, $sum, @throws, @result);

    $line = shift;

    return $line if $line =~ /\A[0-9]+\z/;

    return undef unless $line =~ m{
                 ^              # beginning of line
                 (              # dice string in $1
                   (?:\d+)?     # optional count
                   [dD]         # 'd' for dice
                   (?:          # type of dice:
                      \d+       # either one or more digits
                    |           # or
                      %         # a percent sign for d% = d100
                    |           # pr
                      F         # a F for a fudge dice
                   )
                 )
                 (?:            # grouping-only parens
                   ([-+xX*/bB]) # a + - * / b(est) in $2
                   (\d+)        # an offset in $3
                 )?             # both of those last are optional
                 \s*            # possibly some trailing space (like \n)
                 $
              }x;               # whitespace allowed

    $dice_string = $1;
    $sign        = $2 || '';
    $offset      = $3 || 0;

    $sign        = lc $sign;

    @throws = roll_array( $dice_string );
    return undef unless @throws;

    if( $sign eq 'b' ) {
        $offset = 0       if $offset < 0;
        $offset = @throws if $offset > @throws;

        @throws = sort { $b <=> $a } @throws;   # sort numerically, descending
        @result = @throws[ 0 .. $offset-1 ];    # pick off the $offset first ones
    } else {
        @result = @throws;
    }

    $sum = 0;
    $sum += $_ foreach @result;
    $sum += $offset if  $sign eq '+';
    $sum -= $offset if  $sign eq '-';
    $sum *= $offset if ($sign eq '*' || $sign eq 'x');
    do { $sum /= $offset; $sum = int $sum; } if $sign eq '/';

    return $sum;
}

sub roll_array ($) {
    my($line, $num, $type, @throws);

    $line = shift;

    return $line if $line =~ /\A[0-9]+\z/;

    return undef unless $line =~ m{
                 ^      # beginning of line
                 (\d+)? # optional count in $1
                 [dD]   # 'd' for dice
                 (      # type of dice in $2:
                    \d+ # either one or more digits
                  |     # or
                    %   # a percent sign for d% = d100
                  |     # pr
                    F   # a F for a fudge dice
                 )
              }x;       # whitespace allowed

    $num    = $1 || 1;
    $type   = $2;

    my $throw = sub { int (rand $_[0]) + 1 };

    if ( $type eq '%' ) {
        $type = 100;
    } elsif ( $type eq 'F' ) {
        $throw = sub { int( rand 3 ) - 1 };
    }

    @throws = ();
    for( 1 .. $num ) {
        push @throws, $throw->($type);
    }

    return @throws;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Games::Dice - Perl module to simulate die rolls

=head1 VERSION

version 0.045

=head1 SYNOPSIS

  use Games::Dice 'roll';
  $strength = roll '3d6+1';

  use Games::Dice 'roll_array';
  @rolls = roll_array '4d8';

=head1 DESCRIPTION

Games::Dice simulates die rolls. It uses a function-oriented (not
object-oriented) interface. No functions are exported by default. At
present, there are two functions which are exportable: C<roll> and
C<roll_array>. The latter is used internally by C<roll>, but can also be
exported by itself.

The number and type of dice to roll is given in a style which should be
familiar to players of popular role-playing games: I<a>dI<b>[+-*/b]I<c>.
I<a> is optional and defaults to 1; it gives the number of dice to roll.
I<b> indicates the number of sides to each die; the most common,
cube-shaped die is thus a d6. % can be used instead of 100 for I<b>;
hence, rolling 2d% and 2d100 is equivalent. If F is used for I<b> fudge
dice are used, which either results in -1, 0 or 1. C<roll> simulates I<a>
rolls of I<b>-sided dice and adds together the results. The optional end,
consisting of one of +-*/b and a number I<c>, can modify the sum of the
individual dice. +-*/ are similar in that they take the sum of the rolls
and add or subtract I<c>, or multiply or divide the sum by I<c>. (x can
also be used instead of *.) Hence, 1d6+2 gives a number in the range
3..8, and 2d4*10 gives a number in the range 20..80. (Using / truncates
the result to an int after dividing.) Using b in this slot is a little
different: it's short for "best" and indicates "roll a number of dice,
but add together only the best few". For example, 5d6b3 rolls five six-
sided dice and adds together the three best rolls. This is sometimes
used, for example, in role-playing to give higher averages.

Generally, C<roll> probably provides the nicer interface, since it does
the adding up itself. However, in some situations one may wish to
process the individual rolls (for example, I am told that in the game
Feng Shui, the number of dice to be rolled cannot be determined in
advance but depends on whether any 6s were rolled); in such a case, one
can use C<roll_array> to return an array of values, which can then be
examined or processed in an application-dependent manner.

This having been said, comments and additions (especially if accompanied
by code!) to Games::Dice are welcome. So, using the above example, if
anyone wishes to contribute a function along the lines of roll_feng_shui
to become part of Games::Dice (or to support any other style of die
rolling), you can contribute it to the author's address, listed below.

=head1 NAME

=head1 AUTHORS

=over 4

=item *

Philip Newton <pne@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Mario Domgoergen Mark Allen

=over 4

=item *

Mario Domgoergen <mdom@taz.de>

=item *

Mark Allen <mrallen1@yahoo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1999 by Philip Newton.

This is free software, licensed under:

  The MIT (X11) License

=cut

__END__

#pod =head1 NAME
#pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod   use Games::Dice 'roll';
#pod   $strength = roll '3d6+1';
#pod
#pod   use Games::Dice 'roll_array';
#pod   @rolls = roll_array '4d8';
#pod
#pod =head1 DESCRIPTION
#pod
#pod Games::Dice simulates die rolls. It uses a function-oriented (not
#pod object-oriented) interface. No functions are exported by default. At
#pod present, there are two functions which are exportable: C<roll> and
#pod C<roll_array>. The latter is used internally by C<roll>, but can also be
#pod exported by itself.
#pod
#pod The number and type of dice to roll is given in a style which should be
#pod familiar to players of popular role-playing games: I<a>dI<b>[+-*/b]I<c>.
#pod I<a> is optional and defaults to 1; it gives the number of dice to roll.
#pod I<b> indicates the number of sides to each die; the most common,
#pod cube-shaped die is thus a d6. % can be used instead of 100 for I<b>;
#pod hence, rolling 2d% and 2d100 is equivalent. If F is used for I<b> fudge
#pod dice are used, which either results in -1, 0 or 1. C<roll> simulates I<a>
#pod rolls of I<b>-sided dice and adds together the results. The optional end,
#pod consisting of one of +-*/b and a number I<c>, can modify the sum of the
#pod individual dice. +-*/ are similar in that they take the sum of the rolls
#pod and add or subtract I<c>, or multiply or divide the sum by I<c>. (x can
#pod also be used instead of *.) Hence, 1d6+2 gives a number in the range
#pod 3..8, and 2d4*10 gives a number in the range 20..80. (Using / truncates
#pod the result to an int after dividing.) Using b in this slot is a little
#pod different: it's short for "best" and indicates "roll a number of dice,
#pod but add together only the best few". For example, 5d6b3 rolls five six-
#pod sided dice and adds together the three best rolls. This is sometimes
#pod used, for example, in role-playing to give higher averages.
#pod
#pod Generally, C<roll> probably provides the nicer interface, since it does
#pod the adding up itself. However, in some situations one may wish to
#pod process the individual rolls (for example, I am told that in the game
#pod Feng Shui, the number of dice to be rolled cannot be determined in
#pod advance but depends on whether any 6s were rolled); in such a case, one
#pod can use C<roll_array> to return an array of values, which can then be
#pod examined or processed in an application-dependent manner.
#pod
#pod This having been said, comments and additions (especially if accompanied
#pod by code!) to Games::Dice are welcome. So, using the above example, if
#pod anyone wishes to contribute a function along the lines of roll_feng_shui
#pod to become part of Games::Dice (or to support any other style of die
#pod rolling), you can contribute it to the author's address, listed below.
#pod
#pod =cut
