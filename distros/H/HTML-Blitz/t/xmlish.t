use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception);
use HTML::Blitz ();

my $blitz = HTML::Blitz->new(
    [ 'b' => ['replace_inner_text' => 'hej'] ],
);

like exception { $blitz->apply_to_html('html~' . __LINE__, '<p><![CDATA[<b>yo</b>]]></p>') }, qr/\binvalid declaration\b/, "CDATA is an error";

like exception { $blitz->apply_to_html('html~' . __LINE__, '<p />') }, qr/\bnon-void tag '<p>'/, "<p /> is an error";

{
    my $template = $blitz->apply_to_html('html~' . __LINE__, '<svg><![CDATA[<b>yo</b>]]></svg>');
    my $got = $template->process;
    is $got, '<svg>&lt;b>yo&lt;/b></svg>', 'CDATA treated as raw text in foreign element';
}

{
    my $template = $blitz->apply_to_html('html~' . __LINE__, '<math><p/></math>');
    my $got = $template->process;
    is $got, '<math><p /></math>', '<p/> treated as self-closing in foreign element';
}

for my $tag ('svg', 'math') {
    my $template = $blitz->apply_to_html('html~' . __LINE__, "<$tag/>");
    my $got = $template->process;
    is $got, "<$tag />", "$tag can be self-closing";
}

done_testing;
