BEGIN { $| = 1; print "1..1\n"; }

use HTML::Content::Extractor;

my $html = q~
<html>
        <body>
                <div><a href="http://www.massiveattack.com/">blah blah blah</a></div>
                <div><img src="http://rammstein.ru/uploads/posts/2011-11/1321515382_rammstein-lifad.jpg">main text in <span>div</span> tag</div>
        </body>
</html>
~;

my $obj = HTML::Content::Extractor->new();
$obj->analyze($html);

my $images = $obj->get_main_images();
if(ref $images eq "ARRAY" && exists $images->[0] && $images->[0]->{prop}->{src} eq "http://rammstein.ru/uploads/posts/2011-11/1321515382_rammstein-lifad.jpg") {
        print "ok 1\n";
} else {
        print "not ok 1\n";
}
