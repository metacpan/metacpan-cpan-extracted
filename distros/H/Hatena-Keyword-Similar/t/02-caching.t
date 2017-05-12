#!perl -T
use strict;
use warnings;
use Test::More;
use Hatena::Keyword::Similar;

BEGIN {
    eval {
        use File::Temp qw(tempdir);
        use Cache::File;
    };
    plan $@ ? (skip_all => 'It requires File::Temp and Cache::File for testing')
            : (tests => 6);
}

my $cache_root = tempdir(CLEANUP => 1);
my $cache = Cache::File->new(
    cache_root      => $cache_root,
    default_expires => "600 sec",
);

my @words = qw(Perl Ruby);
my @result;
push @result, scalar Hatena::Keyword::Similar->similar(@words, { cache => $cache });
push @result, scalar Hatena::Keyword::Similar->similar(@words, { cache => $cache });

ok @result == 2;
ok $cache->count == 1;
is join('', @{$result[0]}), join('', @{$result[1]});

@words = qw(Perl Python Ruby);
push @result, scalar Hatena::Keyword::Similar->similar(@words, { cache => $cache });

ok @result == 3;
ok $cache->count == 2;
isnt join('', @{$result[1]}), join('', @{$result[2]});

