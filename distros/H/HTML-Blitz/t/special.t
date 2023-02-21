use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception);
use HTML::Blitz ();

my $html = <<'_EOT_';
<title class=special>TITLE</title>
<div class=harmless>DIV</div>
<script class=special>SCRIPT</script>
<style class=special>STYLE</style>
_EOT_

sub run {
    my ($rule, $args) = @_;
    HTML::Blitz->new($rule)->apply_to_html('(test:html)', $html)->process($args // {})
}

for my $tag (qw(
    div
)) {
    is run([$tag => ['replace_inner_text' => '>&<']]), $html =~ s/\U\Q$tag/>&amp;&lt;/r, "<$tag> contents get escaped (replace)";
    is run([$tag => ['replace_inner_var' => 'txt']], { txt => '>&<' }), $html =~ s/\U\Q$tag/>&amp;&lt;/r, "<$tag> contents get escaped (dynamic replace)";
    is run([$tag => ['transform_inner_sub' => sub { "<&$_[0]>" }]]), $html =~ s/\U\Q$tag/&lt;&amp;\U$tag\E>/r, "<$tag> contents get escaped (transform)";
    is run([$tag => ['transform_inner_var' => 'fn']], { fn => sub { "<&$_[0]>" } }), $html =~ s/\U\Q$tag/&lt;&amp;\U$tag\E>/r, "<$tag> contents get escaped (dynamic transform)";
}

for my $tag (qw(
    script
    style
)) {
    is run([$tag => ['replace_inner_text' => '>&<']]), $html =~ s/\U\Q$tag/>&</r, "<$tag> contents don't get escaped (replace)";
    is run([$tag => ['replace_inner_var' => 'txt']], { txt => '>&<' }), $html =~ s/\U\Q$tag/>&</r, "<$tag> contents don't get escaped (dynamic replace)";
    is run([$tag => ['transform_inner_sub' => sub { "<&$_[0]>" }]]), $html =~ s/\U\Q$tag/<&\U$tag\E>/r, "<$tag> contents don't get escaped (transform)";
    is run([$tag => ['transform_inner_var' => 'fn']], { fn => sub { "<&$_[0]>" } }), $html =~ s/\U\Q$tag/<&\U$tag\E>/r, "<$tag> contents don't get escaped (dynamic transform)";
}

{
    my $blitz = HTML::Blitz->new;
    for my $torcher (
        [1, '<script>'],
        [1, '</script'],
        [0, '</script>'],
        [0, '</script/'],
        [0, '</script '],
        [1, '</scriptn'],
        [1, ' <!-- '],
        [1, ' <!--> <script> '],
        [1, ' <!---> <script> '],
        [1, ' <!----> <script> '],
        [1, ' <!-- --> <script> '],
        [0, ' <!-- <script> '],
        [1, ' <!-- <script -->'],
        [1, ' <!-- <script> -->'],
        [1, ' <!-- <script> </script>'],
        [1, ' <!-- <script </script '],
        [0, ' <!-- <script> --> </script> '],
    ) {
        my ($good, $fragment) = @$torcher;
        my $document = "<script>$fragment</script>";
        if ($good) {
            is exception { $blitz->apply_to_html('(torture-test)', $document)->process }, undef, "'$fragment' parses OK";
            my $expect = $html =~ s/SCRIPT/$fragment/r;
            is run(['script' => ['replace_inner_text', $fragment]]), $expect, "'$fragment' inserted";
            is run(['script' => ['replace_inner_var', 'txt']], { txt => $fragment }), $expect, "'$fragment' inserted (dynamic)";
            is run(['script' => ['transform_inner_sub', sub { $fragment }]]), $expect, "'$fragment' transformed";
            is run(['script' => ['transform_inner_var', 'fn']], { fn => sub { $fragment } }), $expect, "'$fragment' transformed (dynamic)";
        } else {
            like exception { $blitz->apply_to_html('(torture-test)', $document)->process }, qr/\berror:.*\btag\b/, "'$fragment' is a parse error";
            like exception { run(['script' => ['replace_inner_text', $fragment]]) }, qr/\Qcontents of <script> tag/, "'$fragment' cannot be inserted";
            like exception { run(['script' => ['replace_inner_var', 'txt']], { txt => $fragment }) }, qr/\Qcontents of <script> tag/, "'$fragment' cannot be inserted (dynamic)";
            like exception { run(['script' => ['transform_inner_sub', sub { $fragment }]]) }, qr/\Qcontents of <script> tag/, "'$fragment' cannot be transformed";
            like exception { run(['script' => ['transform_inner_var', 'fn']], { fn => sub { $fragment } }) }, qr/\Qcontents of <script> tag/, "'$fragment' cannot be transformed (dynamic)";
        }
    }
}

my $dummy_template = HTML::Blitz->new->apply_to_html('(test:dummy)', '');

for my $tag (qw(
    title
    script
    style
)) {
    like exception { run([$tag => ['replace_inner_template' => $dummy_template]]) }, qr/\Q<$tag> tag cannot have descendant elements/, "cannot insert descendants into <$tag> (template)";
    like exception { run([$tag => ['replace_inner_dyn_builder' => 'dyn']], { dyn => '.' }) }, qr/\Q<$tag> tag cannot have descendant elements/, "cannot insert descendants into <$tag> (builder)";
}

done_testing;
