use 5.10.0;

use strict;
use warnings;

use Test::More;

use JSON;

use JSON::Schema::AsType::Draft4::Types '-all';

test_type( Minimum[5], [ 6, 'banana', 5 ], [ 4 ] );
test_type( ExclusiveMinimum[5], [ 6, 'banana' ], [ 5, 4 ] );

test_type( Maximum[5], [ 4, 'banana', 5 ], [ 6 ] );
test_type( ExclusiveMaximum[5], [ 4, 'banana' ], [ 5, 6 ] );

test_type( MinLength[5], [ 'banana', {} ], [ 'foo' ] );
test_type( MaxLength[5], [ 'foo', {} ], [ 'banana' ] );

test_type( MultipleOf[5], [ 10, 'banana' ], [ 3 ] );

test_type( MaxItems[2], [ 10, [1] ], [ [1..3] ] );
test_type( MinItems[2], [ 10, [1..2] ], [ [1] ] );

subtest types => sub {
    test_type( Null, [ undef ], [ 'banana' ] );

    test_type( Boolean, [ JSON::true, JSON::false ], [ 1 ] );

    test_type( Array, [ [] ], [ 1 ] );

    test_type( Object, [ {} ], [ [], 1 ] );

    test_type( String, [ "foo" ], [ [] ] );

    test_type( Integer, [ 1 ], [ 1.3, [], "foo", JSON::true ] );

    test_type( Number, [ 1, 1.3 ], [ [], "foo", JSON::true ] );

    test_type( Pattern[qr/foo/], [ 'fool', 'foo' ], [ 'potato' ] );
};

test_type( Required['foo'],
    [ { foo => 1 }, [], 1 ], [ { bar => 1 } ]
);
test_type( Required['foo','bar'],
    [ { foo => 1, bar => 1 }, 1, [] ], [ { bar => 1 } ]
);

test_type( Not[Integer],
    [ { foo => 1 }, "banana" ], [ 1 ]
);

test_type( MaxProperties[2],
    [ { foo => 1 }, "banana" ], [ { 1..6} ]
);

test_type( MinProperties[2],
    [ { foo => 1, bar => 2 }, "banana" ], [ { 1..2} ]
);

test_type( OneOf[ Integer, Boolean ],
    [ 1, JSON::true ], [ "banana", [] ] );

test_type( OneOf[ MaxLength[7], MaxLength[6] ],
  undef, [ "banana" ] );

test_type( AnyOf[ MaxLength[7], MaxLength[6] ],
    [ "banana" ] );

test_type( AnyOf[ Integer, Boolean ],
    [ 1, JSON::true ], [ "banana", [] ] );

test_type( AllOf[ MaxLength[5], MinLength[2] ],
    [ "fool", [] ], [ "banana" ] );

test_type(
    Items[ Number ],
    [ [1], [1,2] ], [ ["banana"], [1,"foo"] ],
);

test_type(
    AdditionalItems[ 1, Number ],
    [ [1], [1,2], ["banana"] ], [ [1..3,'x'] ],
);


test_type(
    PatternProperties[ f => Number, b => Array ],
    [ { foo => 1 }, { bar => [] } ], [ { foo => 'x' } ]
);

test_type(
    Dependencies[ foo => ['bar'], baz => MaxProperties[2] ],
    [ { foo => 1, bar => 1 }, { baz => [] } ], [ { foo => 'x' }, { baz => 1, 1..4 } ]
);

test_type(
    Enum[ 'foo', { x => 1 } ],
    [ 'foo', { x => 1 } ], [ { foo => 'x' }, { baz => 1, x => 1 } ]
);

test_type(
    Enum[ 1..3 ],
    [ 1 ]
);

test_type( UniqueItems,
    [ [1..4] ], [ [1,1,2,3] ] );

test_type(
    Properties[ foo => Number, bar => Array ],
    [ { foo => 1 }, { bar => [] } ], [ { foo => 'x' } ]
);

test_type(
    AdditionalProperties[ [ 'foo', qr/b/ ], 0 ],
    [ { foo => 1 }, { bar => [] } ], [ { quux => 'x' } ]
);

subtest anyof => sub {
    my $type = AnyOf[ Integer, Minimum[2] ];
    ok !$type->check(1.5);
};

subtest not => sub {
    my $type = Not[ Integer ];
#    use Types::Standard 'Int';
#    my $type = Int & Number & ~ Boolean;
#    ok $type->check(1);
    ok !$type->check(1);
};

done_testing;

sub test_type {
    my( $type, $good, $bad ) = @_;

    subtest $type => sub {

        subtest 'valid values' => sub {
            for my $test ( @$good ) {
                ok $type->check($test), join '', 'value: ', explain $test;
            }
        } if $good;

        subtest 'bad values' => sub {
            my $printed = 0;
            for my $test ( @$bad ) {
                my $error = $type->validate($test);
                ok $error, join '', 'value: ', explain $test;
                diag $error unless $printed++;
            }
        } if $bad;
    };

}
