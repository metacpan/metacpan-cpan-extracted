#!perl -T

use warnings;

use Test::More tests => 3;

use HTML::ListScraper::Book;

my $book = HTML::ListScraper::Book->new();
ok(!$book->shapeless);
ok($book->is_unclosed_tag('br'));

my $i = 0;
while ($i < 3) {
    $book->push_item('br');
    ++$i;
}

ok($book->is_presentable(0, 3));
