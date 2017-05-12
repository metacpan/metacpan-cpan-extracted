use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/Twitter.pm',
    't/00-compile.t',
    't/choose_shortener.t',
    't/lib/Dist/Zilla/Plugin/FakeUploader.pm',
    't/lib/LWP/TestUA.pm',
    't/lib/Net/Netrc.pm',
    't/lib/Test/DZil.pm',
    't/lib/WWW/Shorten/TinyURL.pm',
    't/meta.t',
    't/module.t',
    't/twitter.t'
);

notabs_ok($_) foreach @files;
done_testing;
