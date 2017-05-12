use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::DZil;
use Test::Differences;
use Path::Tiny;
use syntax 'qi';
use String::Cushion;
use File::Temp 'tempdir';
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Dist::Zilla::Plugin::Stenciller::MojoliciousTests;

ok 1;


my $tzil = Builder->from_config(
    {   dist_root => 't/corpus' },
    {   add_files => {
            'source/t/corpus/template.test' => path('t/corpus/template.test')->slurp_utf8,
            'source/t/corpus/01-test.stencil' => path('t/corpus/01-test.stencil')->slurp_utf8,
            'source/example/du.mmy' => '',
            'source/dist.ini' => simple_ini(
                ['Stenciller::MojoliciousTests' => {
                    source_directory => 't/corpus',
                    file_pattern => '.+\.stencil',
                    output_directory => 't',
                    template_file => 't/corpus/template.test',
                }],
            )
        }
    },
);

$tzil->build;

my $generated_test = $tzil->slurp_file('build/t/01-test.t');
eq_or_diff $generated_test, expected_test(), 'Generated correct test';

done_testing;

sub expected_test {
    return cushion 0, 2, qi{
        use 5.10.1;
        use strict;
        use warnings FATAL => 'all';
        use Test::More;
        use Test::Warnings;
        use Test::Mojo::Trim;
        use Mojolicious::Lite;

        use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

        my $test = Test::Mojo::Trim->new;


        # test from line 2 in 01-test.stencil

        my $expected_01_test_2 = qq{    <span class="badge">3</span>};

        get '/01_test_2' => '01_test_2';

        $test->get_ok('/01_test_2')->status_is(200)->trimmed_content_is($expected_01_test_2, 'Matched trimmed content in 01-test.stencil, line 2');

        done_testing();

        __DATA__

        @@ 01_test_2.html.ep

            <% badge '3' %>
    };

}
