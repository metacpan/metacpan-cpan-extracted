
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Fey/Hash/ColumnsKey.pm',
    'lib/Fey/Meta/Attribute/FromColumn.pm',
    'lib/Fey/Meta/Attribute/FromInflator.pm',
    'lib/Fey/Meta/Attribute/FromSelect.pm',
    'lib/Fey/Meta/Class/Schema.pm',
    'lib/Fey/Meta/Class/Table.pm',
    'lib/Fey/Meta/HasMany/ViaFK.pm',
    'lib/Fey/Meta/HasMany/ViaSelect.pm',
    'lib/Fey/Meta/HasOne/ViaFK.pm',
    'lib/Fey/Meta/HasOne/ViaSelect.pm',
    'lib/Fey/Meta/Method/Constructor.pm',
    'lib/Fey/Meta/Method/FromSelect.pm',
    'lib/Fey/Meta/Role/FromSelect.pm',
    'lib/Fey/Meta/Role/Relationship.pm',
    'lib/Fey/Meta/Role/Relationship/HasMany.pm',
    'lib/Fey/Meta/Role/Relationship/HasOne.pm',
    'lib/Fey/Meta/Role/Relationship/ViaFK.pm',
    'lib/Fey/ORM.pm',
    'lib/Fey/ORM/Exceptions.pm',
    'lib/Fey/ORM/Manual.pod',
    'lib/Fey/ORM/Manual/Intro.pod',
    'lib/Fey/ORM/Policy.pm',
    'lib/Fey/ORM/Role/Iterator.pm',
    'lib/Fey/ORM/Schema.pm',
    'lib/Fey/ORM/Table.pm',
    'lib/Fey/ORM/Types.pm',
    'lib/Fey/ORM/Types/Internal.pm',
    'lib/Fey/Object/Iterator/FromArray.pm',
    'lib/Fey/Object/Iterator/FromSelect.pm',
    'lib/Fey/Object/Iterator/FromSelect/Caching.pm',
    'lib/Fey/Object/Policy.pm',
    'lib/Fey/Object/Schema.pm',
    'lib/Fey/Object/Table.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Class/Policy.t',
    't/Class/Schema.t',
    't/Class/Table-has_many.t',
    't/Class/Table-has_one.t',
    't/Class/Table.t',
    't/Object/Iterator/FromArray.t',
    't/Object/Iterator/FromSelect.t',
    't/Object/Iterator/FromSelect/Caching.t',
    't/Object/Schema.t',
    't/Object/Table-cache.t',
    't/Object/Table-has_many.t',
    't/Object/Table-has_one.t',
    't/Object/Table-query-method.t',
    't/Object/Table-select-attr.t',
    't/Object/Table.t',
    't/author-00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/author-test-version.t',
    't/lib/Fey/ORM/Test.pm',
    't/lib/Fey/ORM/Test/Iterator.pm',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-no404s.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-tidyall.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
