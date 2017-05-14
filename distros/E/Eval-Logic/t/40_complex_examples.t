use Test::More tests => 4;

use_ok ( 'Eval::Logic' );

# This is actually testing Perl itself, so we do just one for now.
my $c1 = Eval::Logic->new ( '((one && two ) || three) ? four : !five' );

ok ( $c1->evaluate_if_true ( 'one', 'two', 'four' ));
ok ( ! $c1->evaluate_if_true ( 'three', 'five' ));
ok ( $c1->evaluate_if_true ( 'three', 'four' ));
