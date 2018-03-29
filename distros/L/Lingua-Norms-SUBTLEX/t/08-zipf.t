use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 5;
use FindBin qw/$Bin/;
use File::Spec;
use Lingua::Norms::SUBTLEX;
require File::Spec->catfile($Bin, '_common.pl');

my $subtlex;

eval {
    $subtlex = Lingua::Norms::SUBTLEX->new(
        path      => File::Spec->catfile( $Bin, qw'samples SUBTLEX-PT_Soares_et_al._QJEP.csv' ),
        fieldpath => File::Spec->catfile(
            $Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'
        ),
        lang => 'PT',
        match_level => 0,
    );
};
ok( !$@, $@ );

my $val;

$val = $subtlex->n_lines();
ok($val == 29, "returned wrong number of lines in FR sample: $val");

my $canned_data = get_canned_data();

my $ret;
for my $str( sort {$a cmp $b} keys %{$canned_data->{'PT'}}) {
    my $val = $canned_data->{'PT'}->{$str};
    #my $count = $subtlex->frq_opm2count(string => $key);
    #ok($count == $val->{'frq_count'}, 'Returned wrong conversion frq_opm2count');
    #$ret = $subtlex->frq_zipf_calc(string => $str); #, n_wordtypes => 157920, corpus_size => 50, 125653
    $ret = $subtlex->frq_zipf(string => $str); #, n_wordtypes => 157920, corpus_size => 50, 125653
    ok( about_equal($ret, $val->{'frq_zipf'}), "'$str' returned wrong frq_zipf: $ret" );    
    #diag( sprintf("%s\t%f\t%f", $str, $val->{'frq_zipf'}, $ret) );
     # Zipf_calc: From Van Heuven: "The Zipf value of a word type observed once in the complete corpus will be 0.997; that of a word observed 10 times will be 1.737, and so on."
    #my $zipf_1 = 0.997;
    #my $zipf_10 = 1.737;    
}

1;
