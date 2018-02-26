use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use Markdown::Pod::Test qw( get_pod markdown_to_pod );

my $file = 't/mkd/github-7-nested-lists.mkd';
is markdown_to_pod($file), get_pod( \*DATA ), "converting $file";

__DATA__
=encoding utf8

=over

=item *

Fruits

=over

=item *

Apples


=item *

Oranges


=back



=item *

Vegetables

=over

=item *

Carrots


=item *

Peppers

=over

=item *

Chili Peppers


=item *

Bell Peppers


=back



=item *

Lettuce


=back



=back
