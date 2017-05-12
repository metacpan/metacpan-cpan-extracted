use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use Markdown::Pod::Test qw( get_pod markdown_to_pod );

my $file = 't/mkd/style-in-style.md';

is markdown_to_pod($file), get_pod( \*DATA ), "converting $file";

__DATA__
=encoding utf8

L<C<<< $this->method() >>>|http://example.org>.

L<I<emphasis>|http://example.org>.

I<L<emphasis|http://example.org>>.

L<B<strong>|http://example.org>.

B<L<strong|http://example.org>>.
