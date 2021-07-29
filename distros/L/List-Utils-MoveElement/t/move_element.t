use Test::More;
use strict;
use warnings;

BEGIN {
  use_ok('List::Utils::MoveElement::PP');
  use_ok('List::Utils::MoveElement');
}

our @modules_to_test = ('::PP', '');

# Array for test
my @letters = (qw/a b c d e f/);

# Test PP and XS separately if applicable
for my $prefix (@modules_to_test) {
  no strict 'refs';
  my $func;
  $func = "List::Utils::MoveElement${prefix}::left";
  is_deeply([$func->(0, @letters)], [qw/a b c d e f/], "$prefix left 0, list (no-op)");
  is_deeply([$func->(1, @letters)], [qw/b a c d e f/], "$prefix left 1, list");
  is_deeply([$func->(2, @letters)], [qw/a c b d e f/], "$prefix left 2, list");
  is_deeply([$func->(3, @letters)], [qw/a b d c e f/], "$prefix left 3, list");
  is_deeply([$func->(4, @letters)], [qw/a b c e d f/], "$prefix left 4, list");
  is_deeply([$func->(5, @letters)], [qw/a b c d f e/], "$prefix left 5, list");
  is_deeply(\@letters, [qw/a b c d e f/], "$prefix move_left - original array not mutated");

  $func = "List::Utils::MoveElement${prefix}::right";
  is_deeply([$func->(5, @letters)], [qw/a b c d e f/], "$prefix right 5, list (no-op)");
  is_deeply([$func->(4, @letters)], [qw/a b c d f e/], "$prefix right 4, list");
  is_deeply([$func->(3, @letters)], [qw/a b c e d f/], "$prefix right 3, list");
  is_deeply([$func->(2, @letters)], [qw/a b d c e f/], "$prefix right 2, list");
  is_deeply([$func->(1, @letters)], [qw/a c b d e f/], "$prefix right 1, list");
  is_deeply([$func->(0, @letters)], [qw/b a c d e f/], "$prefix right 0, list");
  is_deeply(\@letters, [qw/a b c d e f/], "$prefix move_left - original array not mutated");

  $func = "List::Utils::MoveElement${prefix}::to_beginning";
  is_deeply([$func->(0, @letters)], [qw/a b c d e f/], "$prefix to_beginning 0, list (no-op)");
  is_deeply([$func->(1, @letters)], [qw/b a c d e f/], "$prefix to_beginning 1, list");
  is_deeply([$func->(2, @letters)], [qw/c a b d e f/], "$prefix to_beginning 2, list");
  is_deeply([$func->(3, @letters)], [qw/d a b c e f/], "$prefix to_beginning 3, list");
  is_deeply([$func->(4, @letters)], [qw/e a b c d f/], "$prefix to_beginning 4, list");
  is_deeply([$func->(5, @letters)], [qw/f a b c d e/], "$prefix to_beginning 5, list");
  is_deeply(\@letters, [qw/a b c d e f/], "$prefix to_beginning - original array not mutated");

  $func = "List::Utils::MoveElement${prefix}::to_end";
  is_deeply([$func->(5, @letters)], [qw/a b c d e f/], "$prefix to_end 5, list (no-op)");
  is_deeply([$func->(4, @letters)], [qw/a b c d f e/], "$prefix to_end 4, list");
  is_deeply([$func->(3, @letters)], [qw/a b c e f d/], "$prefix to_end 3, list");
  is_deeply([$func->(2, @letters)], [qw/a b d e f c/], "$prefix to_end 2, list");
  is_deeply([$func->(1, @letters)], [qw/a c d e f b/], "$prefix to_end 1, list");
  is_deeply([$func->(0, @letters)], [qw/b c d e f a/], "$prefix to_end 0, list");
  is_deeply(\@letters, [qw/a b c d e f/], "$prefix to_end - original array not mutated");
}

# Check move_left, move_right alised to left, right
is(\&List::Utils::MoveElement::move_element_left,          \&List::Utils::MoveElement::left,         'move_left aliased to left');
is(\&List::Utils::MoveElement::move_element_right,         \&List::Utils::MoveElement::right,        'move_right aliased to right');
is(\&List::Utils::MoveElement::move_element_to_beginning,  \&List::Utils::MoveElement::to_beginning, 'move_left aliased to left');
is(\&List::Utils::MoveElement::move_element_to_end,        \&List::Utils::MoveElement::to_end,       'move_right aliased to right');


# Test with no import
eval '
  package List::Utils::MoveElement::test_no_export;
  use List::Utils::MoveElement ();
';
{
  for my $sub (qw/move_element_left move_element_right move_element_to_beginning move_element_to_end left right to_beginning to_end/) {
    ok(!defined(List::Utils::Move::test_no_export->can($sub)), "$sub is not exported by default");
  }
}

# Make sure exported subs are exported
eval '
  package List::Utils::MoveElement::test_with_export;
  use List::Utils::MoveElement;
';
{
  for my $sub (qw/move_element_left move_element_right move_element_to_beginning move_element_to_end/) {
    ok(defined(List::Utils::MoveElement::test_with_export->can($sub)), "$sub is exported upon request");
  }
}

# We never export the short names
my $unable_exports = eval '
  package List::Utils::MoveElement::test_never_export;
  use List::Utils::MoveElement qw/left right to_beginning to_end/;
  1;
';
ok(!$unable_exports, 'attempting to import short names should be an error');

done_testing;

