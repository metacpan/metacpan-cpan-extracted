use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use JSON::YY ':doc';

# jread
{
    my ($fh, $tmp) = tempfile(SUFFIX => ".json");
    print $fh '{"x":1,"arr":[2,3]}';
    close $fh;

    my $doc = jread $tmp;
    is ref $doc, 'JSON::YY::Doc', 'jread returns Doc';
    is jgetp $doc, "/x", 1, 'jread content';
    is jlen $doc, "/arr", 2, 'jread array';

    unlink $tmp;
}

# jread error
{
    eval { jread "/nonexistent/path/file.json" };
    like $@, qr/jread/, 'jread missing file croaks';
}

# jwrite + roundtrip
{
    my ($fh, $tmp) = tempfile(SUFFIX => ".json");
    close $fh;

    my $doc = jdoc '{"a":1,"b":[true,null]}';
    jwrite $doc, $tmp;

    my $doc2 = jread $tmp;
    ok jeq $doc, $doc2, 'jwrite/jread roundtrip preserves content';

    unlink $tmp;
}

# jwrite pretty format
{
    my ($fh, $tmp) = tempfile(SUFFIX => ".json");
    close $fh;

    my $doc = jdoc '{"k":"v"}';
    jwrite $doc, $tmp;

    open my $rfh, '<', $tmp or die;
    my $content = do { local $/; <$rfh> };
    close $rfh;
    like $content, qr/\n/, 'jwrite produces pretty output';

    unlink $tmp;
}

# jpaths
{
    my $doc = jdoc '{"a":1,"b":{"c":2,"d":[3,4]},"e":"hi"}';
    my @paths = jpaths $doc, "";
    is_deeply [sort @paths], ['/a', '/b/c', '/b/d/0', '/b/d/1', '/e'],
        'jpaths all leaves';

    my @sub = jpaths $doc, "/b";
    is_deeply [sort @sub], ['/b/c', '/b/d/0', '/b/d/1'],
        'jpaths subtree';
}

# jpaths empty containers — no leaf children, so no paths returned
{
    my $doc = jdoc '{"arr":[],"obj":{}}';
    my @paths = jpaths $doc, "";
    is scalar @paths, 0, 'jpaths empty containers have no leaf paths';
}

# jpaths with special chars in keys (~ and / escaping)
{
    my $doc = jdoc '{"a/b":1,"c~d":2}';
    my @paths = jpaths $doc, "";
    my @sorted = sort @paths;
    is $sorted[0], '/a~1b', 'jpaths escapes / as ~1';
    is $sorted[1], '/c~0d', 'jpaths escapes ~ as ~0';
}

# jfind
{
    my $doc = jdoc '[{"name":"Alice","age":30},{"name":"Bob","age":25},{"name":"Carol","age":35}]';

    my $bob = jfind $doc, "", "/name", "Bob";
    is ref $bob, 'JSON::YY::Doc', 'jfind returns Doc';
    is jgetp $bob, "/age", 25, 'jfind correct element';

    my $old = jfind $doc, "", "/age", 35;
    is jgetp $old, "/name", "Carol", 'jfind by number';

    my $nope = jfind $doc, "", "/name", "Nobody";
    ok !defined $nope, 'jfind returns undef on miss';
}

# jfind nested path
{
    my $doc = jdoc '{"items":[{"meta":{"id":"x1"}},{"meta":{"id":"x2"}}]}';
    my $found = jfind $doc, "/items", "/meta/id", "x2";
    is jencode $found, "/meta/id", '"x2"', 'jfind nested key path';
}

done_testing;
