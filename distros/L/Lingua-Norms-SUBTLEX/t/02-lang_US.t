use 5.12.0;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 32;
use FindBin qw/$Bin/;
use File::Spec;
use Lingua::Norms::SUBTLEX;

require File::Spec->catfile($Bin, '_common.pl');

my $subtlex = Lingua::Norms::SUBTLEX->new(
    path      => File::Spec->catfile( $Bin, qw'samples US.csv' ),
    fieldpath => File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'),
    lang => 'US'
);

my $canned_data = get_canned_data('US');
my ( $val, $ret ) = ();

while ( my ( $str, $val ) = each %{$canned_data} ) {
    $ret = $subtlex->frq_count( string => $str );
    ok( about_equal($ret, $val->{'frq_count'}),
        "'$str' returned wrong frq_count: '$ret'" );
    
    $ret = $subtlex->frq_opm( string => $str );
    ok( $ret =~ m/^[0-9\.]+$/,
        "'$str' returned non-numeric frq_opm: '$ret'" );
    ok( about_equal($ret, $val->{'frq_opm'}),
        "'$str' returned wrong frq_opm: '$ret'" );
    
    $ret = $subtlex->frq_log( string => $str );
    ok( about_equal($ret, $val->{'frq_log'}),
        "'$str' returned wrong frq_log: $ret" );
    
    $ret = $subtlex->frq_zipf( string => $str );
    ok( $ret =~ m/^[0-9\.]+$/,
        "'$str' returned non-numeric frq_zipf: '$ret'" );
    ok( about_equal($ret, $val->{'frq_zipf'}), "'$str' returned wrong frq_zipf: $ret" );
    
    $ret = $subtlex->cd_count( string => $str );
    ok( about_equal($ret, $val->{'cd_count'}),
        "'$str' returned wrong cd_count: '$ret'" );
    
    $ret = $subtlex->cd_pct( string => $str );
    ok( about_equal($ret, $val->{'cd_pct'}),
        "'$str' returned wrong cd_pct: $ret" );
    
    $ret = $subtlex->cd_log( string => $str );
    ok( about_equal($ret, $val->{'cd_log'}),
        "'$str' returned wrong cd_log: $ret" );
    
    $ret = $subtlex->frq_opm2count(string => $str);
    ok( about_equal($ret, $val->{'frq_count'}),
        "'$str' returned wrong frq_count by opm2count: '$ret'" );
        
    $ret = $subtlex->pos_dom( string => $str );
    ok( $ret eq $val->{'pos_dom'}, "<$str> returned wrong pos_dom: $ret" );
    
    $ret = $subtlex->pos_all( string => $str );
    ok(ref $ret, 'Not a reference returned from pos_all');
    for my $expected_pos_i(0 .. ((scalar @{$val->{'pos_all'}}) - 1 )) {
        my $expected = $val->{'pos_all'}->[$expected_pos_i];
        my $observed = $ret->[$expected_pos_i];
        ok( $observed eq $expected, "<$str> returned wrong pos_all:\n\tobserved\t$observed\n\texpected\t$expected" );
    }
}

# check empty-string is returned if string not found:
ok( $subtlex->frq_opm( string => 'x9_9x' ) == 0,
    "non-item frq_opm is not zero" );

1;
