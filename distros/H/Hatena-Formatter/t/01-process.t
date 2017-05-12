#!perl -T
use strict;
use warnings;
use Hatena::Formatter;
use Test::More tests => 2;

my $text = qq(*contents
[HomePage]
Perl5 or Pugs?
>||
<block>
Perl5 or Pugs?
id:yappo
||<
id:yappo
);
my $ret1 = qq(<div class="section">
\t<h3><a href="http://example.org/#p1" name="p1"><span class="sanchor">@</span></a> contents</h3>
\t<p>[HomePage]</p>
\t<p>Perl5 or <a class="keyword" href="http://d.hatena.ne.jp/keyword/Pugs">Pugs</a>?</p>
\t<pre class="hatena-super-pre">
&lt;block&gt;
Perl5 or Pugs?
id:yappo
</pre>
\t<p><a href="/yappo/">id:yappo</a></p>
</div>);

my $ret2 = qq(<div class="section">
\t<h3><a href="http://example.org/#p1" name="p1"><span class="sanchor">@</span></a> contents</h3>
\t<p><a href="?HomePage">HomePage</a></p>
\t<p>Perl5 or <a class="keyword" href="http://d.hatena.ne.jp/keyword/Pugs">Pugs</a>?</p>
\t<pre class="hatena-super-pre">
&lt;block&gt;
Perl5 or Pugs?
id:yappo
</pre>
\t<p><a href="?yappo">id:yappo</a></p>
</div>);

my $formatter1 = Hatena::Formatter->new(
    text_config => {
        sectionanchor => '@',
        permalink => 'http://example.org/',
    },
    keyword_config => {
    },
);
$formatter1->process($text);
ok($formatter1->html eq $ret1);

my $formatter2 = Hatena::Formatter->new(
    text_config => {
        sectionanchor => '@',
        permalink => 'http://example.org/',
        hatenaid_href => '?%s',
    },
    keyword_config => {
        score => 0,
    },
);
$formatter2->register( hook => 'text_finalize', callback => sub {
    my($context, $option) = @_;
    my $html = $context->html;
    $html =~ s{\[(\w+)\]}{
        my $target = $1;
        qq(<a href="?$target">$target</a>);
    }gsme;
    $context->html($html);
});
$formatter2->process($text);
ok($formatter2->html eq $ret2);
