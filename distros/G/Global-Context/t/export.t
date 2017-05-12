use strict;
use warnings;

use Test::More;

use Global::Context qw($Context);

$Global::Context::Object = 1;

is($Global::Context::Object, 1, '$Global::Context was just assigned to');

is($Context, 1, '...so $Context is set');

$Context = 2;
is($Global::Context::Object, 2, 'we updated $Context so $G::C is updated');

{
  local $Context = 3;
  is($Context, 3, 'updated local $Context');
  is($Global::Context::Object, 3, 'updated local $Context so $G::C is updated');
}

is($Context, 2, 'localization over ($Context)');
is($Global::Context::Object, 2, 'localization over ($G::C::Object)');

{
  package Renamed;
  use Global::Context q($Context) => { -as => 'Ctx' };

  main::is($Ctx, 2, 'imported $Context as Ctx');
}

done_testing;
