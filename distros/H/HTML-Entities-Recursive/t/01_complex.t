use strict;
use warnings;
use utf8;
use Test::More;
use Data::Dumper;

use HTML::Entities;
use HTML::Entities::Recursive;
 
my $recursive = HTML::Entities::Recursive->new;

# encode tests
my $orig_str = q{<&>"'};
my $orig = {
    arrayref  => [
        { key => $orig_str },
        { key => $orig_str },
        { key => $orig_str },
    ],
    hashref => {
        hashref => {
            hashref => {
                arrayref => [
                    $orig_str,
                    $orig_str,
                    $orig_str,
                ],
            },
            key => $orig_str,
        },
        key => $orig_str,
    },
    scalarref => \$orig_str,
};

# Tests for encode( $structure )
my $t1     = $recursive->encode($orig);
my $t1_str = HTML::Entities::encode_entities($orig_str);

ok($t1->{arrayref}[1]{key}
    eq $t1_str, 'encode {arrayref}[1]{key}');

ok($t1->{hashref}{key}
    eq $t1_str, 'encode {hashref}{key}');

ok($t1->{hashref}{hashref}{key}
    eq $t1_str, 'encode {hashref}{hashref}{key}');

ok($t1->{hashref}{hashref}{hashref}{arrayref}[2]
    eq $t1_str, 'encode {hashref}{hashref}{hashref}{arrayref}[2]');

ok(${$t1->{scalarref}}
    eq $t1_str, 'encode {scalarref}');


# Tests for encode( $structure, $unsafe_chars )
my $t2     = $recursive->encode($orig, q{<&>"'});
my $t2_str = HTML::Entities::encode_entities($orig_str, q{<&>"'});

ok($t2->{arrayref}[1]{key}
    eq $t2_str, 'encode_with_opt {arrayref}[1]{key}');

ok($t2->{hashref}{key}
    eq $t2_str, 'encode_with_opt {hashref}{key}');

ok($t2->{hashref}{hashref}{key}
    eq $t2_str, 'encode_with_opt {hashref}{hashref}{key}');

ok($t2->{hashref}{hashref}{hashref}{arrayref}[2]
    eq $t2_str, 'encode_with_opt {hashref}{hashref}{hashref}{arrayref}[2]');

ok(${$t2->{scalarref}}
    eq $t2_str, 'encode_with_opt {scalarref}');


# Tests for encode_numeric( $structure )
my $t3     = $recursive->encode_numeric($orig);
my $t3_str = HTML::Entities::encode_entities_numeric($orig_str);

ok($t3->{arrayref}[1]{key}
    eq $t3_str, 'encode_numeric {arrayref}[1]{key}');

ok($t3->{hashref}{key}
    eq $t3_str, 'encode_numeric {hashref}{key}');

ok($t3->{hashref}{hashref}{key}
    eq $t3_str, 'encode_numeric {hashref}{hashref}{key}');

ok($t3->{hashref}{hashref}{hashref}{arrayref}[2]
    eq $t3_str, 'encode_numeric {hashref}{hashref}{hashref}{arrayref}[2]');

ok(${$t3->{scalarref}}
    eq $t3_str, 'encode_numeric {scalarref}');


# Tests for encode_numeric( $structure, $unsafe_chars )
my $t4     = $recursive->encode_numeric($orig, q{<&>"'});
my $t4_str = HTML::Entities::encode_entities_numeric($orig_str, q{<&>"'});

ok($t4->{arrayref}[1]{key}
    eq $t4_str, 'encode_numeric_with_opt {arrayref}[1]{key}');

ok($t4->{hashref}{key}
    eq $t4_str, 'encode_numeric_with_opt {hashref}{key}');

ok($t4->{hashref}{hashref}{key}
    eq $t4_str, 'encode_numeric_with_opt {hashref}{hashref}{key}');

ok($t4->{hashref}{hashref}{hashref}{arrayref}[2]
    eq $t4_str, 'encode_numeric_with_pot {hashref}{hashref}{hashref}{arrayref}[2]');

ok(${$t4->{scalarref}}
    eq $t4_str, 'encode_numeric_with_opt {scalarref}');


# decode tests
my $orig_str2 = HTML::Entities::encode_entities(q{<&>"'});
my $orig2 = {
    arrayref  => [
        { key => $orig_str2 },
        { key => $orig_str2 },
        { key => $orig_str2 },
    ],
    hashref => {
        hashref => {
            hashref => {
                arrayref => [
                    $orig_str2,
                    $orig_str2,
                    $orig_str2,
                ],
            },
            key => $orig_str2,
        },
        key => $orig_str2,
    },
    scalarref => \$orig_str2,
};

# Tests for decode( $structure )
my $t5     = $recursive->decode($orig2);
my $t5_str = HTML::Entities::decode_entities($orig_str2);

ok($t5->{arrayref}[1]{key}
    eq $t5_str, 'decode {arrayref}[1]{key}');

ok($t5->{hashref}{key}
    eq $t5_str, 'decode {hashref}{key}');

ok($t5->{hashref}{hashref}{key}
    eq $t5_str, 'decode {hashref}{hashref}{key}');

ok($t5->{hashref}{hashref}{hashref}{arrayref}[2]
    eq $t5_str, 'decode {hashref}{hashref}{hashref}{arrayref}[2]');

ok(${$t5->{scalarref}}
    eq $t5_str, 'decode {scalarref}');

done_testing;

