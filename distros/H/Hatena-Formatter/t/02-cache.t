#!perl -T
use strict;
use warnings;
use Hatena::Formatter;
use Test::More;

BEGIN {
    eval {
        use File::Temp qw(tempdir);
        use Cache::File;
    };
    plan $@ ? (skip_all => 'It requires File::Temp and Cache::File for testing')
            : (tests => 1);
}

my $cache_root = tempdir(CLEANUP => 1);
my $cache = Cache::File->new(
    cache_root      => $cache_root,
    default_expires => "600 sec",
);

my $text = qq(*contents
[HomePage]
Perl5 or Pugs?
>||
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
Perl5 or Pugs?
id:yappo
</pre>
\t<p><a href="/yappo/">id:yappo</a></p>
</div>);

my $formatter1 = Hatena::Formatter->new(
    text_config => {
        sectionanchor => '@',
        permalink => 'http://example.org/',
    },
    keyword_config => {
        cache => $cache,
    },
);
$formatter1->process($text);

my $formatter2 = Hatena::Formatter->new(
    text_config => {
        sectionanchor => '@',
        permalink => 'http://example.org/',
    },
    keyword_config => {
        cache => $cache,
    },
);
$formatter2->process($text);

ok($formatter2->html eq $ret1);
