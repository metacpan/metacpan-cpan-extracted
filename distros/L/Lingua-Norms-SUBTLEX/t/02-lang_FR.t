use 5.12.0;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 32;
use FindBin qw/$Bin/;
use File::Spec;
use Lingua::Norms::SUBTLEX;
require File::Spec->catfile($Bin, '_common.pl');

my $subtlex;

eval {
    $subtlex = Lingua::Norms::SUBTLEX->new(
        path      => File::Spec->catfile( $Bin, qw'samples FR.txt' ),
        fieldpath => File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'),
        lang => 'FR',
        match_level => 0,
    );
};
ok( !$@, $@ );

my $val;

$val = $subtlex->n_lines();
ok($val == 33, "returned wrong number of lines in FR sample: $val");

# ensure got tab not comma as delimiter:
ok ($subtlex->{'_DELIM'} eq "\t", "Returned wrong delimiter for lang FR");

my $canned_data = get_canned_data('FR');

my $ret;

for my $str( sort {$a cmp $b} keys %{$canned_data}) {
    my $val = $canned_data->{$str};
    $ret = $subtlex->frq_opm( string => $str );
    ok( about_equal($ret, $val->{'frq_opm'}),
        "<$str> returned wrong opm frequency: $ret" );
    #ok( $subtlex->frq_log( string => $key ) == $val->{'frq_log'}, "'$str' returned wrong log frequency" );
}

# and stats?
my $mean =
  $subtlex->frq_mean( strings => [qw/jouissive divorceras/], scale => 'opm' );
ok( about_equal( $mean, 0.015 ),
    "returned wrong mean frequency for FR: $mean" );

# equality
$subtlex->set_eq(match_level => 0); # case- and mark-sensitive
$ret = $subtlex->is_normed(string => 'emotive'); # should not be found
ok($ret == 0, "Error: found unmarked 'emotive' with match_level => 0");
$ret = $subtlex->is_normed(string => 'émotive'); # should be found
ok($ret == 1, "Error: found unmarked 'émotive' with match_level => 0");

$subtlex->set_eq(match_level => 1); # both case- and mark-insensitive
$ret = $subtlex->is_normed(string => 'emotive'); # should be found
ok($ret == 1, "Error: did not find unmarked 'emotive' with match_level => 1");
$ret = $subtlex->is_normed(string => 'Emotive'); # should be found
ok($ret == 1, "Error: did not find unmarked 'Emotive' with match_level => 1");

$subtlex->set_eq(match_level => 2); # both case- and mark-insensitive
$ret = $subtlex->is_normed(string => 'emotive'); # should not be found
ok($ret == 0, "Error: found unmarked 'emotive' with match_level => 1");
$ret = $subtlex->is_normed(string => 'Émotive'); # should be found
ok($ret == 1, "Error: did not find unmarked 'Émotive' with match_level => 1");

$subtlex->set_eq(match_level => 3); # case- and mark-sensitive - same as 0
$ret = $subtlex->is_normed(string => 'emotive'); # should not be found
ok($ret == 0, "Error: found unmarked 'emotive' with match_level => 0");
$ret = $subtlex->is_normed(string => 'émotive'); # should be found
ok($ret == 1, "Error: found unmarked 'émotive' with match_level => 0");

# target: 'action'
my $list = $subtlex->select_strings(cv_pattern => 'VCCVVC');
ok(ref $list, "Did not get ref back from select_strings()");
ok($list->[0] eq 'action', "Selected wrong string: expected 'action', got $list->[0]");

# target: 'embâcle'
$list = $subtlex->select_strings(cv_pattern => 'VCCVCCV');
ok( (ref $list and defined $list->[0]), "Did not get ref back from select_strings()");
ok($list->[0] eq 'embâcle', "Selected wrong string: expected 'embâcle', got $list->[0]");

1;
