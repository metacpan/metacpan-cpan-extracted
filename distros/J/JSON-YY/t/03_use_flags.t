use strict;
use warnings;
use Test::More;

# test use-flags in a separate package to avoid polluting main
{
    package TestPkg;
    use JSON::YY -utf8, -pretty;
    use Test::More;

    my $json = encode_json({a => 1});
    like $json, qr/\n/, 'use -utf8 -pretty exports configured encode_json';

    my $data = decode_json('{"a":1}');
    is_deeply $data, {a => 1}, 'use -utf8 -pretty exports configured decode_json';
}

# test plain export still works
{
    package TestPkg2;
    use JSON::YY qw(encode_json decode_json);
    use Test::More;

    my $json = encode_json({b => 2});
    is $json, '{"b":2}', 'plain export encode_json works';

    my $data = decode_json('{"b":2}');
    is_deeply $data, {b => 2}, 'plain export decode_json works';
}

# A qw() import sets the keyword hint, which the compiler prefers over the
# closure the flag form installs -- so the flags were silently dropped.
{
    package TestPkg3;
    use JSON::YY qw(encode_json);
    use JSON::YY -pretty;
    use Test::More;

    like encode_json({a => 1}), qr/\n/,
        'a -flag import after a qw() import still takes effect';
}

# flags-only in a nested scope
{
    package TestPkg4;
    use Test::More;
    {
        use JSON::YY -pretty;
        like encode_json({a => 1}), qr/\n/, '-flag import inside a block works';
    }
}

done_testing;
