use Test::More tests => 2;

use_ok('Language::Haskell');

my $hugs = Language::Haskell->new;
is($hugs->eval('product [1..10]'), 3628800, 'eval works');

