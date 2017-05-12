
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.05

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/HTML/FormHandler/Generator/DBIC.pm',
    'lib/HTML/FormHandler/Model/DBIC.pm',
    'lib/HTML/FormHandler/Model/DBIC/TypeMap.pm',
    'lib/HTML/FormHandler/TraitFor/DBICFields.pm',
    'lib/HTML/FormHandler/TraitFor/Model/DBIC.pm',
    'script/form_generator.pl'
);

notabs_ok($_) foreach @files;
done_testing;
