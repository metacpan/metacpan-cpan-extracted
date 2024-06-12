use strict;
use warnings;

use Test::More;
use KelpX::Symbiosis::Test;
use Kelp;

my $app = Kelp->new();
can_ok $app, 'run';
can_ok $app, 'json';

my $t = KelpX::Symbiosis::Test->new(app => $app);
can_ok $t, 'run';
can_ok $t, 'json';

done_testing;

