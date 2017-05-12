
use Test;
use Errno;

BEGIN { plan tests => 6 }

#
# load
#
require Error::Wait;
ok ref tied($?), 'Error::Wait', 'tied($?)';

#
# catch exit status
#
system $^X, '-e', 'exit 1';

ok "$?",    'Exited: 1',  'catch exit code';
ok $? >> 8,  1,           '$? >> 8 still works';

#
# use $! when $? == -1
#
$? = -1; 
$! = Errno::ENOENT();

ok "$?", "$!",   'stringify like $!';
ok $?+0, -1,     'but return -1 in numeric context';

#
# catch signal
#
$? = 1;
ok "$?", qr/Killed/,  'report signal';

