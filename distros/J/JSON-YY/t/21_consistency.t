use strict;
use warnings;
use Test::More;
use JSON::YY ':doc';

# NB: the Doc keywords are list operators -- call them without parentheses.

# decode_doc honors allow_nonref, matching decode() (0.06 consistency fix).
# decode_doc is an OO method, so normal paren calls are fine here.
{
    my $c = JSON::YY->new;                       # allow_nonref on by default
    ok defined($c->decode_doc('42')),
        'decode_doc: scalar root ok with allow_nonref on (default)';

    $c->allow_nonref(0);
    eval { $c->decode_doc('42') };
    like $@, qr/object or array/,
        'decode_doc: croaks on scalar root with allow_nonref off';
    ok defined(eval { $c->decode_doc('[1]') }),
        'decode_doc: array root still ok with allow_nonref off';
    my $obj = $c->decode_doc('{"a":1}');
    is "$obj", '{"a":1}',
        'decode_doc: object root ok with allow_nonref off';
}

# jtype returns undef on a missing path (documented soft return)
{
    my $doc = jdoc '{"a":1,"b":[2,3]}';
    my $ta = jtype $doc, "/a";
    my $tb = jtype $doc, "/b";
    my $tn = jtype $doc, "/nope";
    is $ta, "number", 'jtype: present scalar';
    is $tb, "array",  'jtype: present array';
    is $tn, undef,    'jtype: undef on missing path';
}

# jdel croaks on an empty path (root cannot be deleted); undef on missing
{
    my $doc = jdoc '{"a":1}';
    eval { jdel $doc, "" };
    like $@, qr/cannot delete root/, 'jdel: croaks on empty (root) path';
    my $miss = jdel $doc, "/nope";
    is $miss, undef, 'jdel: undef on missing path';
    my $removed = jdel $doc, "/a";
    ok defined($removed), 'jdel: returns removed subtree';
}

done_testing;
