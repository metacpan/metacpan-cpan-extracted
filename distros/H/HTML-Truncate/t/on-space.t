#!perl
use strict;

use Test::More tests => 28;

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use HTML::Truncate;

print $HTML::Truncate::VERSION, $/;

my $ht = HTML::Truncate->new();
$ht->ellipsis('...');
ok( $ht->on_space(1),
    "Setting on_space(1)" );

my $html = '<p><i>We</i> have to test <b>something</b>.</p>';

my $test = [
    1 => '<p><i>...</i></p>',
    2 => '<p><i>We...</i></p>',
    3 => '<p><i>We</i>...</p>',
    4 => '<p><i>We</i>...</p>',
    5 => '<p><i>We</i>...</p>',
    6 => '<p><i>We</i>...</p>',
    7 => '<p><i>We</i> have...</p>',
    8 => '<p><i>We</i> have...</p>',
    9 => '<p><i>We</i> have...</p>',
    10 => '<p><i>We</i> have to...</p>',
    11 => '<p><i>We</i> have to...</p>',
    12 => '<p><i>We</i> have to...</p>',
    13 => '<p><i>We</i> have to...</p>',
    14 => '<p><i>We</i> have to...</p>',
    15 => '<p><i>We</i> have to test...</p>',
    16 => '<p><i>We</i> have to test...</p>',
    17 => '<p><i>We</i> have to test <b>...</b></p>',
    18 => '<p><i>We</i> have to test <b>...</b></p>',
    19 => '<p><i>We</i> have to test <b>...</b></p>',
    20 => '<p><i>We</i> have to test <b>...</b></p>',
    21 => '<p><i>We</i> have to test <b>...</b></p>',
    22 => '<p><i>We</i> have to test <b>...</b></p>',
    23 => '<p><i>We</i> have to test <b>...</b></p>',
    24 => '<p><i>We</i> have to test <b>...</b></p>',
    25 => '<p><i>We</i> have to test <b>something...</b></p>',
    26 => '<p><i>We</i> have to test <b>something</b>...</p>',
    27 => '<p><i>We</i> have to test <b>something</b>.</p>',
];


while ( my( $key, $val ) = splice @{$test}, 0, 2 ){
    $ht->chars( $key );
    my $result;
    is( $result = $ht->truncate( $html ), $val,
        $result );
#    diag( $key . ' ' . $ht->truncate( $html ) ) if $ENV{TEST_VERBOSE};
}

