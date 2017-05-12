use strict;
use warnings;
use Test::More;
use Hash::Weighted::Categorize;

# build the various coderefs
my %categorize = map split( /:/, $_, 2 ), split /^---.*?^/ms, << 'CODE';
percent90:
%CRIT + %WARN > 50%       : CRIT;
%OK  >= 90%, %CRIT <= 10% : OK;
UNKN;
---
absolute5:
%CRIT + %WARN >50%     : CRIT;
OK  >= 5, %CRIT <= 10% : OK;
UNKN;
---
color:
# grey
%red   >= 11/36, %green >= 11/36, %blue >= 11/36: grey;
# secondary
blue  > red,   green > red,   green / blue  > 33/36, green / blue  < 36/33: cyan;
red   > green, blue  > green, blue  / red   > 33/36, blue  / red   < 36/33: magenta;
green > blue,  red   > blue,  red   / green > 33/36, red   / green < 36/33: yellow;
# primary
%red   >= 50%: red;
%green >= 50%: green;
%blue  >= 0.5: blue;
# whatever
unknown;
---
nested:
%OK == 1: OK;
%CRIT >= 10% : {
    CRIT >= 20: CRIT;
    %OK  > 85%: OK;
    WARN;
};
WARN != 0: WARN;
UNKN;
CODE

# test data
my %test = (
    percent90 => [
        [ { OK => 1, CRIT => 1 } => 'UNKN' ],
        [ { OK => 9, CRIT => 1 } => 'OK' ],
        [ { OK => 1, CRIT => 5 } => 'CRIT' ],
        [ { OK => 2, CRIT => 2, WARN => 3 } => 'CRIT' ],
        [ { OK => 10 } => 'OK' ],
    ],
    absolute5 => [
        [ { OK => 1,  CRIT => 1 } => 'UNKN' ],
        [ { OK => 5,  CRIT => 1 } => 'UNKN' ],
        [ { OK => 10, CRIT => 1 } => 'OK' ],
        [ { OK => 10, CRIT => 1, WARN => 4 } => 'OK' ],
        [ { OK => 5,  CRIT => 1, WARN => 5 } => 'CRIT' ],
    ],
    color => [
        [ '2A73FA' => 'blue' ],
        [ '2BD6CE' => 'cyan' ],
        [ '33050F' => 'red' ],
        [ '6FC8F5' => 'unknown' ],
        [ '79E849' => 'green' ],
        [ '79E849' => 'green' ],
        [ 'CCC0CA' => 'grey' ],
        [ 'D6D62B' => 'yellow' ],
        [ 'D8F99E' => 'unknown' ],
        [ 'DB4263' => 'red' ],
        [ 'FC68F2' => 'magenta' ],
        [ '9DCEA1' => 'unknown' ],
    ],
    nested => [
        [ { OK => 1, CRIT => 1 } => 'WARN' ],
        [ { OK => 9, CRIT => 1 } => 'OK' ],
        [ { OK => 8, CRIT => 1, WARN => 1 } => 'WARN' ],
        [ { OK => 1, CRIT => 5 } => 'WARN' ],
        [ { OK => 2, CRIT => 2, WARN => 3 } => 'WARN' ],
        [ { OK => 10 } => 'OK' ],
        [ { OK => 10, CRIT => 20 } => 'CRIT' ],
    ],
);

# fixup color input
$_->[0] = {
    red   => hex( substr $_->[0], 0, 2 ),
    green => hex( substr $_->[0], 2, 2 ),
    blue  => hex( substr $_->[0], 4, 2 )
    }
    for @{ $test{color} };

# generate coderefs
my $fleur = Hash::Weighted::Categorize->new();
$_ = $fleur->parse($_) for values %categorize;

# run the tests
for my $test ( sort keys %test ) {
    my $code = $categorize{$test};
    for my $t ( @{ $test{$test} } ) {
        my ( $hash, $expected ) = @$t;
        is( $code->($hash), $expected, "$test: $expected" );
    }
}

done_testing();
