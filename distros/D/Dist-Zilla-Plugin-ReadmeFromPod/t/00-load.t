#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Dist::Zilla::Plugin::ReadmeFromPod');
}

diag(
"Testing Dist::Zilla::Plugin::ReadmeFromPod $Dist::Zilla::Plugin::ReadmeFromPod::VERSION, Perl $], $^X"
);
