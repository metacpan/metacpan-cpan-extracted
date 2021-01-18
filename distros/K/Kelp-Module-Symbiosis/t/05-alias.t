use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);
use lib 't/lib';
use CountingApp;

my $app = CountingApp->new(mode => 'none_mounted');
$app->run_all;

is $app->get_count, 1, 'run count ok';

done_testing;
