#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Dist::Zilla::Plugin::ReadmeAnyFromPod');
}

diag(
"Testing Dist::Zilla::Plugin::ReadmeAnyFromPod $Dist::Zilla::Plugin::ReadmeAnyFromPod::VERSION, Perl $], $^X"
);
