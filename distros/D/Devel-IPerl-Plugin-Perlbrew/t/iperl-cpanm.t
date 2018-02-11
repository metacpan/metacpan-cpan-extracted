use strict;
use warnings;
use Test::More;
use Devel::IPerl;
use IPerl;

my $iperl = new_ok('IPerl');

ok $iperl->load_plugin('CpanMinus');

# cpanm
can_ok $iperl, qw{cpanm cpanm_info cpanm_installdeps};
# autoload perlbrew
can_ok $iperl, 'perlbrew';

is $iperl->cpanm, -1, 'no library for app::cpanminus';

is $iperl->cpanm_info, -1, 'return early too';

is $iperl->cpanm_installdeps('ACME::NotThere'), 1, 'anything';

is $iperl->cpanm('--self-upgrade'), 1, 'upgrade';

done_testing;
