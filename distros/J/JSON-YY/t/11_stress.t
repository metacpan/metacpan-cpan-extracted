use strict;
use warnings;
use Test::More;
use JSON::YY qw(encode_json decode_json);
use JSON::YY ':doc';

# deeply nested
{
    my $depth = 100;
    my $json = '[' x $depth . '1' . ']' x $depth;
    my $data = decode_json($json);
    my $inner = $data;
    $inner = $inner->[0] for 1..$depth-1;
    is $inner->[0], 1, "decode $depth levels deep";

    my $doc = jdoc $json;
    # build path /0/0/0/.../0
    my $path = join('', map { "/0" } 1..$depth);
    is jgetp $doc, $path, 1, "Doc API $depth levels deep";
}

# wide array
{
    my $n = 10000;
    my $json = '[' . join(',', 1..$n) . ']';
    my $data = decode_json($json);
    is scalar @$data, $n, "decode $n element array";
    is $data->[-1], $n, "last element correct";

    my $doc = jdoc $json;
    is jlen $doc, "", $n, "Doc API $n element array length";
    is jgetp $doc, "/9999", $n, "Doc API last element";
}

# wide object
{
    my $n = 1000;
    my $json = '{' . join(',', map { qq("k$_":$_) } 1..$n) . '}';
    my $data = decode_json($json);
    is scalar keys %$data, $n, "decode $n key object";

    my $doc = jdoc $json;
    is jlen $doc, "", $n, "Doc API $n key object";
    is jgetp $doc, "/k500", 500, "Doc API middle key";
}

# large string values
{
    my $long = "x" x 100_000;
    my $json = encode_json({s => $long});
    my $back = decode_json($json);
    is length($back->{s}), 100_000, "100K string roundtrip";
}

# many iterations
{
    my $json = encode_json([map { {id => $_} } 1..1000]);
    my $doc = jdoc $json;
    my $it = jiter $doc, "";
    my $count = 0;
    while (defined(my $v = jnext $it)) { $count++ }
    is $count, 1000, "iterate 1000 elements";
}

# repeated doc creation/destruction (leak check)
{
    for (1..10000) {
        my $doc = jdoc '{"a":1}';
        jset $doc, "/b", 2;
        jencode $doc, "";
    }
    pass "10K doc create/modify/encode cycles without crash";
}

# repeated jfrom/jclone cycles
{
    for (1..5000) {
        my $doc = jfrom {x => [1,2,3], y => {z => "hello"}};
        my $copy = jclone $doc, "/x";
        jencode $copy, "";
    }
    pass "5K jfrom/jclone cycles without crash";
}

done_testing;
