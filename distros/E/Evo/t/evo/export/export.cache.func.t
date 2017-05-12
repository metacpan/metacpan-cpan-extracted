package main;
use Evo 'Test::More';
use Symbol 'delete_package';

my $counter;
{

  package My::Lib;
  use Evo -Export, -Loaded;

  sub foo : ExportGen {
    $counter++;
    sub {$counter}
  }
}

eval 'package My::Dest; use My::Lib "foo"';    ## no critic
is(My::Dest->foo, 1);
is(My::Dest->foo, 1);

eval 'package My::Dest; use My::Lib "foo"';    ## no critic
is(My::Dest->foo, 1);
is(My::Dest->foo, 1);

delete_package 'My::Dest';
eval 'package My::Dest; use My::Lib "foo"';    ## no critic
is(My::Dest->foo, 2);
is(My::Dest->foo, 2);

done_testing;
