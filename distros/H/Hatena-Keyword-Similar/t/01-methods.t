#!perl -T
use strict;
use warnings;
use Test::More tests => 5;
use Hatena::Keyword::Similar;
use utf8;

my @words = qw(Perl Ruby ¤Ï¤Æ¤Ê);
my $keywords = Hatena::Keyword::Similar->similar(@words);
ok ref($keywords);
ok scalar @$keywords;
isa_ok $keywords->[0], 'Hatena::Keyword';

my @keywords = Hatena::Keyword::Similar->similar(@words);
ok scalar @keywords;
isa_ok $keywords[0], 'Hatena::Keyword';
