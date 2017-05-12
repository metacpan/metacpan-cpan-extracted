use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Logging::Simple') };

my $mod = 'Logging::Simple';

can_ok($mod, 'new');
can_ok($mod, 'file');
can_ok($mod, 'level');
can_ok($mod, 'levels');
can_ok($mod, 'display');
can_ok($mod, 'timestamp');
can_ok($mod, 'print');
can_ok($mod, '_sub_names');
can_ok($mod, '_generate_entry');

for (qw(_0 _1 _2 _3 _4 _5 _6 _7)){
    can_ok($mod, $_);
}

done_testing();


