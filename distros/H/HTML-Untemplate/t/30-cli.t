#!perl
use strict;
use utf8::all;
use warnings qw(all);

use Set::CrossProduct;
use Test::More;
use Test::Script::Run;

for my $script (qw(untemplate xpathify)) {
    subtest $script => sub {
        my ($ret, $stdout, $stderr) = run_script($script => [qw[--help]]);
        ok($ret == 1, qq($script --help));

        ($ret, $stdout, $stderr) = run_script($script => []);
        ok($ret == 1, qq($script (no args)));

        ($ret, $stdout, $stderr) = run_script($script => [qw[--badoption]]);
        ok($ret == 1, qq($script --badoption));

        my $files = $script eq q(untemplate) ? 2 : 1;

        ($ret, $stdout, $stderr) = run_script($script => [qw[--color --16] => qw[baddir/badfile.html] x $files]);
        ok($ret == 1, qq($script baddir/badfile.html));

        ($ret, $stdout, $stderr) = run_script($script => [qw[t/00-load.t] x $files]);
        ok($ret == 1, qq($script non-HTML));

        done_testing(5);
    };
}

run_output_matches(
    xpathify => [qw[t/test.html]],
    [
        qq(/html/head[1]/title[1]/text()\ttest 1),
        qq(/html/body[1]/h1[1]/text()\ttest 2),
        qq(/html/body[1]/p[1]/text()\t Lorem ipsum dolor sit amet, consectetur adipiscing elit. ),
        qq(/html/body[1]/p[1]/text()\t Ut sed scelerisque nulla. ),
        qq(//li[\@id='li1'][1]/text()\tVestibulum ullamcorper eleifend justo.),
        qq(/html/body[1]/p[1]/ul[1]/li[2]/text()\tSed id sapien tortor.),
        qq(/html/body[1]/p[1]/ul[1]/li[3]/text()\t Fusce et volutpat mi. ),
        qq(/html/body[1]/p[1]/ul[1]/li[4]/text()\tQuisque ullamcorper mauris lacus.),
        qq(/html/body[1]/p[1]/ul[1]/li[5]/text()\tNunc in erat sit amet nisi vulputate pharetra.),
        qq(/html/body[1]/p[1]/text()\t Nam sit amet massa ac justo lacinia cursus. Et harum quidem rerum facilis est et expedita distinctio. ),
        qq(/html/body[1]/p[2]/text()\t Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? ),
    ],
    [],
    q(xpathify output matches),
);

run_output_matches(
    xpathify => [qw[--encoding=latin1 --color --16 t/hello.html]],
    [qq(\\[1m\\[31m\/\\[0m\\[1m\\[94mhtml\\[0m\\[1m\\[31m\/\\[0m\\[1m\\[94mbody\\[0m\\[1m\\[36m\[\\[0m\\[1m\\[92m1\\[0m\\[1m\\[36m\]\\[0m\\[1m\\[31m\/\\[0m\\[1m\\[93mtext\(\)\\[0m\t\\[41m\ \\[0mHello\ World\!)],
    [],
    q(xpathify ANSI colorified output matches),
);

run_output_matches(
    untemplate => [qw[--encoding=latin1 --html --unmangle=DUMMY t/bash1839.html t/bash2486.html]],
    [map { chomp; $_ } <DATA>],
    [],
    q(untemplate output matches),
);

my $iterator = Set::CrossProduct->new([
    [qw[--color --nocolor --html]],
    [qw[--shrink --noshrink]],
    [qw[--strict --nostrict]],
    [qw[--weight --noweight]],
]);

my $m = 0;
for my $tuple ($iterator->combinations) {
    my $html = grep /html/, @{$tuple};
    run_output_matches(
        xpathify => [@{$tuple}, q(t/hello.html)],
        $html
            ? [
                qr(<![^>]+>),
                q(<html>),
                q(<head>),
                q(<title></title>),
                qr(<meta.*?>),
                qr(<link.*?>),
                qr(<link.*?>),
                q(</head>),
                q(<body>),
                q(<table summary="">),
                qr(Hello&nbsp;World!),
                q(</table>),
                q(</body>),
                q(</html>),
            ]
            : [qr(Hello\s+World!)],
        [],
    );
    ++$m;
}

$iterator = Set::CrossProduct->new([
    [qw[--color --nocolor --html]],
    [qw[--partial --nopartial]],
    [qw[--shrink --noshrink]],
    [qw[--strict --nostrict]],
]);

for my $tuple ($iterator->combinations) {
    run_ok(
        untemplate => [@{$tuple}, qw(t/bash1839.html t/bash2486.html)],
        q(untemplate ) . join(' ', @{$tuple}),
    );
    ++$m;
}

if ($ENV{RELEASE_USE_DOWNLOADER}) {
    run_script(
        xpathify => [qw(http://bash.org/?1839)],
        q(xpathify http://bash.org...),
    );
    run_script(
        xpathify => [qw(--encoding=latin1 http://google.com.br)],
        q(xpathify http://google.com.br...),
    );
    run_script(
        xpathify => [qw(http://255.255.255.255)],
        q(xpathify http://BAD_HOST),
    );
    run_script(
        untemplate => [qw(http://bash.org/?1839 http://bash.org/?2486 http://255.255.255.255/)],
        q(untemplate http://...),
    );
}

done_testing(5 + $m);

__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">
<html>
<head>
<title></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link rel="stylesheet" href="http://creaktive.github.com/HTML-Untemplate/highlight.css" type="text/css">
<link rel="stylesheet" href="highlight.css" type="text/css">
</head>
<body>
<table summary="">
<tr><td colspan="2"><span class="sep">/</span><span class="tag">html</span><span class="sep">/</span><span class="tag">head</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="tag">title</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="att">text()</span></td></tr>
<tr><td><span class="doc">bash1839.html</span></td><td>QDB:&nbsp;Quote&nbsp;#1839</td></tr>
<tr><td><span class="doc">bash2486.html</span></td><td>QDB:&nbsp;Quote&nbsp;#2486</td></tr>
<tr><td colspan="2" class="spacer"></td></tr>
<tr><td colspan="2"><span class="sep">/</span><span class="tag">html</span><span class="sep">/</span><span class="tag">body</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="tag">form</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="tag">center</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="tag">table</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="tag">tr</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="tag">td</span><span class="arr">[</span><span class="num">2</span><span class="arr">]</span><span class="sep">/</span><span class="tag">font</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="tag">b</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="att">text()</span></td></tr>
<tr><td><span class="doc">bash1839.html</span></td><td>Quote&nbsp;#1839</td></tr>
<tr><td><span class="doc">bash2486.html</span></td><td>Quote&nbsp;#2486</td></tr>
<tr><td colspan="2" class="spacer"></td></tr>
<tr><td colspan="2"><span class="sep">/</span><span class="sep">/</span><span class="tag">p</span><span class="arr">[</span><span class="sig">@</span><span class="att">class</span><span class="eql">=</span><span class="val">&#39;quote&#39;</span><span class="arr">]</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="tag">a</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="sig">@</span><span class="att">href</span></td></tr>
<tr><td><span class="doc">bash1839.html</span></td><td>?1839</td></tr>
<tr><td><span class="doc">bash2486.html</span></td><td>?2486</td></tr>
<tr><td colspan="2" class="spacer"></td></tr>
<tr><td colspan="2"><span class="sep">/</span><span class="sep">/</span><span class="tag">p</span><span class="arr">[</span><span class="sig">@</span><span class="att">class</span><span class="eql">=</span><span class="val">&#39;quote&#39;</span><span class="arr">]</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="tag">a</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="tag">b</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="att">text()</span></td></tr>
<tr><td><span class="doc">bash1839.html</span></td><td>#1839</td></tr>
<tr><td><span class="doc">bash2486.html</span></td><td>#2486</td></tr>
<tr><td colspan="2" class="spacer"></td></tr>
<tr><td colspan="2"><span class="sep">/</span><span class="sep">/</span><span class="tag">a</span><span class="arr">[</span><span class="sig">@</span><span class="att">class</span><span class="eql">=</span><span class="val">&#39;qa&#39;</span><span class="arr">]</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="sig">@</span><span class="att">href</span></td></tr>
<tr><td><span class="doc">bash1839.html</span></td><td>./?le=cc8456a913b26eb7364e4e9a94348d04&amp;rox=1839</td></tr>
<tr><td><span class="doc">bash2486.html</span></td><td>./?le=cc8456a913b26eb7364e4e9a94348d04&amp;rox=2486</td></tr>
<tr><td colspan="2" class="spacer"></td></tr>
<tr><td colspan="2"><span class="sep">/</span><span class="sep">/</span><span class="tag">p</span><span class="arr">[</span><span class="sig">@</span><span class="att">class</span><span class="eql">=</span><span class="val">&#39;quote&#39;</span><span class="arr">]</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="att">text()</span></td></tr>
<tr><td><span class="doc">bash1839.html</span></td><td>(245)</td></tr>
<tr><td><span class="doc">bash2486.html</span></td><td>(228)</td></tr>
<tr><td colspan="2" class="spacer"></td></tr>
<tr><td colspan="2"><span class="sep">/</span><span class="sep">/</span><span class="tag">a</span><span class="arr">[</span><span class="sig">@</span><span class="att">class</span><span class="eql">=</span><span class="val">&#39;qa&#39;</span><span class="arr">]</span><span class="arr">[</span><span class="num">2</span><span class="arr">]</span><span class="sep">/</span><span class="sig">@</span><span class="att">href</span></td></tr>
<tr><td><span class="doc">bash1839.html</span></td><td>./?le=cc8456a913b26eb7364e4e9a94348d04&amp;sox=1839</td></tr>
<tr><td><span class="doc">bash2486.html</span></td><td>./?le=cc8456a913b26eb7364e4e9a94348d04&amp;sox=2486</td></tr>
<tr><td colspan="2" class="spacer"></td></tr>
<tr><td colspan="2"><span class="sep">/</span><span class="sep">/</span><span class="tag">a</span><span class="arr">[</span><span class="sig">@</span><span class="att">class</span><span class="eql">=</span><span class="val">&#39;qa&#39;</span><span class="arr">]</span><span class="arr">[</span><span class="num">3</span><span class="arr">]</span><span class="sep">/</span><span class="sig">@</span><span class="att">href</span></td></tr>
<tr><td><span class="doc">bash1839.html</span></td><td>./?le=cc8456a913b26eb7364e4e9a94348d04&amp;sux=1839</td></tr>
<tr><td><span class="doc">bash2486.html</span></td><td>./?le=cc8456a913b26eb7364e4e9a94348d04&amp;sux=2486</td></tr>
<tr><td colspan="2" class="spacer"></td></tr>
<tr><td colspan="2"><span class="sep">/</span><span class="sep">/</span><span class="tag">p</span><span class="arr">[</span><span class="sig">@</span><span class="att">class</span><span class="eql">=</span><span class="val">&#39;qt&#39;</span><span class="arr">]</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="att">text()</span></td></tr>
<tr><td><span class="doc">bash1839.html</span></td><td>&lt;maff&gt;&nbsp;who&nbsp;needs&nbsp;showers&nbsp;when&nbsp;you&#39;ve&nbsp;got&nbsp;an&nbsp;assortment&nbsp;of&nbsp;feminine&nbsp;products</td></tr>
<tr><td><span class="doc">bash2486.html</span></td><td>&lt;R`:#heroin&gt;&nbsp;Is&nbsp;this&nbsp;for&nbsp;recovery&nbsp;or&nbsp;indulgence?</td></tr>
<tr><td colspan="2" class="spacer"></td></tr>
<tr><td colspan="2"><span class="sep">/</span><span class="sep">/</span><span class="tag">tr</span><span class="arr">[</span><span class="num">2</span><span class="arr">]</span><span class="sep">/</span><span class="tag">td</span><span class="arr">[</span><span class="sig">@</span><span class="att">class</span><span class="eql">=</span><span class="val">&#39;footertext&#39;</span><span class="arr">]</span><span class="arr">[</span><span class="num">1</span><span class="arr">]</span><span class="sep">/</span><span class="att">text()</span></td></tr>
<tr><td><span class="doc">bash1839.html</span></td><td>0.0070</td></tr>
<tr><td><span class="doc">bash2486.html</span></td><td>0.0166</td></tr>
<tr><td colspan="2" class="spacer"></td></tr>
</table>
</body>
</html>
