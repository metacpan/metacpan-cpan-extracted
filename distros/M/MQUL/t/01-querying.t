#!/usr/bin/env perl

use lib './lib';
use Test2::V0;
use MQUL qw/doc_matches/;

# start by making sure doc_matches() fails when it needs to:
like(
    dies { doc_matches() },
    qr/requires a document hash-ref/,
    'doc_matches() fails when no document is given.'
);

like(
    dies { doc_matches('asdf') },
    qr/requires a document hash-ref/,
    'doc_matches() fails when a scalar is given for a document.'
);

like(
    dies { doc_matches( [ 1, 2, 3 ] ) },
    qr/requires a document hash-ref/,
    'doc_matches() fails when a non-hash reference is given for a document.'
);

like(
    dies { doc_matches( { asdf => 1 }, 1 ) },
    qr/expects a query hash-ref/,
    'doc_matches() fails when a scalar is given for the query.'
);

like(
    dies { doc_matches( { asdf => 1 }, [ 1, 2, 3 ] ) },
    qr/expects a query hash-ref/,
    'doc_matches() fails when a non-hash reference is given for the query.'
);

# let's make sure every document will match an empty query
ok( doc_matches( { asdf => 1 } ),
    'doc_matches() returns true when no query is given.' );
ok( doc_matches( { one => 1, two => 2 }, {} ),
    'doc_matches() returns true when an empty query is given.' );

# let's get to actual querying and start with simple equality and regex checks
ok(
    doc_matches( { string => 'yo yo', integer => 123 }, { string => 'yo yo' } ),
    'simple equality works'
);
ok( !doc_matches( { string => 'my name is nobody' }, { string => 'yo yo' } ),
    'simple equality does not match erroneously' );
ok(
    doc_matches( { string => 'my name is nobody' }, { string => qr/nobody$/ } ),
    'simple regex works'
);
ok( !doc_matches( { string => 'yo yo' }, { string => qr/nobody$/ } ),
    'simple regex does not match erroneously' );

# let's see if deep equality works
ok(
    doc_matches(
        { hash => { one => 1, two => 2 }, array => [ 1, 2, 3 ] },
        { hash => { one => 1, two => 2 } }
    ),
    'deep hash equality works'
);
ok(
    doc_matches(
        { hash  => { one => 1, two => 2 }, array => [ 1, 2, 3 ] },
        { array => [ 1, 2, 3 ] }
    ),
    'deep array equality works'
);
ok(
    doc_matches(
        { deep_hash => { nest => { bird => 'and stuff' } }, number => 123 },
        { number    => 123, deep_hash => { nest => { bird => 'and stuff' } } }
    ),
    'really deep hash works'
);

# now let's take a look at non-equality and $eq-style equality
ok(
    doc_matches(
        { should_eq => 'clint', should_not_eq => 'westwood' },
        {
            should_eq     => { '$eq' => 'clint' },
            should_not_eq => { '$ne' => 'eastwood' }
        }
    ),
    'simple non-equality works'
);

# okay, now we're gonna check every advanced operator one at a time
# 1. $gt
ok( doc_matches( { number => 2 }, { number => { '$gt' => 1 } } ),
    'simple $gt works' );
ok( !doc_matches( { number => 2 }, { number => { '$gt' => 3 } } ),
    'simple $gt does not match erroneously' );

# 2. $gte
ok(
    doc_matches(
        { float => 12.5,             integer => 23 },
        { float => { '$gte' => 11 }, integer => { '$gte' => 23 } }
    ),
    'simple $gte works'
);
ok(
    !doc_matches(
        { float => 12.5,             integer => 23 },
        { float => { '$gte' => 13 }, integer => { '$gte' => 23 } }
    ),
    'simple $gte does not match erroneously'
);

# 3. $lt
ok( doc_matches( { number => 4 }, { number => { '$lt' => 5 } } ),
    'simple $lt works' );
ok( !doc_matches( { number => 2 }, { number => { '$lt' => 2 } } ),
    'simple $lt does not match erroneously' );

# 4. $lte
ok( doc_matches( { number => 4 }, { number => { '$lte' => 4 } } ),
    'simple $lte works' );
ok(
    !doc_matches(
        { integer => 10,              float => 5.124 },
        { integer => { '$lte' => 8 }, float => { '$lte' => 5.124 } }
    ),
    'simple $lte does not match erroneously'
);

# 5. $exists
ok(
    doc_matches(
        { now       => 'for', something => 'completely' },
        { something => { '$exists' => 1 } }
    ),
    'simple $exists works'
);
ok(
    !doc_matches(
        { now       => 'for', something => 'completely' },
        { different => { '$exists' => 1 } }
    ),
    'simple $exists does not match erroneously'
);

# 6. not $exists
ok(
    doc_matches(
        { now       => 'for', something => 'completely' },
        { different => { '$exists' => 0 } }
    ),
    'simple not $exists works'
);
ok(
    !doc_matches(
        { now       => 'for', something => 'completely' },
        { something => { '$exists' => 0 } }
    ),
    'simple not $exists does not match erroneously'
);

# 7. $mod
ok(
    doc_matches(
        { two => 2,                      three => 3 },
        { two => { '$mod' => [ 2, 0 ] }, three => { '$mod' => [ 2, 1 ] } }
    ),
    'simple $mod works'
);
ok( !doc_matches( { five => 5 }, { five => { '$mod' => [ 2, 0 ] } } ),
    'simple $mod does not match erroneously' );

# 8. $in
ok(
    doc_matches(
        { monty => 'python' },
        { monty => { '$in' => [qw/cobra python viper/] } }
    ),
    'simple $in works'
);
ok( !doc_matches( { age => 23 }, { age => { '$in' => [ 1 .. 20 ] } } ),
    'simple $in does not match erroneously' );

# 9. $nin
ok(
    doc_matches(
        { monty => 'python' },
        { monty => { '$nin' => [qw/cobra viper asp/] } }
    ),
    'simple $nin works'
);
ok(
    !doc_matches(
        { monty => 'python' },
        { monty => { '$nin' => [qw/python viper cobra asp/] } }
    ),
    'simple $nin does not match erroneously'
);

# 10. $size
ok( doc_matches( { array => [ 1 .. 10 ] }, { array => { '$size' => 10 } } ),
    'simple $size works' );
ok( !doc_matches( { array => [1] }, { array => { '$size' => 10 } } ),
    'simple $size does not match erroneously' );

# 11. $all
ok(
    doc_matches(
        { snakes => [qw/python asp cobra viper/] },
        { snakes => { '$all' => [qw/python cobra/] } }
    ),
    'simple $all works'
);
ok(
    !doc_matches(
        { snakes => [qw/python asp/] },
        { snakes => { '$all' => [qw/python asp rattler/] } }
    ),
    'simple $all does not match erroneously'
);

# 12. $type
ok( doc_matches( { integer => 20 }, { integer => { '$type' => 'int' } } ),
    'positive integers match' );
ok( doc_matches( { integer => -20 }, { integer => { '$type' => 'int' } } ),
    'negative integers match' );
ok( doc_matches( { whole => 0 }, { whole => { '$type' => 'whole' } } ),
    'whole numbers match' );
ok( !doc_matches( { whole => -2 }, { whole => { '$type' => 'whole' } } ),
    'negative integers do not match as wholes' );
ok( doc_matches( { float => +1.23e99 }, { float => { '$type' => 'float' } } ),
    'positive floats match' );
ok( doc_matches( { float => -1.23e99 }, { float => { '$type' => 'float' } } ),
    'negative floats match' );
ok( doc_matches( { real => 12.51 }, { real => { '$type' => 'real' } } ),
    'positive real numbers match' );
ok( doc_matches( { real => -12.51 }, { real => { '$type' => 'real' } } ),
    'negative real numbers match' );
ok(
    doc_matches(
        { string => 'this is a string' },
        { string => { '$type' => 'string' } }
    ),
    'strings match'
);
ok(
    doc_matches( { array => [ 1 .. 4 ] }, { array => { '$type' => 'array' } } ),
    'arrays match'
);
ok(
    doc_matches(
        { hash => { one     => 1, two => 2 } },
        { hash => { '$type' => 'hash' } }
    ),
    'hashes match'
);
ok( doc_matches( { bool => 1 }, { bool => { '$type' => 'bool' } } ),
    'booleans match' );
ok(
    doc_matches(
        { date => '2003-02-15T13:50:05-05:00' },
        { date => { '$type' => 'date' } }
    ),
    'w3c formatted dates match'
);
ok( doc_matches( { null => undef }, { null => { '$type' => 'null' } } ),
    'nulls (undefs) match' );
ok( doc_matches( { regex => qr/\d+/ }, { regex => { '$type' => 'regex' } } ),
    'regexes match' );
ok( !doc_matches( { float => 20.51 }, { float => { '$type' => 'int' } } ),
    "floats don't match as integers" );
ok(
    doc_matches( { number => 0x1234 }, { number => { '$type' => 'string' } } ),
    "numbers can match as strings"
);
ok(
    !doc_matches( { array => [ 1 .. 5 ] }, { array => { '$type' => 'hash' } } ),
    "arrays don't match as hashes"
);
ok(
    !doc_matches( { date => '12.06.1984' }, { date => { '$type' => 'date' } } ),
    "improperly formatted dates don't match"
);
ok( !doc_matches( { null => '' }, { null => { '$type' => 'null' } } ),
    "false values don't match as nulls" );

# let's perform some complex queries
ok(
    doc_matches(
        {
            integer => 12,
            date    => '2011-06-07T14:30:00+03:00',
            things  => [ 'ball', 'bull', 'shit' ],
        },
        {
            integer => { '$gte' => 5, '$lte' => 12 },
            date => { '$type' => 'date', '$lt' => '2020-06-07T14:30:00+03:00' },
            things => { '$all' => ['shit'] },
        }
    ),
    'complex #1 okay'
);
ok(
    doc_matches(
        {
            and       => -12.5,
            now       => 'now',
            for       => { needs_more => 'cowbell' },
            something => [ { one => 1 }, { two => 2 } ],
            name      => 'Ido Perlmuter',
        },
        {
            and  => { '$type'   => 'float', '$lte' => 0 },
            now  => { '$exists' => 1 },
            then => { '$exists' => 0 },
            for  => { '$type'   => 'hash', '$size' => 1 },
            name => 'Ido Perlmuter',
        }
    ),
    'complex #2 okay'
);
ok(
    doc_matches(
        {
            type    => 'blog',
            name    => 'vlog',
            tags    => [qw/sex drugs rocknroll/],
            members => {
                ido   => 'admin',
                moses => 'leader',
                jesus => 'savior',
                misus => 'wife',
            },
            score => 8.5,
        },
        {
            type    => { '$in'   => [qw/newspaper blog forum lie/] },
            name    => { '$nin'  => [qw/something inappropriate and stuff/] },
            members => { '$type' => 'hash' },
            score   => { '$gte'  => 7, '$mod' => [ 5, 3 ] },
        }
    ),
    'complex #3 okay'
);

# let's try some $or queries
ok(
    doc_matches(
        { title => 'Freaks and Geeks' },
        {
            '$or' =>
              [ { title => 'Freaks and Geeks' }, { title => 'Undeclared' } ]
        }
    ),
    '$or #1 works'
);
ok(
    !doc_matches(
        { title => 'How I Met Your Mother' },
        {
            '$or' =>
              [ { title => 'Freaks and Geeks' }, { title => 'Undeclared' } ]
        }
    ),
    '$or #2 works'
);
ok(
    doc_matches(
        { one => 1 },
        {
            '$or' =>
              [ { one => { '$exists' => 1 } }, { two => { '$exists' => 1 } } ]
        }
    ),
    '$or #3 works'
);
ok(
    doc_matches(
        { two => 2 },
        {
            '$or' =>
              [ { one => { '$exists' => 1 } }, { two => { '$exists' => 1 } } ]
        }
    ),
    '$or #4 works'
);
ok(
    !doc_matches(
        { three => 3 },
        {
            '$or' =>
              [ { one => { '$exists' => 1 } }, { two => { '$exists' => 1 } } ]
        }
    ),
    '$or #5 works'
);
ok(
    doc_matches(
        {
            year  => 2010,
            genre => 'comedy',
        },
        {
            year  => { '$gt' => 2000 },
            '$or' => [ { genre => 'comedy' }, { genre => 'drama' }, ],
        }
    ),
    'or #6 works'
);
ok(
    !doc_matches(
        {
            year  => 2010,
            genre => 'mystery',
        },
        {
            year  => { '$gt' => 2000 },
            '$or' => [ { genre => 'comedy' }, { genre => 'drama' }, ],
        }
    ),
    'or #7 works'
);
ok(
    !doc_matches(
        {
            year  => 1990,
            genre => 'comedy',
        },
        {
            year  => { '$gt' => 2000 },
            '$or' => [ { genre => 'comedy' }, { genre => 'drama' }, ],
        }
    ),
    'or #8 works'
);
ok(
    doc_matches(
        {
            key_one   => 0,
            key_two   => 0,
            key_three => 'Something',
        },
        {
            '$or' => [
                { key_three => 'Cool' },
                {
                    key_one   => 0,
                    key_three => { '$in' => [ 'Someone', 'Something' ] },
                },
            ],
        }
    ),
    'or #9 works'
);

# let's try some $and queries
ok(
    doc_matches(
        { a => 5, b => 5 },
        {
            '$and' => [
                { '$or' => [ { a => 5 }, { b => 10 } ] },
                { '$or' => [ { a => 1 }, { b => 5 } ] }
            ]
        }
    ),
    'checking $and query #1'
);

ok(
    doc_matches(
        { a => 1, b => 2 },
        {
            '$and' => [ { a => { '$lt' => 2 } }, { b => { '$gt' => 1 } } ]
        }
    ),
    'checking $and query #2'
);

ok(
    !doc_matches(
        { a => 1, b => 2 },
        {
            '$and' => [ { a => 1 }, { b => 1 } ]
        }
    ),
    'checking $and query #3'
);

# let's try some functions
ok(
    doc_matches(
        { one => 1, two => 2, three => 3 },
        { min => 1 },
        [ min => { '$min' => [ 'one', 'two', 'three' ] } ]
    ),
    '$min works with simple equality'
);

ok(
    doc_matches(
        { one => 1, two => 2, three => 3 },
        { max => 3 },
        [ max => { '$max' => [ 'one', 'two', 'three' ] } ]
    ),
    '$max works with simple equality'
);

ok(
    doc_matches(
        { one => 1, two => 2, three => 3 },
        { max => { '$gt' => 2, '$lt' => 4 } },
        [ max => { '$max' => [ 'one', 'two', 'three' ] } ]
    ),
    '$max works with complex ranging'
);

ok(
    doc_matches(
        { some_value => -5.94 },
        { 'abs(some_value)' => { '$gte' => 5, '$lte' => 6 } },
        [ 'abs(some_value)' => { '$abs' => 'some_value' } ]
    ),
    '$abs works'
);

ok(
    doc_matches(
        { two     => 2, four => 4, eight => 8 },
        { product => 64 },
        [ product => { '$product' => [qw/two four eight/] } ]
    ),
    'product() works'
);

ok(
    doc_matches(
        { four => 4, two => 2 },
        { div  => 2 },
        [ div => { '$div' => [ 'four', 'two' ] } ]
    ),
    'div() works'
);

ok(
    doc_matches(
        { four => 4, zero => 0, three => 3 },
        { div  => 0 },
        [ div => { '$div' => [ 'four', 'zero', 'three' ] } ]
    ),
    'div() by zero returns zero'
);

ok(
    doc_matches(
        { four => 4, zero => 0, three => 3 },
        { sum  => 7 },
        [ sum => { '$sum' => [ 'four', 'zero', 'three' ] } ]
    ),
    'sum() works'
);

ok(
    doc_matches(
        { four => 4, grand => 1000, mfour => -4 },
        { diff => -992 },
        [ diff => { '$diff' => [qw/four grand mfour/] } ]
    ),
    'diff() works'
);

# let's try function nesting
ok(
    doc_matches(
        { one => 1, two => 2, three => 3 },
        { sum => 4 },
        [
            min => { '$min' => [ 'one', 'two', 'three' ] },
            max => { '$max' => [ 'one', 'two', 'three' ] },
            sum => { '$sum' => [ 'min', 'max' ] }
        ]
    ),
    'nested function #1 works'
);

ok(
    doc_matches(
        { ten => 10, nine => 9, three => 3, four => 4 },
        { abs => 20 },
        [
            diff1 => { '$diff' => [ 'three', 'four' ] },
            diff2 => { '$diff' => [ 'diff1', 'ten', 'nine' ] },
            abs   => { '$abs'  => 'diff2' }
        ]
    ),
    'nested function #2 works'
);

# what if we're running a function on non-existing values?
ok( !doc_matches( {}, { abs => 20 }, [ abs => { '$abs' => 'something' } ] ),
    'abs() on a non-existing value does not croak' );

ok(
    doc_matches(
        {},
        { min => { '$type' => 'null' } },
        [ min => { '$min' => [qw/one two three/] } ]
    ),
    'min() on non-existing values does not croak but returns null'
);

# let's check the dot notation
ok(
    doc_matches(
        { some => { thing => { very => { deep => 3 } }, other_thing => 1 } },
        { 'some.thing.very.deep' => { '$gt' => 2 } }
    ),
    'dot notation works on simple nested hash'
);

ok(
    doc_matches(
        { some                   => { thing     => 1 } },
        { 'some.thing.very.deep' => { '$exists' => 0 } }
    ),
    'dot notation doesn\'t die on long nesting that doesn\'t exist'
);

ok(
    doc_matches(
        { some         => { thing   => [ 1, 2, 3 ] } },
        { 'some.thing' => { '$size' => 3 } }
    ),
    'dot notation gets correct size of array'
);

ok( !doc_matches( { hey => { man => 1 } }, { 'hey.man.what' => 3 } ),
    'dot notation doesn\'t die on bad nesting' );

# let's try the dot notation with arrays
ok(
    doc_matches(
        { some           => { thing => [ 5, 0, 5 ] } },
        { 'some.thing.1' => { '$lt' => 1 } }
    ),
    'dot notation works with arrays #1'
);

ok(
    !doc_matches(
        { some           => { thing => [ 5, 0, 5 ] } },
        { 'some.thing.1' => { '$gt' => 1 } }
    ),
    'dot notation works with arrays #2'
);

ok(
    doc_matches(
        { some => { thing => [ { zero => 0 }, { one => 1 }, { two => 2 } ] } },
        { 'some.thing.1.one' => { '$exists' => 1 } }
    ),
    'dot notation works with arrays of hashes #1'
);

ok(
    !doc_matches(
        { some => { thing => [ { zero => 0 }, { one => 1 }, { two => 2 } ] } },
        { 'some.thing.1.zero' => { '$exists' => 1 } }
    ),
    'dot notation works with arrays of hashes #2'
);

ok(
    doc_matches(
        { one => { value => 3.25 }, two => { value => 5.75 } },
        {
            'two.value'   => { '$ne'     => 3.25 },
            'one.value'   => { '$type'   => 'float' },
            'one.missing' => { '$exists' => 0 }
        }
    ),
    'dot notation works with multiple complex queries'
);

ok(
    doc_matches(
        { one => { value => 3.25 }, two => { value => 5.75 } },
        {
            '$or' => [
                { 'one.value' => { '$gt' => 4 } },
                { 'two.value' => { '$gt' => 4 } }
            ]
        }
    ),
    'dot notation works with $or queries #1'
);

ok(
    !doc_matches(
        { one => { value => 3.25 }, two => { value => 5.75 } },
        {
            '$or' => [
                { 'one.value' => { '$gt' => 4 } },
                { 'two.value' => { '$gt' => 6 } }
            ]
        }
    ),
    'dot notation works with $or queries #2'
);

ok(
    doc_matches(
        { one => { value => -3.5 } },
        { abs => 3.5 },
        [ abs => { '$abs' => 'one.value' } ]
    ),
    'dot notation works with simple abs()'
);

ok(
    doc_matches(
        { one => { value => 3.25 }, two => { value => 5.75 } },
        { max => 5.75 },
        [ max => { '$max' => [ 'one.value', 'two.value' ] } ]
    ),
    'dot notation works with max() #1'
);

ok(
    !doc_matches(
        { one => { value => 3.25 }, two => { value => 5.75 } },
        { max => 3.25 },
        [ max => { '$max' => [ 'one.value', 'two.value' ] } ]
    ),
    'dot notation works with max() #2'
);

ok(
    doc_matches(
        {
            one => { array => [ { value => 1 } ] },
            two => { array => [ { value => 2 } ] }
        },
        { min => { '$gte' => 1, '$lt' => 2 } },
        [ min => { '$min' => [ 'one.array.0.value', 'two.array.0.value' ] } ]
    ),
    'dot notation works with functions and arrays #1'
);

ok(
    !doc_matches(
        {
            one => { array => [ { value => 1 } ] },
            two => { array => [ { value => 2 } ] }
        },
        { min => { '$gt' => 1, '$lt' => 2 } },
        [ min => { '$min' => [ 'one.array.0.value', 'two.array.0.value' ] } ]
    ),
    'dot notation works with functions and arrays #2'
);

ok(
    doc_matches(
        {
            some  => { thing => { very   => { deep => 3 } } },
            array => { of    => { hashes => [ { one => 1 }, { two => 2 } ] } }
        },
        {
            'array.of.hashes'   => { '$type' => 'array' },
            'array.of.hashes.0' => { '$type' => 'hash' }
        }
    ),
    'dot notation returns proper types'
);

ok(
    doc_matches(
        {
            numbers => {
                one   =>  35,
                two   => -65,
                three => 100
            },
            array_of_numbers => [ 80, 90 ]
        },
        { max => { '$gt' => 90 } },
        [ max => { '$max' => [ 'array_of_numbers.1', 'numbers.three' ] } ]
    ),
    'max with dot notation from different fields works'
);

done_testing();
