use lib 't', 'lib';
use strict;
use warnings;
use TestChunks;
use Kwiki;

my $hub = Kwiki->new->debug->load_hub(
    {
        css_class => 'Kwiki::CSS',
        formatter_class => 'Kwiki::Formatter',
    }
);

my $formatter = $hub->formatter;

for my $test ((test_chunks(qw(%%% <<<)))[1]) {
    my $wiki_text = $test->chunk('%%%');
    my $expect_html = $test->chunk('<<<');
    my $got_html = $formatter->text_to_html($wiki_text);
    $got_html =~ s{^<div class="wiki">\n(.*)</div>\n\z}{$1}s;
    is($got_html, $expect_html);
}

__END__
%%%
Crack Sabbath.
|   | x | y |
| a | 1 | 3 |
| b | 3 | 5 |
| c | 4 | *be bold* |
It's Christmas Time.
| http://www.kwiki.org | it */rocks/* |
<<<
<p>
Crack Sabbath.
</p>
<table>
<tr>
<td></td>
<td>x</td>
<td>y</td>
</tr>
<tr>
<td>a</td>
<td>1</td>
<td>3</td>
</tr>
<tr>
<td>b</td>
<td>3</td>
<td>5</td>
</tr>
<tr>
<td>c</td>
<td>4</td>
<td><strong>be bold</strong></td>
</tr>
</table>
<p>
It&#39;s Christmas Time.
</p>
<table>
<tr>
<td><a href="http://www.kwiki.org">http://www.kwiki.org</a></td>
<td>it <strong><em>rocks</em></strong></td>
</tr>
</table>
%%%
|
== A Heading
|
<<<
<table class="formatter_table">
<tr>
<td><h2>A Heading</h2>
</td>
</tr>
</table>
