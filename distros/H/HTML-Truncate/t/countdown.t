#!perl
use strict;

use Test::More tests => 27;

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use HTML::Truncate;

print $HTML::Truncate::VERSION, $/;

my $ht = HTML::Truncate->new();
$ht->ellipsis('...');

my $html = '<p><i>We</i> have to test <b>something</b>.</p>';

my $test = [
    1 => '<p><i>W...</i></p>',
    2 => '<p><i>We...</i></p>',
    3 => '<p><i>We</i>...</p>',
    4 => '<p><i>We</i> h...</p>',
    5 => '<p><i>We</i> ha...</p>',
    6 => '<p><i>We</i> hav...</p>',
    7 => '<p><i>We</i> have...</p>',
    8 => '<p><i>We</i> have...</p>',
    9 => '<p><i>We</i> have t...</p>',
    10 => '<p><i>We</i> have to...</p>',
    11 => '<p><i>We</i> have to...</p>',
    12 => '<p><i>We</i> have to t...</p>',
    13 => '<p><i>We</i> have to te...</p>',
    14 => '<p><i>We</i> have to tes...</p>',
    15 => '<p><i>We</i> have to test...</p>',
    16 => '<p><i>We</i> have to test...</p>',
    17 => '<p><i>We</i> have to test <b>s...</b></p>',
    18 => '<p><i>We</i> have to test <b>so...</b></p>',
    19 => '<p><i>We</i> have to test <b>som...</b></p>',
    20 => '<p><i>We</i> have to test <b>some...</b></p>',
    21 => '<p><i>We</i> have to test <b>somet...</b></p>',
    22 => '<p><i>We</i> have to test <b>someth...</b></p>',
    23 => '<p><i>We</i> have to test <b>somethi...</b></p>',
    24 => '<p><i>We</i> have to test <b>somethin...</b></p>',
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

