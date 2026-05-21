use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/LWP/ConsoleLogger.pm',
    'lib/LWP/ConsoleLogger/Easy.pm',
    'lib/LWP/ConsoleLogger/Everywhere.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/LWP/ConsoleLogger.t',
    't/LWP/ConsoleLogger/Easy.t',
    't/LWP/ConsoleLogger/Everywhere.t',
    't/LWP/ConsoleLogger/environment-variable-log-file.t',
    't/LWP/ConsoleLogger/post-with-json.t',
    't/LWP/ConsoleLogger/post.t',
    't/decode-header-value.t',
    't/everywhere-logfile-child.pl',
    't/everywhere-logfile.t',
    't/pretty.t',
    't/test-data/content-regex.html',
    't/test-data/file-upload.html',
    't/test-data/foo.html',
    't/test-data/unicode.html',
    't/test-data/wide-cjk.html',
    't/unicode.t',
    't/utf8-cookies.t',
    't/utf8-headers.t',
    't/wide-chars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
