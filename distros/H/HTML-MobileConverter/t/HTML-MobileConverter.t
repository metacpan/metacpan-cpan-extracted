use Test::More tests => 23;
BEGIN { use_ok('HTML::MobileConverter') };

use URI;

my $baseuri = 'http://example.com/';
my $c = HTML::MobileConverter->new(
    baseuri => $baseuri,
    hrefhandler => sub {
        my $href = shift;
        return URI->new_abs($href, $baseuri);
    },
);

ok(ref($c) eq 'HTML::MobileConverter');

my $text = $c->_makestartm(
    'img',
    {
        src => '/sample.gif',
        width => '500',
        alt => 'sample',
    },
);
ok ($text eq 'img:sample');

$text = $c->_makestart2(
    'img',
    {
        src => '/sample.gif',
        width => '500',
        alt => 'sample',
    },
);
ok ($text =~ /^<img.+alt="sample"/);

$c->_initparser;
&{$c->starthandler}(
    qq|<a href="$baseuri" onclick="alert()">|,
    'a',
    {
        href => $baseuri,
        onclick => "alert()",
    },
);
ok($c->param('tagcount') == 1);
ok($c->param('mtagcount') == 1);
ok($c->param('mhtml') eq qq|<a href="$baseuri">|);

&{$c->texthandler}('example');
ok($c->param('tagcount') == 1);
ok($c->param('mtagcount') == 1);
ok($c->param('mhtml') eq qq|<a href="$baseuri">example|);

&{$c->endhandler}(
    '</a>',
    'a',
);
ok($c->param('tagcount') == 1);
ok($c->param('mtagcount') == 1);
ok($c->param('mhtml') eq qq|<a href="$baseuri">example</a>|);

$c->_initparser;
my $html = <<END;
<html><body>
<a href="http://example.com/my">my link</a>
</body></html>
END

my $html2 = <<END;
<html><body>
<a href="./my">my link</a>
<script><!-- script --></script>
<!-- comment -->
<iframe src="http://www.example.com/"></iframe>
</body></html>
END

my $mhtml = $c->convert($html);

ok($c->param('tagcount') == 3);
ok($c->param('mtagcount') == 3);
ok($c->ismobilecontent);

$c->_initparser;

ok($c->param('tagcount') == 0);
ok($c->param('mtagcount') == 0);

my $mhtml2 = $c->convert($html2);
$mhtml2 =~ s/(\s)\s+/$1/g;

ok($c->param('tagcount') == 5);
ok($c->param('mtagcount') == 3);
ok(!$c->_checkmobile);
ok(!$c->ismobilecontent);

ok($mhtml eq $mhtml2);
