package main;
use Evo '-Class::Attrs::XS; Benchmark cmpthese';

# we use StrictConstructor to behave the same way as Evo, but without it the result will be the same

{

  package My::Mouse;
  use Mouse;
  use MouseX::StrictConstructor;
  has sm => is => 'rw';
  has df => is => 'rw', default => 'DEFAULT';
  has lz => is => 'rw', default => sub {'LAZY'}, lazy => 1;

  package My::Moo;
  use Moo;
  use MooX::StrictConstructor;
  has sm => is => 'rw';
  has df => is => 'rw', default => 'DEFAULT';
  has lz => is => 'rw', default => sub {'LAZY'}, lazy => 1;

  package My::Evo;
  use Evo -Class;
  has 'sm', optional;
  has df => 'DEFAULT';
  has lz => sub {'LAZY'}, lazy;
}


my $mouse = My::Mouse->new(sm => 1);
my $moo = My::Moo->new(sm => 1);
my $evo = My::Evo->new(sm => 1);

say "New(strict)";
cmpthese - 1,
  {
  Mouse => sub { My::Mouse->new(sm => 'SIMPLE') for 1 .. 1000 },
  Moo => sub { My::Moo->new(sm => 'SIMPLE') for 1 .. 1000 },
  Evo => sub { My::Evo->new(sm => 'SIMPLE') for 1 .. 1000 },
  };

say "\n\n", "Simple get+set";
cmpthese - 1,
  {
  Mouse => sub { $mouse->sm('FOO'); $mouse->sm; },
  Moo   => sub { $moo->sm('FOO');   $moo->sm; },
  Evo   => sub { $evo->sm('FOO');   $evo->sm },
  };


say "\n\n", "Lazy + default + simple";
cmpthese - 1,
  {
  Mouse => sub { $mouse->sm($mouse->lz . $mouse->df); die unless $mouse->sm eq 'LAZYDEFAULT'; },
  Moo   => sub { $moo->sm($moo->lz . $moo->df);       die unless $moo->sm eq 'LAZYDEFAULT'; },
  Evo   => sub { $evo->sm($evo->lz . $evo->df);       die unless $evo->sm eq 'LAZYDEFAULT'; },
  };
