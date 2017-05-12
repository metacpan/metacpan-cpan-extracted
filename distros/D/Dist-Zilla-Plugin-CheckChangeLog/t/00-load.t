#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Dist::Zilla::Plugin::CheckChangeLog');
}

diag(
"Testing Dist::Zilla::Plugin::CheckChangeLog $Dist::Zilla::Plugin::CheckChangeLog::VERSION, Perl $], $^X"
);
