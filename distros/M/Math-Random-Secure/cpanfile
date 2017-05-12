# 1.001 supports 64-bit systems.
requires 'Math::Random::ISAAC' => 1.001;

# 0.07 fixes a lot of important bugs and warnings.
requires 'Crypt::Random::Source' => 0.07;

requires 'Moo' => 2;

recommends 'Math::Random::ISAAC::XS';

on 'develop' => sub {
   requires 'Statistics::Test::RandomWalk';
};

on 'test' => sub {
   requires 'Test::More';
   requires 'Test::Warn';
   requires 'List::MoreUtils';
   requires 'Test::SharedFork';

   recommends 'Test::LeakTrace';
};
