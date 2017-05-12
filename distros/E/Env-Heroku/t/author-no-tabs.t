
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Env/Heroku.pm',
    'lib/Env/Heroku/Cloudinary.pm',
    'lib/Env/Heroku/Pg.pm',
    'lib/Env/Heroku/Redis.pm',
    'lib/Env/Heroku/Rediscloud.pm',
    't/00-compile.t',
    't/00_compile.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/release-check-changes.t',
    't/release-cpan-changes.t',
    't/release-distmeta.t',
    't/release-meta-json.t',
    't/release-portability.t',
    't/release-synopsis.t'
);

notabs_ok($_) foreach @files;
done_testing;
