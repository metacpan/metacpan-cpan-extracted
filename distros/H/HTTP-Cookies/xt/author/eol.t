use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTTP/Cookies.pm',
    'lib/HTTP/Cookies/Microsoft.pm',
    'lib/HTTP/Cookies/Netscape.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-original_spec.t',
    't/11-rfc_2965.t',
    't/cookies.t',
    't/data/netscape-httponly.txt',
    't/issue26.t',
    't/issue32.t',
    't/publicsuffix.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
