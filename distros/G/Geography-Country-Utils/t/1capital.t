use Test;
BEGIN { plan tests => 2 }

use Geography::Country::Utils qw(Capital);

ok(defined &Capital);
ok(Capital('SW'), 'Stockholm');
