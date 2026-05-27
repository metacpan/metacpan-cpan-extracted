use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

my $tbl = <<'MD';
| L | C | R |
|:--|:-:|--:|
| a | b | c |
MD

md_like( $tbl, qr|<th[^>]*\balign="left"[^>]*>L</th>|i,
    'left-aligned column' );
md_like( $tbl, qr|<th[^>]*\balign="center"[^>]*>C</th>|i,
    'center-aligned column' );
md_like( $tbl, qr|<th[^>]*\balign="right"[^>]*>R</th>|i,
    'right-aligned column' );
md_like( $tbl, qr|<td[^>]*\balign="center"[^>]*>b</td>|i,
    'cell alignment inherited from column' );

done_testing;
