use strict;
use warnings;
use Test::More;
use Devel::IPerl;
use IPerl;

plan skip_all => "No Devel::Hide"
  unless eval 'use Devel::Hide qw{App::cpanminus::fatscript App::perlbrew}; 1;';

my $iperl = new_ok('IPerl');

ok $iperl->load_plugin('CpanMinus');

is $iperl->cpanm('--self-upgrade'), -1, 'eval failed for cpanminus';

is $iperl->perlbrew_list, -1, 'eval failed for perlbrew';

done_testing;
