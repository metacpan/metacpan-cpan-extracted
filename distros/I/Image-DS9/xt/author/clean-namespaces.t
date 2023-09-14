use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::CleanNamespaces 0.006

use Test::More 0.94;
use Test::CleanNamespaces 0.15;

subtest all_namespaces_clean => sub {
    namespaces_clean(
        grep { my $mod = $_; not grep { $mod =~ $_ } qr/Image::DS9::Grammar/, qr/Image::DS9::PConsts/, qr/Image::DS9::Constants::V1/ }
            Test::CleanNamespaces->find_modules
    );
};

done_testing;
