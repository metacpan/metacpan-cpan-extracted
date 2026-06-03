use strict;
use warnings;
use Test::More;
use JSON::YY qw(decode_json_ro);

# decode_json_ro returns zero-copy values that borrow string bytes from the
# underlying yyjson_doc. A *reference* taken to a nested value must keep that
# doc alive even after the top-level container is freed -- otherwise the
# borrowed bytes dangle (use-after-free). Each borrowing SV carries magic
# anchoring the doc, so these patterns must stay valid. We churn the heap
# after freeing the container to clobber any prematurely-freed doc memory,
# so a regression shows up as wrong data rather than passing by luck.

sub churn {
    my @junk = map { decode_json_ro qq{["junk-$_-padding-padding-padding-padding"]} } 1 .. 300;
    my $filler = join '', map { 'x' x 64 } 1 .. 100;
    return scalar(@junk) + length($filler);
}

# 1. reference to a nested hash->array element
{
    my $ref;
    {
        my $data = decode_json_ro '{"items":["alpha","bravo","charlie"],"name":"widget"}';
        $ref = \$data->{items}[1];
        is $$ref, 'bravo', 'nested ref correct while container alive';
    }
    churn();
    is $$ref, 'bravo', 'nested ref still valid after container freed + heap churn';
}

# 2. reference to a top-level array element
{
    my $ref;
    {
        my $arr = decode_json_ro '["hello","world","again"]';
        $ref = \$arr->[2];
    }
    churn();
    is $$ref, 'again', 'array element ref survives container free';
}

# 3. a nested aggregate (sub-hash) outliving the root container
{
    my $sub;
    {
        my $data = decode_json_ro '{"a":{"deep":"kept-value"},"b":2}';
        $sub = $data->{a};   # RV to the inner hash; its string anchors the doc
    }
    churn();
    is $sub->{deep}, 'kept-value', 'nested aggregate survives root free';
}

# 4. value copied out by assignment is independent (existing contract)
{
    my $copy;
    {
        my $d = decode_json_ro '{"k":"copied"}';
        $copy = $d->{k};
    }
    churn();
    is $copy, 'copied', 'copy-on-extract value independent of doc';
}

done_testing;
