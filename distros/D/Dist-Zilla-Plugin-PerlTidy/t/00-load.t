#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok('Dist::Zilla::Plugin::PerlTidy');
    use_ok('Dist::Zilla::App::Command::perltidy');
}

diag(
    "Testing Dist::Zilla::Plugin::PerlTidy $Dist::Zilla::Plugin::PerlTidy::VERSION, Perl $], $^X"
);
