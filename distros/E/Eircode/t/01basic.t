#!/usr/bin/perl

use strict;
use warnings;
use Test::Simple tests => 25;
use Eircode qw< check_eircode >;

my @t = (
    [[ 'A65 B2CD' ], 1, 'Simple pass'],
    [[ ''], 0, 'Blank string'],
    [["a65 b2cd"], 1, 'Defaults to case insensitive'], 
    [["a65b2cd", {lax => 1}], 1, 'Lax does not care about spaces'],
    [["a65b2cd"], 0, 'Default does care about spaces'],
    [["a65     b2cd"], 1, 'Default does care about spaces, but not how many'],
    [["a65b2cd", {strict =>1}], 0, 'Stricy does care about spaces'],
    [["a65b2cd", {strict => 0}], 0, 'Strict off (default) cares about spaces'],
    [["a65 b2cd", {strict => 1}], 0, 'Strict cares about case'],
    [["A65 B2CD", {strict => 1}], 1, 'Strict can pass'],
    [["O65 B2CD"], 0, 'O in the routing code fails'],
    [["A6O B2CD"], 0, 'O in the any part of the routing code fails'],
    [["A65 O2CD"], 0, 'O in the uid fails'],
    [["A65 B2CD1"], 0, 'Extra character fails'],
    [["065 B2CD"], 0, 'Zero in the alpha part of routing key fails'],
    [["B00 B2CD"], 1, 'Zero in the numeric part Ok'],
    [["D6W B2CD"], 1, 'Known exceptional routing key pass'],
    [["D22 YD82"], 1, 'D22 YD82'],
    [["F93 T3P6"], 1, 'F93 T3P6'],
    [["f93t3p6", {space_optional =>1}], 1, 'space_optional + lower case no spaces'],
    [["F93T3P6", {space_optional =>1}], 1, 'space_optional + lower case no spaces'],
    [["f93 t3p6", {space_optional =>1}], 1, 'space_optional + lower case correct space'],
    [["f93  t3p6", {space_optional =>1}], 1, 'space_optional + lower case too much space'],
    [["f93t 3p6", {space_optional =>1}], 0, 'space_optional + lower case wrong space'],
    [["f93 t3 p6", {space_optional =>1}], 0, 'space_optional + lower case extra space'],
);

for( @t ){
    my( $arga, $expect_pass, $tn, $opt ) = @{$_};
    my @a = @{$arga};
    my $ok = eval{check_eircode(@a)};
    my $e = $@;
    if( $e ){
        if( ! $opt && $opt->{expect_exception}){
            die $e;
        }
        else{
            ok(1, "got an exception as expected");
            next;
        }
    }

    if( $expect_pass ){
        ok( $ok, $tn);
    }
    else{
        ok(!$ok, $tn);
    }
}

