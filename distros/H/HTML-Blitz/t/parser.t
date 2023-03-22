use Test2::V0;
use HTML::Blitz ();

{
    my $template = <<'_EOT_';
1<!---->
2<!--!b!-->
3<!--<c<-->
4<!--<!-d<!-->
_EOT_
    my $blitz1 = HTML::Blitz->new({ keep_comments_re => qr/<!\z/ });
    my $blitz2 = HTML::Blitz->new({ keep_comments_re => qr/(?<!<!)\z/ });

    my ($html1, $html2) = map $_->apply_to_html('(test)', $template)->process, $blitz1, $blitz2;

    is $html1, <<'_EOT_';
1
2
3
4<!--<!-d<!-->
_EOT_

    is $html2, <<'_EOT_';
1<!---->
2<!--!b!-->
3<!--<c<-->
4
_EOT_
}

for my $fragment (
    '<!-->',
    '<!--->',
    '<!----!>',
) {
    like dies { HTML::Blitz->new->apply_to_html('(test)', $fragment) }, qr/improperly closed comment/;
}

like dies { HTML::Blitz->new->apply_to_html('(test)', '<!--<!--X-->') }, qr/improperly nested comment/;
like dies { HTML::Blitz->new->apply_to_html('(test)', '<!--') }, qr/unterminated comment/;

like dies { HTML::Blitz->new->apply_to_html('(test)', '<p></p a>') }, qr/invalid attribute in end tag/;
like dies { HTML::Blitz->new->apply_to_html('(test)', '<p class="" class=""></p>') }, qr/duplicate attribute 'class'/;
like dies { HTML::Blitz->new->apply_to_html('(test)', "<br a=>") }, qr/missing attribute value after '='/;
like dies { HTML::Blitz->new->apply_to_html('(test)', "<br a='>") }, qr/missing "'" after attribute value/;
like dies { HTML::Blitz->new->apply_to_html('(test)', "<br a='>'b>") }, qr/missing whitespace after attribute value/;

done_testing;
