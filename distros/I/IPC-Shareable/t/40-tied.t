use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(assert_clean_process);


tie my %hv, 'IPC::Shareable', {destroy => 1, serializer => 'storable' };

$hv{a} = 'foo';

is $hv{a}, 'foo', "data created and set ok";

tied(%hv)->clean_up;

is %hv, '', "data is removed after tied(\$data)->clean_up()";

IPC::Shareable::_end;

assert_clean_process();

done_testing();
