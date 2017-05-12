use strict;
use Test::More tests => 5;

use strict;
use warnings;
use JavaScript::MochiKit;

JavaScript::MochiKit::require('Base', 'Async');

my $base = JavaScript::MochiKit::javascript_definitions('Base');
ok( $base ne '' );
my $async = JavaScript::MochiKit::javascript_definitions('Async');
ok( $async ne '' );
my $datetime = JavaScript::MochiKit::javascript_definitions('DateTime');
ok( $datetime ne '' );
my $all = JavaScript::MochiKit::javascript_definitions;
ok( $all ne '' );
ok ( "$async$base$datetime" eq $all );
