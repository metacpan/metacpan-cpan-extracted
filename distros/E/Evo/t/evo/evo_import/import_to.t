package main;
use Evo;
use Test::More;

my @called;
{

  package Evo::My;
  use Evo -Loaded;

  sub import { push @called, [scalar caller, @_] }

  package Evo::NoImport;
  use Evo -Loaded;

  package Evo::My2;
  use Evo;
  sub makeimport { Evo::->import(shift); }

}

EMPTY: {
  no warnings 'redefine';
  my @loaded;
  local *Module::Load::load = sub { push @loaded, shift };
  Evo::->import('Evo::My ()');
  Evo::->import('Evo::My()');
  Evo::->import('Evo::My ( ) ');
  Evo::->import('Evo::My ( ); Evo::My second ');
  Evo::->import('Evo::My ( ), Evo::My second ');
  is_deeply \@called, [['main', 'Evo::My', 'second'], ['main', 'Evo::My', 'second']];
  is scalar(grep { $_ eq 'Evo::My' } @loaded), 7;
}

@called = ();
Evo::->import('Evo::My');
Evo::->import('Evo::My bar baz');
Evo::->import('-My(bar baz)');
Evo::->import('-My');
Evo::->import('-My');
Evo::->import('-My(-foo bar)');

# multi imports
Evo::->import('Evo::My foo1 foo2; Evo::My bar1 bar2 ; -My opa');

# multi imports from other package
Evo::My2::makeimport("/::My foo1 foo2;\n Evo::My bar");

is_deeply \@called, [
  [qw(main Evo::My)], [qw(main Evo::My bar baz)], [qw(main Evo::My bar baz)], [qw(main Evo::My)],
  [qw(main Evo::My)], [qw(main Evo::My -foo bar)],

  # multi in one cal
  [qw(main Evo::My foo1 foo2)], [qw(main Evo::My bar1 bar2)], [qw(main Evo::My opa)],

  # multi from other
  [qw(Evo::My2 Evo::My foo1 foo2)], [qw(Evo::My2 Evo::My bar)],
];


done_testing;
