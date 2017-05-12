use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/MetaProvides/ProvideRecord.pm',
    'lib/Dist/Zilla/MetaProvides/Types.pm',
    'lib/Dist/Zilla/Plugin/MetaProvides.pm',
    'lib/Dist/Zilla/Role/MetaProvider/Provider.pm',
    't/00-compile/lib_Dist_Zilla_MetaProvides_ProvideRecord_pm.t',
    't/00-compile/lib_Dist_Zilla_MetaProvides_Types_pm.t',
    't/00-compile/lib_Dist_Zilla_Plugin_MetaProvides_pm.t',
    't/00-compile/lib_Dist_Zilla_Role_MetaProvider_Provider_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-Provider/01-boolean-attrs.t',
    't/01-Provider/02-resolve-versions.t',
    't/01-Provider/03-metanoindex.t',
    't/01-Provider/04-integration.t',
    't/01-Provider/05-filenames.t',
    't/01-Provider/06-cuckoo.t',
    't/02-MetaProvides-ProvideRecord.t',
    't/03-Types.t',
    't/04-MetaProvides.t',
    't/lib/Dist/Zilla/Plugin/FakePlugin.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
