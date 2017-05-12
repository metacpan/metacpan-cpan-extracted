use Test::More tests => 12;
use lib qw( ./lib ../lib );
use Egg::Helper;

my $pkg= 'Egg::Helper::Build::Module';

require_ok($pkg);

my $e= Egg::Helper->run( Vtest => { helper_test=> $pkg });
my $c= $e->config;
my $mod_dir= "$c->{root}/Test-Test";

@ARGV= ('Test::Test', '-o '. $e->helper_tempdir);

ok $e->_start_helper;
ok -e $mod_dir, qq{-e $mod_dir};
for (qw{
  lib/Test/Test.pm
  Makefile.PL
  t/00_use.t
  t/89_pod.t
  t/98_perlcritic.t
  t/99_pod_coverage.t~
  Changes
  README
  MANIFEST.SKIP
  })
  { ok -e "$mod_dir/$_", qq{-e "$mod_dir/$_"} }

