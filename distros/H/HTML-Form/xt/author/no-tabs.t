use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/HTML/Form.pm',
    'lib/HTML/Form/FileInput.pm',
    'lib/HTML/Form/IgnoreInput.pm',
    'lib/HTML/Form/ImageInput.pm',
    'lib/HTML/Form/Input.pm',
    'lib/HTML/Form/KeygenInput.pm',
    'lib/HTML/Form/ListInput.pm',
    'lib/HTML/Form/SubmitInput.pm',
    'lib/HTML/Form/TextInput.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/autocomplete.t',
    't/file_upload.t',
    't/file_upload.txt',
    't/find_input.t',
    't/form-label.t',
    't/form-maxlength.t',
    't/form-multi-select.t',
    't/form-param.t',
    't/form-parse.t',
    't/form-selector.t',
    't/form-unicode.t',
    't/form.t'
);

notabs_ok($_) foreach @files;
done_testing;
