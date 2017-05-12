use lib 't', 'lib';
use strict;
use warnings;
use TestChunks;
use Kwiki;

no warnings 'once';

my $hub = Kwiki->new->debug->load_hub(
    {
        css_class => 'Kwiki::CSS',
        formatter_class => 'Kwiki::Formatter',
    }
);

my $formatter = $hub->formatter;

my $x = 0;
for my $test ( test_chunks( '%%%', '<<<' ) )
{

    my $wiki_text   = $test->chunk('%%%');
    my $expect_html = $test->chunk('<<<');

    my $got_html = $formatter->text_to_html($wiki_text);
    $got_html =~ s{^<div class="wiki">\n(.*)</div>\n\z}{$1}s;

    is( $got_html, $expect_html );
}

__END__
%%%
| foo | bar |
| baz | quux |
<<<
<table class="formatter_table">
<tr>
<td>foo</td>
<td>bar</td>
</tr>
<tr>
<td>baz</td>
<td>quux</td>
</tr>
</table>
