use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTML/Form.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/autocomplete.t',
    't/find_input.t',
    't/form-label.t',
    't/form-maxlength.t',
    't/form-multi-select.t',
    't/form-param.t',
    't/form-selector.t',
    't/form-unicode.t',
    't/form.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
