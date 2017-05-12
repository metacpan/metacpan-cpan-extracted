use strict;
use warnings;

use HON::Http::UrlChecker::Service qw/p_isUrlAllowed/;

use Test::More tests => 4;

ok(p_isUrlAllowed('http://www.example.com'), 'http://www.example.com');
ok(p_isUrlAllowed('file:////tmp/index.html'), 'file:////tmp/index.html');
ok(! p_isUrlAllowed('https://'), 'https://');
ok(! p_isUrlAllowed(undef), 'undef url');
