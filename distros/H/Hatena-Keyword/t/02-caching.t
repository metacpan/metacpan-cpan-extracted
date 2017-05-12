#!perl -T
use strict;
use warnings;
use Test::More;
use Hatena::Keyword;

BEGIN {
    eval {
        use File::Temp qw(tempdir);
        use Cache::File;
    };
    plan $@ ? (skip_all => 'It requires File::Temp and Cache::File for testing')
            : (tests => 10);
}

my $cache_root = tempdir(CLEANUP => 1);
my $cache = Cache::File->new(
    cache_root      => $cache_root,
    default_expires => "600 sec",
);

my $text = "Perl and Ruby";
my @result;
push @result, scalar Hatena::Keyword->extract($text, { cache => $cache });
push @result, scalar Hatena::Keyword->extract($text, { cache => $cache });

ok @result == 2;
ok $cache->count == 1;

push @result, scalar Hatena::Keyword->extract($text, {
    cache => $cache,
    score => 20,
});
ok @result == 3;
ok $cache->count == 2;

my @html;
$html[0] = Hatena::Keyword->markup_as_html($text, { cache => $cache });
$html[1] = Hatena::Keyword->markup_as_html($text, { cache => $cache });

ok @html == 2;
ok $html[0] eq $html[1];
ok $cache->count == 3;

$html[2] = Hatena::Keyword->markup_as_html($text, {
    cache    => $cache,
    score    => 20,
    a_class  => 'keyword',
    a_target => '_blank',
});

ok @html == 3;
ok not $html[2] eq $html[1];
ok $cache->count == 4;
