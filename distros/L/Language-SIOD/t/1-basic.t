use Test::More tests => 2;
use_ok('Language::SIOD');

my $siod = Language::SIOD->new;
is($siod->eval('(+ 1 1)'), 2, 'eval works')
