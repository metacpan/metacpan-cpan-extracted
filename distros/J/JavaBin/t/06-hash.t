use strict;
use utf8;
use warnings;

use JavaBin;
use Test::More;

binmode Test::More->builder->$_, ':utf8' for qw/failure_output output todo_output/;

my @tests = (
    '{}'                   => "\2\12\0",
    '{ foo => "bar" }'     => "\2\12\1\0\43\146\157\157\43\142\141\162",
    '{ foo => {} }'        => "\2\12\1\0\43\146\157\157\12\0",
    '{ "☃" => "snowman" }' => "\2\12\1\0\43\342\230\203\47\163\156\157\167\155\141\156",
);

for ( my $i = 0; $i < @tests; $i += 2 ) {
    my ( $name, $bin ) = @tests[$i, $i + 1];

    my $ref = eval $name;

    is to_javabin($ref), $bin, "  to_javabin $name";

    is_deeply from_javabin($bin), $ref, "from_javabin $name";
}

done_testing;
