#!perl -T
use strict;
use warnings;
use Test::More tests => 25;
use Hatena::Keyword;
use utf8;

my $text = "Perl and Ruby";
my $keywords = Hatena::Keyword->extract($text);
ok ref($keywords);
ok scalar @$keywords;
isa_ok $keywords->[0], 'Hatena::Keyword';
can_ok $keywords->[0], qw(refcount word as_string score cname);
ok $keywords->[0] eq $keywords->[0]->as_string;
ok $keywords->[0] eq $keywords->[0]->word;
ok $keywords->[0]->refcount;
ok defined $keywords->[0]->score;
ok $keywords->[0]->cname;

my %result = map { $_ => $_ } @$keywords;
ok exists $result{Perl};
ok exists $result{Ruby};
isa_ok $result{Perl}, 'Hatena::Keyword';
isa_ok $result{Ruby}, 'Hatena::Keyword';
ok $result{Perl} eq "Perl";
ok $result{Ruby} eq "Ruby";

isa_ok $result{Perl}->jcode, 'Jcode';
ok $result{Perl}->jcode->euc, 'Perl';
ok $result{Perl}->jcode eq $result{Perl}->jcode;
ok $result{Perl}->jcode ne $result{Ruby}->jcode;

my $html = Hatena::Keyword->markup_as_html($text);

ok $html;
ok $html eq '<a href="http://d.hatena.ne.jp/keyword/Perl">Perl</a> and <a href="http://d.hatena.ne.jp/keyword/Ruby">Ruby</a>';

$html = Hatena::Keyword->markup_as_html($text, {
    a_class  => 'keyword',
    a_target => '_blank',
});

like $html, qr/class="keyword"/;
like $html, qr/target="_blank"/;

my $flagged_multibytes = "はてなとはてなブックマーク";
my $japanese = Hatena::Keyword->extract($flagged_multibytes);
ok ref $japanese;
ok scalar @$japanese;
