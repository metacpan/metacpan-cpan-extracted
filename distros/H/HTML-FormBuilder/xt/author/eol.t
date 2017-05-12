use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTML/FormBuilder.pm',
    'lib/HTML/FormBuilder/Base.pm',
    'lib/HTML/FormBuilder/Field.pm',
    'lib/HTML/FormBuilder/FieldSet.pm',
    'lib/HTML/FormBuilder/Select.pm',
    'lib/HTML/FormBuilder/Validation.pm',
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
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
