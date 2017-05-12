#!perl
use strict;
use warnings;

use Test::More 0.88;

use Test::DZil;
use Path::Class;
use Dist::Zilla::App::Tester;

use Test::File::ShareDir -share => {
  -module => { 'Dist::Zilla::MintingProfile::Default' => 'profiles' },
};

# ModuleBuild
my $tzil = Minter->_new_from_profile(
  [ Default => 'xs-mb'],
  { name => 'DZT-Minty-XS', },
  { global_config_root => dir('corpus/global')->absolute },
);

$tzil->mint_dist;

my $pm = $tzil->slurp_file('mint/lib/DZT/Minty/XS.pm');
like($pm, qr/package DZT::Minty::XS;/, "our new module has the package declaration we want");

my $xs = $tzil->slurp_file('mint/lib/DZT/Minty/XS.xs');
like($xs, qr/^MODULE = DZT::Minty::XS/m, "our new module has the package declaration we want");

my $distini = $tzil->slurp_file('mint/dist.ini');
like($distini, qr/copyright_holder = A. U. Thor/, "copyright_holder in dist.ini");

# MakeMaker
$tzil = Minter->_new_from_profile(
  [ Default => 'xs-mm'],
  { name => 'DZT-Minty-XS', },
  { global_config_root => dir('corpus/global')->absolute },
);

$tzil->mint_dist;

$pm = $tzil->slurp_file('mint/lib/DZT/Minty/XS.pm');
like($pm, qr/package DZT::Minty::XS;/, "our new module has the package declaration we want");

$xs = $tzil->slurp_file('mint/XS.xs');
like($xs, qr/^MODULE = DZT::Minty::XS/m, "our new module has the package declaration we want");

$distini = $tzil->slurp_file('mint/dist.ini');
like($distini, qr/copyright_holder = A. U. Thor/, "copyright_holder in dist.ini");

done_testing;
