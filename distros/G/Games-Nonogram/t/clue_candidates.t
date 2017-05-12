use strict;
use warnings;
use Test::More qw(no_plan);

use Games::Nonogram::Clue;

{
  # blocks:
  #        __........ (1, 2: 1)
  #        .._XX_.... (3, 6: 3)
  #        ......_XX_ (7, 10: 3)
  my $rule = Games::Nonogram::Clue->new( size => 10 );
  $rule->set(qw( 1 3 3 ));

  # candidates should be:
  #        X.XXX.XXX.
  #        X.XXX..XXX
  #        X..XXX.XXX
  #        .X.XXX.XXX

  my @candidates = $rule->candidates;
  ok scalar @candidates == 4;

  my $vec = $rule->line->as_vec;

  $rule->reset_blocks;
  $rule->line->as_vec( $candidates[0] );
  ok $rule->line->as_string eq 'X.XXX.XXX.';

  $rule->reset_blocks;
  $rule->line->as_vec( $candidates[1] );
  ok $rule->line->as_string eq 'X.XXX..XXX';

  $rule->reset_blocks;
  $rule->line->as_vec( $candidates[2] );
  ok $rule->line->as_string eq 'X..XXX.XXX';

  $rule->reset_blocks;
  $rule->line->as_vec( $candidates[3] );
  ok $rule->line->as_string eq '.X.XXX.XXX';

  $rule->reset_blocks;
  $rule->line->as_vec( $vec );
  ok $rule->line->as_string eq '__________';

}
