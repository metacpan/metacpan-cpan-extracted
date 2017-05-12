use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use Markdown::Pod::Test qw( get_pod markdown_to_pod );

my $file = 't/mkd/github-3-weird-ordered-lists.mkd';
is markdown_to_pod($file), get_pod( \*DATA ), "converting $file";

__DATA__
=encoding utf8

=over

=item 1.

This should be understood as an ordered list.


=item 2.

The output numbers should increase, even though every written number is "1".


=item 3.

That's just how Markdown is!


=back

Here's a paragraph just to break things up.

=over

=item 1.

This should also be understood as an ordered list.


=item 2.

The numbers should increase, starting from 1, even though the written numbers are weird.


=item 3.

That's again just how Markdown is!


=back
