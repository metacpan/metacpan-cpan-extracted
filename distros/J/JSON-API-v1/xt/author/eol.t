use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/JSON/API/v1.pm',
    'lib/JSON/API/v1/Attribute.pm',
    'lib/JSON/API/v1/Error.pm',
    'lib/JSON/API/v1/JSONAPI.pm',
    'lib/JSON/API/v1/Links.pm',
    'lib/JSON/API/v1/MetaObject.pm',
    'lib/JSON/API/v1/Relationship.pm',
    'lib/JSON/API/v1/Resource.pm',
    'lib/JSON/API/v1/Roles/Links.pm',
    'lib/JSON/API/v1/Roles/MetaObject.pm',
    'lib/JSON/API/v1/Roles/TO_JSON.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/200-object-resource.t',
    't/210-object-link.t',
    't/220-object-error.t',
    't/230-object-attribute.t',
    't/240-object-relationship.t',
    't/300-toplevel-full.t',
    't/lib/Test/JSON/API/v1.pm',
    't/lib/Test/JSON/API/v1/Object.pm',
    't/lib/Test/JSON/API/v1/Util.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
