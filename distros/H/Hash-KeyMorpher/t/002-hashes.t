#!/usr/bin/perl -w

use Hash::KeyMorpher;
use Test::More tests => 7;

# key_morph hashes
my $h1 = { 'level_one' => { 'LevelTwo' => { 'levelThree' => { 'LEVELFOUR' => 'hello'}, 'the_array' => ['abc',1,2] } } };
my $camel = { 'LevelOne' => { 'LevelTwo' => { 'LevelThree' => { 'Levelfour' => 'hello'}, 'TheArray' => ['abc',1,2] } } };
my $mixed = { 'levelOne' => { 'levelTwo' => { 'levelThree' => { 'levelfour' => 'hello'}, 'theArray' => ['abc',1,2] } } };
my $under = { 'level_one' => { 'level_two' => { 'level_three' => { 'levelfour' => 'hello'}, 'the_array' => ['abc',1,2] } } };
my $delim = { 'level-one' => { 'level-two' => { 'level-three' => { 'levelfour' => 'hello'}, 'the-array' => ['abc',1,2] } } };
my $upper = { 'LEVELONE' => { 'LEVELTWO' => { 'LEVELTHREE' => { 'LEVELFOUR' => 'hello'}, 'THEARRAY' => ['abc',1,2] } } };
my $lower = { 'levelone' => { 'leveltwo' => { 'levelthree' => { 'levelfour' => 'hello'}, 'thearray' => ['abc',1,2] } } };

is_deeply(key_morph($h1,'camel'),$camel,'key_morph camel');
is_deeply(key_morph($h1,'mixed'),$mixed,'key_morph camel');
is_deeply(key_morph($h1,'mixed'),$mixed,'key_morph mixed');
is_deeply(key_morph($h1,'under'),$under,'key_morph under');
is_deeply(key_morph($h1,'delim','-'),$delim,'key_morph delim');
is_deeply(key_morph($h1,'upper'),$upper,'key_morph upper');
is_deeply(key_morph($h1,'lower'),$lower,'key_morph lower');

exit 0;