use strict;
use warnings;

use JavaBin;
use Test::More;

my @tests = (
    '[]'                => "\2\200",
    '[0..9]'            => "\2\212" . join( '', map { "\3" . pack 'c' , $_ } 0.. 9 ),
    '[qw/foo bar baz/]' => "\2\203\43\146\157\157\43\142\141\162\43\142\141\172",
);

for ( my $i = 0; $i < @tests; $i += 2 ) {
    my ( $name, $bin ) = @tests[$i, $i + 1];

    my $ref = eval $name;

    is to_javabin($ref), $bin, "  to_javabin $name";

    is_deeply from_javabin($bin), $ref, "from_javabin $name";
}

done_testing;
