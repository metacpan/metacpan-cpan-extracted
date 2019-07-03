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
our @EXPORT_OK = qw(prd_bistep prd_step prd_bitable prd_table);

our $VERSION = '0.03';

sub HIT ()  { 1 }
sub MISS () { 0 }

sub prd_bistep {
    my %param = @_;
    croak "need start step_hit step_miss values"
      unless exists $param{start}
      and exists $param{step_hit}
      and exists $param{step_miss};
    croak "rand must be a code ref"
      if defined $param{rand} and ref $param{rand} ne 'CODE';
    my $odds = $param{start};
    my $rand = $param{rand} // sub { CORE::rand };
    (   sub {
            if   ( &$rand <= $odds ) { $odds += $param{step_hit};  HIT }
            else                     { $odds += $param{step_miss}; MISS }
        },
        sub { $odds = $param{start} }
    );
}

sub prd_step {
    my %param = @_;
    croak "requires start and step values"
      unless exists $param{start}
      and exists $param{step};
    croak "rand must be a code ref"
      if defined $param{rand} and ref $param{rand} ne 'CODE';
    my $odds  = $param{start};
    my $reset = $param{reset} // $odds;
    my $rand  = $param{rand} // sub { CORE::rand };
    (   sub {
            if ( &$rand <= $odds ) { $odds = $reset; HIT }
            else                   { $odds += $param{step}; MISS }
        },
        sub { $odds = $param{start} }
    );
}

sub prd_bitable {
    my %param = @_;
    croak "need start table_hit table_miss values"
      unless exists $param{start}
      and exists $param{table_hit}
      and exists $param{table_miss};
    croak "table_hit must be a not-empty array ref"
      if ref $param{table_hit} ne 'ARRAY'
      or !@{ $param{table_hit} };
    croak "table_miss must be a not-empty array ref"
      if ref $param{table_miss} ne 'ARRAY'
      or !@{ $param{table_miss} };
    croak "rand must be a code ref"
      if defined $param{rand} and ref $param{rand} ne 'CODE';
    my $idxhit  = $param{index_hit}  // 0;
    my $idxmiss = $param{index_miss} // 0;
    my $table_hit  = [ @{ $param{table_hit} } ];
    my $table_miss = [ @{ $param{table_miss} } ];
    croak "index_hit outside of table bounds"
      if $idxhit < 0 or $idxhit >= @$table_hit;
    croak "index_miss outside of table bounds"
      if $idxmiss < 0 or $idxmiss >= @$table_miss;
    my $odds = $param{start};
    my $rand = $param{rand} // sub { CORE::rand };
    (   sub {
            if ( &$rand <= $odds ) {
                $idxmiss = 0;
                $odds += $table_hit->[ $idxhit++ ];
                $idxhit %= @$table_hit;
                return HIT;
            } else {
                $idxhit = 0;
                $odds += $table_miss->[ $idxmiss++ ];
                $idxmiss %= @$table_miss;
                return MISS;
            }
        },
        sub {
            $odds    = $param{start};
            $idxhit  = $param{idxhit} // 0;
            $idxmiss = $param{idxmiss} // 0;
        }
    );
}

sub prd_table {
    my %param = @_;
    croak "need start and table values"
      unless exists $param{start}
      and exists $param{table};
    croak "table must be a not-empty array ref"
      if ref $param{table} ne 'ARRAY'
      or !@{ $param{table} };
    croak "rand must be a code ref"
      if defined $param{rand} and ref $param{rand} ne 'CODE';
    my $index = $param{index} // 0;
    my $table = [ @{ $param{table} } ];
    croak "index outside of table bounds" if $index < 0 or $index >= @$table;
    my $odds  = $param{start};
    my $reset = $param{reset} // $odds;
    my $rand  = $param{rand} // sub { CORE::rand };
    (   sub {
            if ( &$rand <= $odds ) { $odds = $reset; $index = 0; HIT }
            else { $odds += $table->[ $index++ ]; $index %= @$table; MISS }
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

  ( $coinflip, $reset ) = prd_step( start => 0.25, step => 0.41675 );

  $coinflip->() and say "maybe heads";      # 25%
  $coinflip->() and say "likely heads";     # 25% + 42%
  $coinflip->() and say "heads";            # 25% + 42% * 2
  $coinflip->() and say "maybe heads";      # 25%
  $reset->();
  $coinflip->() and say "maybe heads";      # 25%

  ( $randfn, undef ) = 
    prd_table( start => 0.12, table => [ 0.05, 0.05, 0.1 ] );

  $food = ( prd_bistep(
    start     =>  0.5,
    step_hit  => -0.4,
    step_miss =>  0.1
  ) )[0]; 

  ... = prd_bitable(
    start      => 0.5,
    table_hit  => [ -0.1, -0.2 ],
    table_miss => [  0.1,  0.2 ]
  )

=head1 DESCRIPTION

This module creates Pseudo Random Distribution (PRD) random functions.
For example one may construct a function that returns true 25% of the
time but one with a rather different distribution than from a typical
random function: typically a distribution with much lower odds of long
runs of misses or (maybe) long runs of hits.

Random values are assumed to be in the same range as the C<rand> builtin
accepts, or

  0.0 <= r < 1.0

though the odds used in the functions generated below can go above
or equal to 1.0 (always true or a hit) or below 0.0 (always false
or a miss).

=head1 FUNCTION GENERATING FUNCTIONS

These return a pair of functions, the first being the random function
to call for a true or false value (C<1> or C<0> to be exact), and the
second a function that will reset the internal state of the closure
back to the starting values. If something goes wrong an exception will
be thrown.

=over 4

=item B<prd_step>

Increases the starting I<odds> by I<step-odds> each miss, resets to
I<reset> or I<start> odds on hit. Optional keys I<rand> (for a custom
random function, should return values in the same range as the builtin
C<rand>) and I<reset> (odds to reset to, if different from the
I<start> odds).

Use this for effects that need to be frequently activated but where a
predictable cool-down timer is unsuitable.

Players may quickly realize and become annoyed by things that always
miss on the first try, so maybe only make I<start> slightly lower than
the I<reset> value when imposing a first use penalty. On the other hand,
beginner's luck can be a thing. One way to (maybe) apply beginner's luck
would be to randomize the starting odds.

  prd_step( start => rand(), step => 0.1, reset => 0.0 );

=item B<prd_bistep>

Bidirectional step odds function generator. On hit adds the (ideally
negative) I<step_hit> value to the odds. On miss adds the (ideally
positive) I<step_miss> value to the odds.

  prd_bistep( start => 0.5, step_hit => -0.1, step_miss => 0.1 )

This produces "rubber band" odds that increase during periods of bad
luck but decrease during periods of good luck; this may suit the
generation of critical resources such as food that there should not be
too much or too little of.

Also accepts I<rand> for a custom RNG function. There is no I<reset> as
the odds are always adjusted by the step values after hit or miss.

=item B<prd_table>

Increases the I<odds> by the value given in I<table> at the optional
index I<index> on miss; resets to I<reset> or I<start> on hit, and
also resets the I<index> to C<0> on hit. Optional keys I<index>
(custom starting index, default is C<0>) and as for B<prd_step>
I<rand> and I<reset>.

  prd_table( start => 0.12, table => [ 0.05, 0.05, 0.1, 0.1 ] )

Unlike B<prd_step> the table allows for non-linear odds changes, and can
wrap around back to the beginning instead of always eventually adding up
to a value greater than 100%; this means B<prd_table> can permit longer
runs of misses, depending on the table used.

=item B<prd_bitable>

Uses a different table lookup for when there is a hit or a miss, and
adjusts the odds by that value. Resets the index pointer of the miss or
hit to C<0> on a hit or miss.

  ... = prd_bitable(
    start      => 0.5,
    table_hit  => [ -0.1, -0.2 ],
    table_miss => [  0.1,  0.2 ]
  )

Accepts a custom I<rand> function.

=back

=head1 STATISTICS 101

  prd_step( start => 0.25, step => 0.41675 )

was above claimed without evidence to be (roughly) a coinflip; what this
tests for is whether a random value is below 0.25, 0.66, and then 1.08.
This means the distribution of runs will be rather different from the
output of a random function:

  $ cd eg
  $ ./trial | ./runstats
  49.9610
  1  53309
  2  19578
  3  1670
  4  435
  5  109
  6  27
  7  11
  $ perl -E 'say rand > 0.5 ? 1 : 0 for 1..1e5' | ./runstats          
  1  24967
  2  12459
  3  6180
  4  3238
  5  1597
  6  742
  7  380
  8  197
  9  88
  10 53
  11 25
  12 11
  13 8
  14 1
  15 1
  16 2
  17 2
  21 1

The C<trial> coinflip only managed a run of 7 (and it was a run of
activations, not of misses) while the unbiased coinflip using the same
C<rand> had a run of 21 hits or misses in a row, and greater odds of
runs of two to seven hits or misses in a row compared to the PRD.

Note that for B<prd_step> an B<prd_table> if the I<start> odds are set
too high there may be runs of activations; B<prd_step> and B<prd_table>
typically only minimize runs of misses and thus may activate too often.
This can be avoided (especially with B<prd_table>) by setting low
initial odds so that the odds of a miss are very high after a hit,
though this then may require a large increase in odds to keep the
variance low, if that is also desired.

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

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
