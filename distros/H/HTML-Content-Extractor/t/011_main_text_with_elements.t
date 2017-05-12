BEGIN { $| = 1; print "1..1\n"; }

use HTML::Content::Extractor;

my $html = q~
<html>
        <body>
                <div><a href="http://www.massiveattack.com/">blah blah blah</a></div>
                <div>main <b>text</b> in <span>div</span> tag</div>
        </body>
</html>
~;

my $obj = HTML::Content::Extractor->new();
$obj->analyze($html);

my $main_text = $obj->get_main_text_with_elements(0, ["span"]);
if($main_text eq "main text in <span>div</span> tag") {
        print "ok 1\n";
} else {
        print "not ok 1\n";
}
