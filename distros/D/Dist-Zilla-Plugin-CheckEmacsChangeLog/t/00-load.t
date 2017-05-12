#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok ('Dist::Zilla::Plugin::CheckEmacsChangeLog');
}

diag ("Testing Dist::Zilla::Plugin::CheckEmacsChangeLog");
