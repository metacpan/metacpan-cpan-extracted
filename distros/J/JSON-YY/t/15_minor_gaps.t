use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use JSON::YY ':doc';
use JSON::YY qw(encode_json);

# NaN/Inf via OO pretty path
{
    my $c = JSON::YY->new(utf8 => 1, pretty => 1);
    eval { $c->encode(9**9**9) };
    like $@, qr/NaN|Inf/i, 'OO pretty encode Inf croaks';
    eval { $c->encode(-9**9**9) };
    like $@, qr/NaN|Inf/i, 'OO pretty encode -Inf croaks';
}

# jwrite on subtree Doc
{
    my ($fh, $tmp) = tempfile(SUFFIX => ".json");
    close $fh;
    my $doc = jdoc '{"a":{"x":1},"b":2}';
    my $sub = jget $doc, "/a";
    jwrite $sub, $tmp;
    my $back = jread $tmp;
    is jencode $back, "", '{"x":1}', 'jwrite subtree Doc writes only subtree';
    unlink $tmp;
}

# jset "" on borrowed Doc croaks
{
    my $doc = jdoc '{"a":1}';
    my $sub = jget $doc, "/a";
    eval { jset $sub, "", 42 };
    like $@, qr/borrowed/, 'jset empty path on borrowed Doc croaks';
}

# jraw "" on borrowed Doc croaks
{
    my $doc = jdoc '{"a":1}';
    my $sub = jget $doc, "/a";
    eval { jraw $sub, "", '42' };
    like $@, qr/borrowed/, 'jraw empty path on borrowed Doc croaks';
}

# jpatch/jmerge on borrowed Doc croaks
{
    my $doc = jdoc '{"a":1}';
    my $sub = jget $doc, "/a";
    my $patch = jdoc '[{"op":"add","path":"/x","value":1}]';
    eval { jpatch $sub, $patch };
    like $@, qr/borrowed/, 'jpatch on borrowed Doc croaks';

    eval { jmerge $sub, jdoc '{"x":1}' };
    like $@, qr/borrowed/, 'jmerge on borrowed Doc croaks';
}

# jpaths on scalar root
{
    my $doc = jdoc '"hello"';
    my @paths = jpaths $doc, "";
    is scalar @paths, 1, 'jpaths scalar root returns one path';
    is $paths[0], '', 'jpaths scalar root path is empty string';
}

# jpaths with nested empty container (leak regression test)
{
    my $doc = jdoc '{"a":{"empty_obj":{},"empty_arr":[]},"b":1}';
    my @paths = jpaths $doc, "";
    is_deeply [sort @paths], ['/b'], 'jpaths skips nested empty containers';
}

# jfind on non-array returns undef
{
    my $doc = jdoc '{"obj":{"a":1}}';
    my $r = jfind $doc, "/obj", "/a", 1;
    ok !defined $r, 'jfind on non-array returns undef';
}

# jfind with bool match
{
    my $doc = jdoc '[{"name":"a","active":true},{"name":"b","active":false}]';
    my $found = jfind $doc, "", "/active", "true";
    is jgetp $found, "/name", "a", 'jfind bool match true';
    my $found2 = jfind $doc, "", "/active", "false";
    is jgetp $found2, "/name", "b", 'jfind bool match false';
}

# jfind with key_path="" (match element itself)
{
    my $doc = jdoc '["alice","bob","carol"]';
    my $found = jfind $doc, "", "", "bob";
    is jgetp $found, "", "bob", 'jfind key_path="" matches element itself';
}

# overloading edge: stringify nested Doc
{
    my $doc = jdoc '{"a":{"b":1}}';
    my $sub = jget $doc, "/a";
    is "$sub", '{"b":1}', 'stringify borrowed Doc';
}

done_testing;
