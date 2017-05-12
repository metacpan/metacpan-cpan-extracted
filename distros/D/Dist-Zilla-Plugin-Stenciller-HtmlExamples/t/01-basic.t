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

use Dist::Zilla::Plugin::Stenciller::HtmlExamples;

ok 1;

my $tzil = Builder->from_config(
    {   dist_root => 't/corpus' },
    {   add_files => {
            'source/t/corpus/template.html' => path('t/corpus/template.html')->slurp_utf8,
            'source/t/corpus/01-test.stencil' => path('t/corpus/01-test.stencil')->slurp_utf8,
            'source/example/du.mmy' => '',
            'source/dist.ini' => simple_ini(
                ['Stenciller::HtmlExamples' => {
                    source_directory => 't/corpus',
                    file_pattern => '.+\.stencil',
                    output_directory => 'example',
                    template_file => 't/corpus/template.html',
                    output_also_as_html => 1,
                    separator => '<hr />',
                }],
            )
        }
    },
);

$tzil->build;

my $generated_html = $tzil->slurp_file('build/example/01-test.html');
eq_or_diff $generated_html, expected_html(), 'Generated correct html';

done_testing;

sub expected_html {
    return cushion 0, 1, qi{
        <!DOCTYPE html>
        <html>
            <head>
                <title>Stencils</title>
            </head>
            <body>
                <div class="container">



        <pre>&lt;%= badge &#39;1&#39; %&gt;</pre>
        <pre>&lt;span class=&quot;badge&quot;&gt;1&lt;/span&gt;</pre>
        <div>    <span class="badge">1</span></div>
        <hr />
        <pre>&lt;%= badge &#39;2&#39; %&gt;</pre>
        <pre>&lt;span class=&quot;badge&quot;&gt;2&lt;/span&gt;</pre>
        <div>    <span class="badge">2</span></div>
                </div>
            </body>
        </html>
    };

}
