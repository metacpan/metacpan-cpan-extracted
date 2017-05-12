use Test::More tests => 3;

use GeNUScreen::Config;

my $thiscfg = GeNUScreen::Config->new();
my $thatcfg = GeNUScreen::Config->new();

$thiscfg->read_config('t/data/example.cfg');
$thatcfg->read_config('t/data/config.hdf');

my @keys = $thiscfg->get_keys();

cmp_ok(scalar @keys, '==', 262, 'number of keys');
cmp_ok($thiscfg->get_value('config.general.webusername'), 'eq', 'admin'
      , 'webusername');

my $cfgdiff = $thiscfg->diff($thatcfg);

ok($cfgdiff->is_empty(), 'no differences');
