use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/HTML/FormFu/MultiForm.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/multiform-misc-file-client-side.t',
    't/multiform-misc-file-client-side.txt',
    't/multiform-misc-file-client-side.yml',
    't/multiform-misc/accessors.t',
    't/multiform-misc/accessors.yml',
    't/multiform-misc/file-server-side.t',
    't/multiform-misc/file-server-side.txt',
    't/multiform-misc/file-server-side.yml',
    't/multiform-nested-name/0_render_page_1.t',
    't/multiform-nested-name/1_submit_page_1.t',
    't/multiform-nested-name/2_render_page_2.t',
    't/multiform-nested-name/3_submit_page_2.t',
    't/multiform-nested-name/4_complete_page_3.t',
    't/multiform-nested-name/multiform.yml',
    't/multiform-no-combine/0_render_page_1.t',
    't/multiform-no-combine/1_submit_page_1.t',
    't/multiform-no-combine/2_render_page_2.t',
    't/multiform-no-combine/3_submit_page_2.t',
    't/multiform-no-combine/4_complete_page_3.t',
    't/multiform-no-combine/multiform.yml',
    't/multiform/0_render_page_1.t',
    't/multiform/1_submit_page_1.t',
    't/multiform/2_render_page_2.t',
    't/multiform/3_submit_page_2.t',
    't/multiform/4_complete_page_3.t',
    't/multiform/multiform.yml',
    't/multiform_hidden_name/0_render_page_1.t',
    't/multiform_hidden_name/1_submit_page_1.t',
    't/multiform_hidden_name/2_render_page_2.t',
    't/multiform_hidden_name/3_submit_page_2.t',
    't/multiform_hidden_name/4_complete_page_3.t',
    't/multiform_hidden_name/multiform.yml'
);

notabs_ok($_) foreach @files;
done_testing;
