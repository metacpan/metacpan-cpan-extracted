use Test2::V0;
use HTML::Blitz ();

my $html = <<'_EOT_';
    <area>
    <base>
    <basefont>
    <bgsound>
    <br>
    <col>
    <embed>
    <frame>
    <hr>
    <img>
    <input>
    <keygen>
    <link>
    <meta>
    <param>
    <source>
    <track>
    <wbr>
_EOT_

my $blitz = HTML::Blitz->new;

{
    my $template = $blitz->apply_to_html('(void:html)', $html);
    is $template->process, $html, 'effectively void elements (including deprecated basefont, bgsound, frame, keygen) parse as void';
}

{
    my $template = $blitz->apply_to_html('(void/:html)', $html =~ s!>!/>!gr);
    is $template->process, $html, 'void elements permit redundant / before end of tag';
}

done_testing;
