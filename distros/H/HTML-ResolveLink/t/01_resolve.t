use strict;
use Test::More tests => 9;
use HTML::ResolveLink;

my $base = "http://www.example.com/base/";
my $count = 0;
my $log;

my $resolver = HTML::ResolveLink->new(
    base => $base,
    callback => sub {
        my($uri, $old) = @_;
        $log .= "$old => $uri\n";
        $count++;
    },
);

my $html = $resolver->resolve(<<'HTML');
<a href="/foo">foo</a><img src="/bar.gif" alt="foo &amp; bar" /> foobar
<a href="mailto:foobar@example.com">hey &amp;</a>
<a href="foo.html" onclick="foobar()">bar</a><br />
<a href="http://www.example.net/">bar</a>
<!-- hello -->
HTML

is $html, <<'HTML';
<a href="http://www.example.com/foo">foo</a><img src="http://www.example.com/bar.gif" alt="foo &amp; bar" /> foobar
<a href="mailto:foobar@example.com">hey &amp;</a>
<a href="http://www.example.com/base/foo.html" onclick="foobar()">bar</a><br />
<a href="http://www.example.net/">bar</a>
<!-- hello -->
HTML

is $count, 3;
like $log, qr!/foo => http://www.example.com/foo!;
like $log, qr!bar.gif => http://www.example.com/bar.gif!;
like $log, qr!foo.html => http://www.example.com/base/foo.html!;

$count = 0;
$html = $resolver->resolve(<<'HTML');
<base href="http://www.google.com/">
<a href="baz">foo</a>
<base href="http://www.example.com/">
<a href="baz">foo</a>
HTML

is $html, <<'HTML', '<base>';
<base href="http://www.google.com/">
<a href="http://www.google.com/baz">foo</a>
<base href="http://www.example.com/">
<a href="http://www.example.com/baz">foo</a>
HTML
    ;

is $count, 2;
is $resolver->resolved_count, 2;

$resolver = HTML::ResolveLink->new(base => $base); # reset

$html = $resolver->resolve(<<'HTML');
<a href="baz">&amp;</a>
&quot;foo&quot;
HTML

is $html, <<'HTML', 'HTML entities';
<a href="http://www.example.com/base/baz">&amp;</a>
&quot;foo&quot;
HTML
    ;
