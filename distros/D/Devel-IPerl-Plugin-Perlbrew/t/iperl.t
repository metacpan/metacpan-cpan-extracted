use strict;
use warnings;
use Test::More;
use Devel::IPerl;
use IPerl;

plan skip_all => "No App::perlbrew" unless eval 'use App::perlbrew; 1';

my $iperl = new_ok('IPerl');

ok $iperl->load_plugin('Perlbrew');

can_ok $iperl,
  qw{perlbrew perlbrew_lib_create perlbrew_list perlbrew_list_modules};


done_testing;
