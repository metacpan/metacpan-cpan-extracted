use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/HTML/FormBuilder.pm',
    'lib/HTML/FormBuilder.pod',
    'lib/HTML/FormBuilder/Base.pm',
    'lib/HTML/FormBuilder/Base.pod',
    'lib/HTML/FormBuilder/Field.pm',
    'lib/HTML/FormBuilder/Field.pod',
    'lib/HTML/FormBuilder/FieldSet.pm',
    'lib/HTML/FormBuilder/FieldSet.pod',
    'lib/HTML/FormBuilder/Select.pm',
    'lib/HTML/FormBuilder/Select.pod',
    'lib/HTML/FormBuilder/Validation.pm',
    'lib/HTML/FormBuilder/Validation.pod',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/csrf.t',
    't/formbuilder.t',
    't/formbuilder/base.t',
    't/formbuilder/field.t',
    't/formbuilder/fieldset.t',
    't/formbuilder/select.t',
    't/formbuilder/validation.t',
    't/formbuilder_output.t',
    't/lib/BaseTest.pm',
    't/lib/TestHelper.pm',
    't/rc/perlcriticrc',
    't/rc/perltidyrc',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
