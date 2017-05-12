# ref_data.t version 0.01
# A script to run tests on the Lingua::Norms::Orthon module.
# Checks correct returns of known values data
use strict;
use warnings;

use Test::More tests => 10;
use constant EPS => 1e-9;

BEGIN { use_ok('Lingua::Orthon') };

my $orthon = Lingua::Orthon->new();

my %val_ref = (
    test1 => 5, # from Yarkoni et al.
    test2 => 2, # from Yarkoni et al.
    test3 => 4, # from Yarkoni et al.
    test4 => 3, # from perlmonks on Hamming.
);

my ($val, @words) = ();

# Test Levenshtein output:
@words = (qw/CHANCE STRAND/);
$val = $orthon->ldist(@words);
ok( is_equal($val, $val_ref{'test1'}), "LOD expected $val_ref{'test1'} observed $val" );

@words = (qw/smile similes/);
$val = $orthon->ldist(@words);
ok( is_equal($val, $val_ref{'test2'}), "LOD expected $val_ref{'test2'} observed $val" );

@words = (qw/pistachio hibachi/);
$val = $orthon->ldist(@words);
ok( is_equal($val, $val_ref{'test3'}), "LOD expected $val_ref{'test3'} observed $val" );

# Test Hamming output:
@words = ('GGAAG', 'GAAGA'); 
$val = $orthon->hdist(@words); 
ok( is_equal($val, $val_ref{'test4'}), "HAM expected $val_ref{'test4'} observed $val" );

@words = ('milk', 'silk');
$val = $orthon->index_identical(@words);
ok( is_equal($val, 3), "index identical expected = 3, observed = $val" );

@words = ('milk', 'mill');
$val = $orthon->index_identical(@words);
ok( is_equal($val, 3), "index identical expected = 3, observed = $val" );

@words = ('milk', 'molk');
$val = $orthon->index_identical(@words);
ok( is_equal($val, 3), "index identical expected = 3, observed = $val" );

@words = ('milkier', 'malty');
$val = $orthon->index_identical(@words);
ok( is_equal($val, 2), "index identical expected = 2, observed = $val" );

@words = (qw/CHANCE STRAND/);
$val = $orthon->len_maxseq(@words);
ok( is_equal($val, 2), "index identical expected = 2, observed = $val" );

sub is_equal {
    return 1 if $_[0] == $_[1];
    return 0;
}

sub char_equal {
    return 1 if $_[0] eq $_[1];
    return 0;
}

sub about_equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
