use strict;
use Test::More 0.98;

use_ok $_ for qw(
  Flexconf
);

my $c;

sub create {
  return Flexconf->new({
    k => {
      h => {
        hk => 'hv'
      },
      a => [
        'av'
      ]
    }
  });
}


$c = create();

is($c->get('k.h'), $c->get()->{k}->{h}, 'get works with path');

$c->assign('', {nk=>'nv'});
is($c->get()->{nk}, 'nv', 'assign top value - new value');
is($c->get()->{k}, undef, 'assign top value - absence of previous');


$c = create();

$c->assign('k.h.nhk', 'nhv');
is($c->get()->{k}->{h}->{nhk}, 'nhv', 'assign value to internal hash');

$c->assign('k.a.1', 'nav');
is($c->get()->{k}->{a}->[1], 'nav', 'assign value to internal array');


$c = create();

$c->copy('k.h.cav', 'k.a.0');
is($c->get()->{k}->{h}->{cav}, 'av', 'copy value from array to hash');

$c->copy('k.a.1', 'k.h.hk');
is($c->get()->{k}->{a}->[1], 'hv', 'copy value from hash to array');


$c = create();

$c->copy('', 'k.h');
is($c->get()->{hk}, 'hv', 'copy value from deep to top');
is($c->get()->{k}, undef, 'copy value from deep to top - absence of previous');


$c = create();

$c->remove('k.h.hk');
is(scalar keys %{$c->get('k.h')}, 0, 'remove key from deep hash');

$c->remove('k.a.0');
is(scalar @{$c->get('k.a')}, 0, 'remove key from deep array');

$c->remove('');
is($c->get(''), undef, 'full remove from top by empty key');


done_testing;

