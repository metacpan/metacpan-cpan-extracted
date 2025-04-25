use v5.36;
use Test::More;
use FU::Validate;
use FU::Util 'json_format';

my $schema = FU::Validate->compile({ keys => {
    bool => { anybool => 1 },
    num => { num => 1 },
    int => { int => 1 },
    str => { default => 'x' },
    intarray => { elems => { int => 1 } },
    any => { type => 'any' },
}});


is json_format($schema->coerce(undef)), 'null';
is json_format($schema->coerce("str")), '"str"';

is json_format($schema->coerce({
        bool => 'abc',
        num => " 1.5 ",
        int => 9.7,
        str => !1,
        intarray => [ 1.5, -10, undef, ' 0E0 ' ],
        any => {},
        whatsthis => undef,
    }, unknown => 'remove'), canonical => 1),
    '{"any":{},"bool":true,"int":9,"intarray":[1,-10,null,0],"num":1.5,"str":""}';

is json_format($schema->coerce({uhm => 1}), canonical => 1),
    '{"any":null,"bool":false,"int":0,"intarray":[],"num":0,"str":"x","uhm":1}';

is json_format($schema->empty, canonical => 1),
    '{"any":null,"bool":false,"int":0,"intarray":[],"num":0,"str":"x"}';

done_testing;
