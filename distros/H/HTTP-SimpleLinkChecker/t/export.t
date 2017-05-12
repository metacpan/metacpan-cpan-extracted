use Test::More tests => 1;

use HTTP::SimpleLinkChecker qw(check_link);

ok( defined &check_link, "check_link was exported" );
