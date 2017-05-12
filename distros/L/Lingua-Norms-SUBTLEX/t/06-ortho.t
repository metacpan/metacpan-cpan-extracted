use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 9;
use Lingua::Norms::SUBTLEX;
use Array::Compare;
use Statistics::Lite qw(mean);
use File::Spec;
use FindBin;
use constant EPS     => 1e-3;
my $cmp_aref = Array::Compare->new;

my $subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($FindBin::Bin, 'US_sample.csv'), fieldpath =>  File::Spec->catfile($FindBin::Bin, '..', 'lib', 'Lingua', 'Norms', 'SUBTLEX', 'fields.csv'));

# TEST on_count():    
# (i) scalar context:
my $val = $subtlex->on_count( string => 'the' );
ok( $val == 11,
    '\'the\' on_count not accurate for sample file'
);

# (ii) array context: - returns properly when called in array context?
my ($val2, $aref) = $subtlex->on_count( string => 'the' );
ok( $val2 == 11,
    '\'the\' on_count not accurate for sample file'
);
ok( $val2 == 11,
    '\'the\' on_count not accurate for sample file'
);
my @the_orthons = (qw/che she tae tee tha tho thy tie toe tue tye/);
ok( $cmp_aref->simple_compare( $aref,  \@the_orthons),
    "aref from on_count in array context error:\nexpected: " .
        join(q{ }, @the_orthons)
        .
        "\ngot: " .
        join( q{ }, @$aref )
  );
    
# TEST on_freq_max(): scalar context:
my $max = 3732.88;
$val = $subtlex->on_freq_max( string => 'the' );
ok(
    about_equal($val, $max),
    '\'the\' on_freq_max not accurate for sample file' . "\n\texpected = $max\n\tobserved = $val" 
);

my $mean;

$mean = 348.500909090909;
$val = $subtlex->on_freq_mean( string => 'the' );
ok(
    about_equal($val, $mean),
    '\'the\' on_freq_mean not accurate for sample file' . "\n\texpected = $mean\n\tobserved = $val" 
);

# ensure undef otherwise:
#ok(
#   ! defined $subtlex->on_freq_mean( string => 'aal' ),
#    '\'aal\' on_freq_mean not undefined for sample file'
#);


$val = $subtlex->on_zipf_mean(string => 'the');
$mean = 3.68804403027;
ok(
    about_equal($val, $mean),
    '\'the\' on_zipf_mean not accurate for sample file' . "\n\texpected = $mean\n\tobserved = $val"
);


# ensure undef otherwise:
#ok(
#   ! defined $subtlex->on_zipf_mean( string => 'aaal' ),
#    '\'aal\' on_zipf_mean not undefined for sample file'
#);

# test calculation of mean Levenshtein distance with default limit of 20 smallest values, using example data in Yarkoni et al:
$subtlex =
  Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($FindBin::Bin, 'data_samp2.csv'), fieldpath =>  File::Spec->catfile($FindBin::Bin, '..', 'lib', 'Lingua', 'Norms', 'SUBTLEX', 'fields.csv'));
$val = $subtlex->on_ldist(string => 'condition');
ok(
    about_equal($val, 2.4),
    'Levenshtein Distance calculation failed' . "\n\texpected = 2.4\n\tobserved = $val"
);

$val = $subtlex->on_ldist(string => 'PISTACHIO');
ok(
    about_equal($val, 4.3),
    'Levenshtein Distance calculation failed' . "\n\texpected = 4.3\n\tobserved = $val"
);

sub about_equal {
    return 0 if !defined $_[0] || !defined $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
1;
