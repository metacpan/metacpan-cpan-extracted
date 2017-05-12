package main;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use Evo 'MyExternalNoEvoImport';
use Test::More;
use Evo::Internal::Exception;

# just load
ok do { Evo::->import('MyExternalNoEvoImport'); 1 };

HAS_IMPORT_PASS_ARGS: {
  my @got = @_;
  my $caller;
  local *MyExternalNoEvoImport::import = sub { $caller = caller; push @got, @_ };
  Evo::->import('MyExternalNoEvoImport foo bar');
  is_deeply \@got, [qw(MyExternalNoEvoImport foo bar)];
  is $caller, 'main';
}
HAS_IMPORT_NO_ARGS: {
  my @got = @_;
  my $caller;
  local *MyExternalNoEvoImport::import = sub { $caller = caller; push @got, @_ };
  Evo::->import('MyExternalNoEvoImport');
  is_deeply \@got, [qw(MyExternalNoEvoImport)];
  is $caller, 'main';
}

NO_IMPORT_NO_ARGS: {
  local *MyExternalNoEvoImport::import;
  Evo::->import('MyExternalNoEvoImport');
  pass "just load";
}

# neither import method no exporting
like exception { Evo::->import('MyExternalNoEvoImport(foo)'); },
  qr/MyExternalNoEvoImport.+"import".+$0/;


# order
my @called;
my $N = 20;
EVAL: {
  local $@;
  eval    ## no critic
    "package Evo::My$_; use Evo -Loaded; sub import { push \@called, $_ }" for 1 .. $N;
  die if $@;
}

Evo::->import("-My$_") for 1 .. $N;
is_deeply \@called, [1 .. $N];


# errors
FATAL: {
  local $@;
  eval "package My::Foo; use Evo '[]'";    ## no critic
  like $@, qr/Can't parse/;
}

# oneline
{

  package My::Foo;
  use Evo '-Export *', -Loaded;
  sub foo : Export {'foo'}

  package Evo::My::Bar;
  use Evo '-Export *', -Loaded;
  sub bar : Export {'bar'}
}

use Evo 'My::Foo; -My::Bar *;';
use Evo 'My::Foo; -My::Bar';

# one string
{

  package My::Foo;
  use Evo '-Export *; -Lib ';
  use Evo '-Export *; -Lib;';
  use Evo '-Export *; -Lib; ';
}

done_testing;
