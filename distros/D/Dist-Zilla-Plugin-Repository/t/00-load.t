#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Dist::Zilla::Plugin::Repository');
}

diag(
"Testing Dist::Zilla::Plugin::Repository $Dist::Zilla::Plugin::Repository::VERSION, Perl $], $^X"
);
