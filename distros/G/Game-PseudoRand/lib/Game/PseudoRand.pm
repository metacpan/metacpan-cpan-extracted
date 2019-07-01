# -*- Perl -*-
#
# returns Pseudo Random Distribution random functions

package Game::PseudoRand;

use 5.10.0;
use strict;
use warnings;
use Carp qw(croak);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(prd_step prd_table);

our $VERSION = '0.01';

sub prd_step {
    my %param = @_;
    croak "prd_step requires start and step values"
      unless exists $param{start}
      and exists $param{step};
    croak "prd_step rand must be a code ref"
      if defined $param{rand} and ref $param{rand} ne 'CODE';
    my $odds  = $param{start};
    my $reset = $param{reset} // $odds;
    my $rand  = $param{rand} // sub { CORE::rand };
    my $step  = $param{step};
    (   sub {
            if ( &$rand <= $odds ) { $odds = $reset; 1 }
            else                   { $odds += $step; 0 }
        },
        sub { $odds = $param{start} }
    );
}

sub prd_table {
    my %param = @_;
    croak "prd_table requires start and table values"
      unless exists $param{start}
      and exists $param{table};
    croak "prd_table table must be a not-empty array ref"
      if ref $param{table} ne 'ARRAY' or !@{$param{table}};
    croak "prd_table rand must be a code ref"
      if defined $param{rand} and ref $param{rand} ne 'CODE';
    my $index = $param{index} // 0;
    my $table = [ @{$param{table}} ];
    croak "index outside of table bounds" if $index < 0 or $index >= @$table;
    my $odds  = $param{start};
    my $reset = $param{reset} // $odds;
    my $rand  = $param{rand} // sub { CORE::rand };
    (   sub {
            if ( &$rand <= $odds ) { $odds = $reset; $index = 0; 1 }
            else                   { $odds += $table->[ $index++ ]; $index %= @$table; 0 }
        },
        sub { $odds = $param{start}; $index = $param{index} // 0 }
    );
}

1;
__END__

=head1 NAME

Game::PseudoRand - pseudo random distribution functions

=head1 SYNOPSIS

  use Game::PseudoRand qw(prd_step prd_table);

  ( $coinflip, undef ) = prd_step( start => 0.25, step => 0.41675 );

  ( $randfn, undef ) = 
    prd_table( start => 0.12, table => [ 0.05, 0.05, 0.1, 0.1 ] );

  $coinflip->() and say "heads";

=head1 DESCRIPTION

This module creates Pseudo Random Distribution random functions. For
example one may construct a function that returns true 25% of the time
but with a rather different distribution than from a typical random
function: typically a distribution with much lower odds of long runs of
hits or misses.

=head1 FUNCTION GENERATING FUNCTIONS

These return a pair of functions, the first being the random check, and
the second a function that will reset the internal state back to the
starting values. If something goes wrong an exception will be thrown.

Random values are assumed to be in the same range as the C<rand> builtin
accepts, or

  0.0 <= r < 1.0

=over 4

=item B<prd_step> B<start> => I<odds> B<step> => I<step-odds> ...

Increases the starting I<odds> by I<step-odds> each miss, resets to
B<reset> or B<start> odds on hit. Optional keys B<rand> (custom random
function, should use same return range as builtin C<rand> does) and
B<reset> (odds to reset to, if different from the B<start> odds).

(Players may quickly realize and become annoyed by things that always
miss on the first try, so maybe only make B<start> slightly lower than
the B<reset> value when imposing a first use penalty. On the other hand,
beginner's luck can be a thing.)

=item B<prd_table> B<start> => I<odds> B<table> => I<table> ...

Increases the I<odds> by the value given in I<table> at the rotating
index I<index> on miss; resets to B<reset> or B<start> on hit, and also
resets the I<index> to C<0> on hit. Optional keys B<index> (custom
starting index, default is C<0>) and as for the previous function
B<rand> and B<reset>.

Unlike B<prd_step> the table allows for non-linear odds changes, and
will wrap around back to the beginning instead of always (eventually)
adding up to a value greater than 100% (assuming a positive step value);
this means B<prd_table> can permit longer runs of misses, depending on
the table used.

The table is copied so cannot be fiddled with afterwards (not directly
nor easily, anyways).

=back

=head1 STATISTICS 101

  prd_step( start => 0.25, step => 0.41675 )

was above claimed without evidence to be (roughly) a coinflip; what this
tests for is whether a random value is below 0.25, 0.66, and then 1.08.
This means the distribution will be quite a bit different from the
output of a random function:

  $ cd eg
  $ ./trial | ./runstats | r-fu table
  50.0351

       1      2      3
  125308 250439 124604

So no more than three flips without the result changing to a different
value; an unbiased roll instead may show (increasingly rare but not
absent) runs of 10, 20, or even more flips without a change in value:

  $ perl -E'say rand()>0.5?1:0 for 1..1e6'|./runstats|r-fu table

       1      2      3      4      5      6      7      8      9
  250244 124873  62288  31391  15578   7803   3954   1910   1018
      10     11     12     13     14     15     16     17     18
     468    252    136     54     34     18      6      3      2

The main point of this module is to reduce this variance, but probably
not so far as done for the example coinflip, and most likely in the
context of a game where too much variance is bad (luck is too much of
a factor).

=head1 BUGS

Please report any bugs or feature requests to
C<bug-game-pseudorand at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-PseudoRand>.

Patches might best be applied towards:

L<https://github.com/thrig/Game-PseudoRand>

=head1 SEE ALSO

L<https://github.com/thrig/ministry-of-silly-vaults/> contains a
discussion and example code under the C<pseudo-random-dist> directory.

Various alternative random modules to the (bad, but fast) builtin
C<rand> call exist on CPAN, e.g. L<Math::Random::PCG32>, among others.

L<https://github.com/thrig/r-fu/> is the command line bridge to R used
in the shell statistics commands, above.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
