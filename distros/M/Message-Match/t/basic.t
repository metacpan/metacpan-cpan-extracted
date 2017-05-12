#!env perl

use strict;use warnings;

use lib '../lib';
use Test::More;

use_ok('Message::Match', 'mmatch');

#not nested
ok mmatch({a => 'b'},{a => 'b'}), 'simplest possible';
ok mmatch({a => 'b', c => 'd'},{a => 'b'}), 'extra stuff';
ok !mmatch({a => 'b', c => 'd'},{e => 'f'}), 'simple miss';
ok mmatch({a => 'b', c => 'd'},{a => 'b', c => 'd'}), 'simplest possible, multi match required';

#nested
ok mmatch({x => {y => 'z'}},{x => {y => 'z'}}), 'simplest nested';
ok mmatch({a => 'b', x => {y => 'z'}},{x => {y => 'z'}}), 'simplest nested with extra stuff';
ok mmatch({a => 'b', x => {y => 'z'}},{x => {y => 'z'}, a => 'b'}), 'multiple matches required, nested';

#array in message, scalar in match: checks membership
ok mmatch({a => [1,2,3]},{a => 2}), 'array contains';
ok !mmatch({a => [1,2,3]},{a => 5}), 'array does not contain';

#array on both sides: full recursion
ok mmatch({a => [1,2,3]},{a => [1,2,3]}), 'array full match';
ok mmatch(
    {   a => [
            {a => 'b'},
            2,
            3
        ]
    },{ a => [
            {a=>'b'},
            2,
            3
        ]
    }), 'nested array full match';

#regex
ok mmatch({a => 'forefoot'},{a => ' special/foo/'}), 'simplest regex';
ok !mmatch({a => 'forefoot'},{a => ' special/smurf/'}), 'simplest regex failure';
ok !mmatch({a => 'forefoot'},{a => ' special/FOO/'}), 'regex failure for case sensitivity';
ok mmatch({a => 'forefoot'},{a => ' special/FOO/i'}), 'regex pass for case sensitivity';

#special form: match is empty hashref
ok mmatch({a => 'b'},{}), 'always pass with match as an empty hashref';
ok mmatch({},{}), 'ALWAYS pass with match as an empty hashref';
ok mmatch({a => {b => 'c'}},{a => {}}), 'validate the ALWAYS pass works nested';
ok !mmatch({a => {b => 'c'}},{a => {}, x => 'y'}), 'validate the ALWAYS pass, if nested, does not over-ride a failure elsewhere';
ok mmatch({a => {b => 'c'}},{}), 'always pass should pass even against a deeper structure';
ok mmatch({a => {b => 'c'}},{a => {}}), 'always pass should pass even against a deeper structure: nested';

#strangeness
ok mmatch({a => ''},{a => ''}), 'pass empty strings';
ok !mmatch({a => ''},{a => 0}), 'fail two things that are both false but different';
eval {
    mmatch({a => 'forefoot'},{a => ' specialhuhFOO/i'});
};
ok $@, 'special form of unknown type throws';
ok $@ =~ /special of unknown type passed:/, 'special form of unknown type throws correct exception';

#front-door errors
eval {
    mmatch();
};
ok $@, 'no arguments not allowed';
ok $@ =~ /two HASH references required/, 'no arguments throw the correct exception';

eval {
    mmatch({});
};
ok $@, 'one argument not allowed';
ok $@ =~ /two HASH references required/, 'one argument throws the correct exception';

eval {
    mmatch({},{},{});
};
ok $@, 'three arguments not allowed';
ok $@ =~ /two HASH references required/, 'three arguments throw the correct exception';

eval {
    mmatch({},'a');
};
ok $@, 'scalar argument not allowed';
ok $@ =~ /two HASH references required/, 'one scalar agument throws the correct exception';

eval {
    mmatch('a',{});
};
ok $@, 'scalar argument not allowed: part two';
ok $@ =~ /two HASH references required/, 'one scalar agument throws the correct exception: part two';

eval {
    mmatch({},[]);
};
ok $@, 'non HASH-ref argument not allowed';
ok $@ =~ /two HASH references required/, 'non HASH-ref argument throws the correct exception';


#covered tuples:
#scalar,scalar
#HASH,HASH
#ARRAY,scalar
#ARRAY,ARRAY

#other tuples
#HASH,scalar
#scalar,HASH
#scalar,ARRAY
#ARRAY,HASH
#HASH,ARRAY

#how to do 'meta' types, such as regex
done_testing();
