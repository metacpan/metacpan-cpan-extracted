use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MDTest;

md_like( "| h1 | h2 |\n|---|---|\n| a | b |\n",
    qr|<thead>.*<th>h1</th>.*</thead>|s, '<thead> wraps header row' );
md_like( "| h1 | h2 |\n|---|---|\n| a | b |\n",
    qr|<tbody>.*<td>a</td>.*</tbody>|s,  '<tbody> wraps body rows' );

{
    my $esc = "| a \\| b | c |\n|---|---|\n| 1 | 2 |\n";
    md_like( $esc, qr{<th>a \| b</th>}, 'escaped pipe kept as literal "|"' );
}

# Even without \\| support the rest of the row still parses.
{
    my $esc = "| a \\| b | c |\n|---|---|\n| 1 | 2 |\n";
    md_like( $esc, qr{<th>c</th>}, 'cell after escaped-pipe cell still parses' );
}

done_testing;
