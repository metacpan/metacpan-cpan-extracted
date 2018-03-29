use 5.12.0;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 39;
use FindBin qw/$Bin/;
use File::Spec;
use Lingua::Norms::SUBTLEX;
require File::Spec->catfile($Bin, '_common.pl');

my $subtlex;

eval {
    $subtlex = Lingua::Norms::SUBTLEX->new(
        path      => File::Spec->catfile( $Bin, qw'samples SUBTLEX-PT_Soares_et_al._QJEP.csv' ),
        fieldpath => File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'),
        lang => 'PT',
        match_level => 0,
    );
};
ok( !$@, $@ );

my $val;

$val = $subtlex->n_lines();
ok($val == 29, "returned wrong number of lines in FR sample: $val");

# Check delimiter: s/be tab not comma:
#---------------

ok ($subtlex->{'_DELIM'} eq q{,}, "Returned wrong delimiter for lang FR");


# Recorded measures:
#---------------

my $canned_data = get_canned_data('PT');

my $ret;
for my $str( sort {$a cmp $b} keys %{$canned_data}) {
    my $val = $canned_data->{$str};
    ok( $subtlex->frq_count( string => $str ) == $val->{'frq_count'}, "<$str> returned wrong frq_count" );
    $ret = $subtlex->frq_opm( string => $str );
    ok( about_equal($ret, $val->{'frq_opm'}), "<$str> returned wrong opm frequency: $ret" );
    ok( $subtlex->frq_log( string => $str ) == $val->{'frq_log'}, "<$str> returned wrong frq_log" );
    ok( $subtlex->cd_count( string => $str ) == $val->{'cd_count'}, "<$str> returned wrong cd_count" );
    ok( $subtlex->cd_pct( string => $str ) == $val->{'cd_pct'}, "<$str> returned wrong cd_pct" );
    ok( $subtlex->cd_log( string => $str ) == $val->{'cd_log'}, "<$str> returned wrong cd_log" );
    
    $ret = $subtlex->pos_dom( string => $str );
    ok( $ret eq $val->{'pos_dom'}, "<$str> returned wrong pos_dom: $ret" );
    
    $ret = $subtlex->pos_all( string => $str );
    ok(ref $ret, 'Not a reference returned from pos_all');
    
    for my $expected_pos_i(0 .. ((scalar @{$val->{'pos_all'}}) - 1 )) {
        my $expected = $val->{'pos_all'}->[$expected_pos_i];
        my $observed = $ret->[$expected_pos_i];
        ok( $observed eq $expected, "<$str> returned wrong pos_all:\n\tobserved\t$observed\n\texpected\t$expected" );
    }
    
    my $count = $subtlex->frq_opm2count(string => $str);
    ok($count == $val->{'frq_count'}, 'Returned wrong conversion frq_opm2count');
}


# stats
#---------------
my $mean =
  $subtlex->frq_mean( strings => [qw/polímeros jubilarás/], scale => 'opm' );
  my $mean_exp = (0.6793 + 0.0128)/2;
ok( about_equal( $mean, $mean_exp ),
    "returned wrong mean frequency for PT: $mean" );


# select_strings
#---------------

# target = 'bantustão'
my $list = $subtlex->select_strings(cv_pattern => 'CVCCVCCVV');
ok(ref $list, "Did not get ref back from select_strings()");
ok($list->[0] eq 'bantustão', "Selected wrong string: expected 'bantustão', got $list->[0]");

# target = 'topológico'
$list = $subtlex->select_strings(cv_pattern => 'CVCVCVCVCV');
ok( (ref $list and defined $list->[0]), "Did not get ref back from select_strings()");
ok($list->[0] eq 'topológico', "Selected wrong string: expected 'topológico', got $list->[0]");

1;
