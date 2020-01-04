#!/usr/bin/env perl

# MLPerl, K Nearest Neighbors 2D, Demo Driver
# Load training points, find K nearest neighbors to classify test points

# [[[ HEADER ]]]
use RPerl;
use strict;
use warnings;
our $VERSION = 0.006_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls) # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]

# from sklearn.neighbors import KNeighborsClassifier  # PYTHON
use MLPerl::Classifier::KNeighbors;

use MLPerl::PythonShims qw(concatenate for_range);
use Data::Dumper;
use Time::HiRes qw(time);

# [[[ CONSTANTS ]]]
my integer $timing_repetitions = 500;

# [[[ OPERATIONS ]]]

# create $train_data_A & $train_data_B data sets;
# copy & paste from Python example for now
my number_arrayref_arrayref $train_data_A = 
    [
#        [ 1,    1  ],
#        [ 6,   -1  ],
#        [-9,   -9  ],

        # PYTHON
        [  2.1283978    ,    6.99781055 ]   ,
        [  0.08238248   ,    5.82400283 ]   ,
        [ -0.82601643   ,    2.71628165 ]   ,
        [  1.37591514   ,    3.65961071 ]   ,
        [  0.8478706    ,    2.98211783 ]   ,
        [ -0.56940469   ,    1.67503135 ]   ,
        [  0.23359639   ,    2.63039698 ]   ,
        [ -1.67666183   ,   -2.68056896 ]   ,
        [  0.38044469   ,    0.10537537 ]   ,
        [ -0.83511902   ,   -2.53894397 ]   ,
        [  0.18993115   ,   -3.37995129 ]   ,
        [  1.06244261   ,   -0.17562345 ]   ,
        [ -0.32022184   ,    1.833004   ]   ,
        [  0.32321392   ,   -0.85304287 ]   ,
        [ -0.20494313   ,    4.34603267 ]   ,
        [  0.16255978   ,    0.87320676 ]   ,
        [  0.09642087   ,   -1.37772042 ]   ,
        [  0.58084648   ,   -5.96674703 ]   ,
        [  0.20887862   ,    10.3951847 ]   ,
        [  2.02425663   ,   -1.64348471 ]   ,
        [ -0.54229195   ,    1.01074369 ]   ,
        [  0.36948569   ,   -1.47472803 ]   ,
        [  1.13707908   ,   -1.03273182 ]   ,
        [ -1.25268671   ,   -5.47504984 ]   ,
        [  0.85122081   ,   -0.06016381 ]   ,
        [ -0.13065605   ,   -1.36226708 ]   ,
        [ -1.71895239   ,   -3.07170047 ]   ,
        [ -0.63678034   ,   -2.23522581 ]   ,
        [  0.69419178   ,    0.38899363 ]   ,
        [  0.38246087   ,    3.33923112 ]   ,
        [ -0.29303277   ,    1.00472943 ]   ,
        [ -0.51302493   ,    2.70101956 ]   ,
        [  0.17664238   ,   -2.75928453 ]   ,
        [ -0.48924721   ,   -1.76872125 ]   ,
        [ -0.79406169   ,   -1.77747045 ]   ,
        [ -0.62381556   ,    2.64807846 ]   ,
        [ -0.90733361   ,   -1.68796351 ]   ,
        [ -0.15474802   ,    4.36177172 ]   ,
        [  0.52476942   ,   -1.56692514 ]   ,
        [ -0.85688532   ,    1.4584907  ]   ,
        [  0.52251546   ,   -2.58823074 ]   ,
        [ -0.50854056   ,    2.14048891 ]   ,
        [  1.3519594    ,   -0.46228006 ]   ,
        [  0.49842541   ,    6.02550774 ]   ,
        [ -0.06215962   ,    5.90720322 ]   ,
        [  1.76737745   ,   -1.70742272 ]   ,
        [ -1.35493332   ,   -1.10715532 ]   ,
        [  0.37475461   ,    1.35350426 ]   ,
        [ -1.03639261   ,   -0.60334725 ]   ,
        [  0.95453091   ,    0.38436805 ]   
    ];


print 'in k_nearest_neighbors_2D.pl, have $train_data_A = ', Dumper($train_data_A), "\n";

my number_arrayref_arrayref $train_data_B =
    [
#        [ 1.5,  3  ],
#        [-3,    7  ],
#        [ 3.5, -3.5],

        # PYTHON
        [ -1.50077801   ,   -1.52477188 ]   ,
        [ -6.13251492   ,    0.34514778 ]   ,
        [ -1.9654295    ,    1.11014045 ]   ,
        [  1.58884486   ,    0.92232399 ]   ,
        [ -0.87627685   ,   -0.27823327 ]   ,
        [  7.04125555   ,   -0.27993588 ]   ,
        [ -6.48629081   ,    0.12203121 ]   ,
        [  1.52576273   ,   -1.03419818 ]   ,
        [  2.8772457    ,    1.22098814 ]   ,
        [ -4.95202581   ,    0.55054009 ]   ,
        [ -0.00897329   ,   -1.30018077 ]   ,
        [  0.13476673   ,   -1.19366736 ]   ,
        [  0.12291227   ,    0.84934431 ]   ,
        [ -4.43001864   ,    0.94382577 ]   ,
        [  1.86301054   ,   -0.09722174 ]   ,
        [ -4.64619808   ,   -0.81635102 ]   ,
        [ -0.71134784   ,   -0.12029882 ]   ,
        [  4.24939394   ,    0.84211799 ]   ,
        [  2.15297488   ,    0.39634493 ]   ,
        [  0.27626963   ,   -0.02902144 ]   ,
        [ -0.90691975   ,    0.328699   ]   ,
        [ -1.33661805   ,   -0.04551647 ]   ,
        [ -5.40849205   ,   -0.54659816 ]   ,
        [ -3.33977239   ,   -0.71925377 ]   ,
        [ -4.79317705   ,   -0.46723375 ]   ,
        [ -2.10423867   ,    1.25116012 ]   ,
        [  4.6117719    ,   -0.90891143 ]   ,
        [ -3.45350021   ,   -1.1577272  ]   ,
        [ -2.15956658   ,   -0.23188081 ]   ,
        [ -2.83795482   ,   -0.05384199 ]   ,
        [ -0.82448634   ,    0.13621835 ]   ,
        [  1.19099935   ,   -0.841093   ]   ,
        [ -4.06228466   ,   -0.34070293 ]   ,
        [ -2.56687767   ,   -0.60520429 ]   ,
        [  2.96776074   ,    1.33419197 ]   ,
        [ -0.67098193   ,   -0.31383433 ]   ,
        [ -1.65931051   ,    0.8682241  ]   ,
        [  0.36457261   ,    0.02549203 ]   ,
        [ -1.34411634   ,    0.43610982 ]   ,
        [  1.75893902   ,   -0.57790005 ]   ,
        [ -0.27047299   ,   -0.13097902 ]   ,
        [ -0.04417533   ,   -1.56640032 ]   ,
        [ -4.14846905   ,    0.51559835 ]   ,
        [  0.60152947   ,   -0.45329234 ]   ,
        [ -4.64296791   ,    0.48533746 ]   ,
        [ -0.85161049   ,    0.21833885 ]   ,
        [ -1.10525844   ,   -1.87520691 ]   ,
        [  1.2803109    ,    0.49911747 ]   ,
        [  1.72920903   ,    0.92308467 ]   ,
        [ -4.13291816   ,    0.13777676 ]   
    ];

print 'in k_nearest_neighbors_2D.pl, have $train_data_B = ', Dumper($train_data_B), "\n";

my number_arrayref_arrayref $train_data_C =
    [
        [ 5,    2.5],
        [ 7.5,  9  ],
        [-8,   -3  ],
    ];
print 'in k_nearest_neighbors_2D.pl, have $train_data_C = ', Dumper($train_data_C), "\n";

my number_arrayref_arrayref $train_data_D =
    [
        [ 4.5,  0  ],
    ];
print 'in k_nearest_neighbors_2D.pl, have $train_data_D = ', Dumper($train_data_D), "\n";

# generate $test_data;
# copy & paste from Python example for now
my number_arrayref_arrayref $test_data =
    [
#        [2, 3],
#        [3, 2],
#        [7, 4],
#        [4, 7],

        # PYTHON
        [ -3.96534395   ,   -0.82902329 ]   ,
        [  2.23135291   ,   -3.5533311  ]   ,
        [  5.02763677   ,    2.72597886 ]   ,
        [  2.58994148   ,   -5.33640833 ]   ,
        [ -4.79920439   ,    3.15399303 ]   ,
        [ -0.64522378   ,    4.12817554 ]   ,
        [ -3.83656154   ,   -1.66552787 ]   ,
        [  4.11695479   ,   -4.35066466 ]   ,
        [ -2.21426699   ,   -0.79198347 ]   ,
        [  2.69766118   ,    4.00446433 ]   ,
        [ -2.84092366   ,   -0.8257502  ]   ,
        [ -5.8707038    ,   -2.01946919 ]   ,
        [  2.10655717   ,    2.82163838 ]   ,
        [  2.12950122   ,   -0.79043461 ]   ,
        [ -2.89831484   ,   -1.83684213 ]   ,
        [ -2.36276645   ,   -0.76320827 ]   ,
        [  0.64259827   ,   -4.64759121 ]   ,
        [ -4.33547064   ,    2.22377513 ]   ,
        [  1.28148674   ,   -1.20661431 ]   ,
        [ -4.11029157   ,   -2.99453875 ]   ,
        [  0.11088396   ,    0.69920335 ]   ,
        [ -0.57005441   ,    1.2144661  ]   ,
        [  1.47916692   ,   -1.44101439 ]   ,
        [ -4.83837184   ,    2.21002145 ]   ,
        [  0.89057334   ,    2.81989985 ]   ,
        [  0.62468568   ,   -2.95783148 ]   ,
        [  2.82486891   ,    2.92851301 ]   ,
        [ -1.31684637   ,    4.12059824 ]   ,
        [  0.50049946   ,   -4.4632458  ]   ,
        [ -0.71183069   ,    8.07408027 ]   ,
        [ -2.90533239   ,   -2.93168862 ]   ,
        [  4.55688556   ,   -5.44956048 ]   ,
        [  1.8951112    ,    1.74661211 ]   ,
        [ -1.07516332   ,   -1.12080175 ]   ,
        [ -2.92899938   ,   -1.83421914 ]   ,
        [  0.89968995   ,    5.25100493 ]   ,
        [  0.79786826   ,   -3.64813682 ]   ,
        [  3.42326571   ,   -1.63250674 ]   ,
        [ -2.81766105   ,   -3.03253414 ]   ,
        [ -3.73628791   ,   -2.03268892 ]   ,
        [  1.79527047   ,   -2.22164886 ]   ,
        [ -6.72491891   ,   -1.13147323 ]   ,
        [ -1.95340108   ,    4.01658556 ]   ,
        [ -3.12318092   ,   -5.27572612 ]   ,
        [  4.86942559   ,    1.80284271 ]   ,
        [ -1.94911954   ,   -3.25102304 ]   ,
        [ -2.10365981   ,   -1.60003309 ]   ,
        [  2.31549512   ,   -2.62598269 ]   ,
        [  7.52649023   ,    1.59437539 ]   ,
        [  1.46190036   ,   -1.54228628 ]   
    ];

print 'in k_nearest_neighbors_2D.pl, have $test_data = ', Dumper($test_data), "\n";

# create KNN classifier and fit to training data

# DEV NOTE, CORRELATION #MLCKNN00: unpredictable behavior when (number of unique train_classifications > 2) or (n_neighbors is even)
# k = 3  # PYTHON
my integer $k = 3;
print 'in k_nearest_neighbors_2D.pl, have $k = ', $k, "\n";

# knn = KNeighborsClassifier(n_neighbors=k, weights='uniform', metric='euclidean', p=2)  # PYTHON
# NEED UPGRADE: support constructor parameters for Inline::CPP object AKA blessed special thing
# (not Moose object, or RPerl PERLOPS_PERLTYPES object AKA blessed hash, or RPerl CPPOPS_CPPTYPES object)
#my $knn = MLPerl::Classifier::KNeighbors->new({n_neighbors => $k, metric => 'euclidean'});
my MLPerl::Classifier::KNeighbors $knn = MLPerl::Classifier::KNeighbors->new();
$knn->set_n_neighbors($k);
$knn->set_metric('euclidean');

# train_data = np.concatenate((train_data_A, train_data_B))  # PYTHON
my number_arrayref_arrayref $train_data = concatenate($train_data_A, $train_data_B);
print 'in k_nearest_neighbors_2D.pl, have $train_data = ', Dumper($train_data), "\n";

# train_classifications = np.concatenate(([0 for _ in range(train_data_A.size)],[1 for _ in range(train_data_B.size)]))  # PYTHON
my string_arrayref $train_classifications = 
    concatenate(for_range('0', (scalar @{$train_data_A})), for_range('1', (scalar @{$train_data_B})));

# DEV NOTE, CORRELATION #MLCKNN00: unpredictable behavior when (number of unique train_classifications > 2) or (n_neighbors is even)
#    [];
#my $train_classifications_basis = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
#for (my integer $i = 0; $i < ((scalar @{$train_data_A}) + (scalar @{$train_data_B})); $i++) {
#    $train_classifications->[$i] = $train_classifications_basis->[($i % (scalar @{$train_classifications_basis}))];
#}

print 'in k_nearest_neighbors_2D.pl, have $train_classifications = ', "\n";
foreach my string $train_classification (@{$train_classifications}) { print $train_classification, "\n"; }
print 'in k_nearest_neighbors_2D.pl, about to call $knn->fit()...', "\n";

# knn.fit(train_data, train_classifications)  # PYTHON
$knn->fit($train_data, $train_classifications);
#$knn->set_train_data($train_data);                        # also works fine
#$knn->set_train_classifications($train_classifications);  # also works fine
print 'in k_nearest_neighbors_2D.pl, have $knn = ', Dumper($knn), "\n";

# generate and list classifier's predictions
print 'in k_nearest_neighbors_2D.pl, about to call $knn->predict()...', "\n";
my number $time_start = time();

# repeat for timing purposes
my string_arrayref $tests_classifications;
# call predict_repeat() for timings w/out data conversion overhead of XS_pack*() & XS_unpack*()
#for (my integer $i = 0; $i < $timing_repetitions; $i++) {
#    # tests_classifications = knn.predict(test_data)  # PYTHON
#    $tests_classifications = $knn->predict($test_data);
#}

$tests_classifications = $knn->predict_repeat($test_data, $timing_repetitions);

my number $time_total = time() - $time_start;
print 'time total:   ' . $time_total . ' seconds' . "\n";
#print 'in k_nearest_neighbors_2D.pl, returned from call to $knn->predict(), received $tests_classifications = ', Dumper($tests_classifications), "\n";
print 'in k_nearest_neighbors_2D.pl, returned from call to $knn->predict(), received $tests_classifications = ', "\n";
foreach my string $test_classifications (@{$tests_classifications}) { print $test_classifications, "\n"; }


# call hard-coded Euclidean metric & uniform weights version

print 'in k_nearest_neighbors_m_e_w_uD.pl, about to call $knn->predict_metric_euclidean_weights_uniform()...', "\n";
my number $time_start_m_e_w_u = time();

# repeat for timing purposes
my string_arrayref $tests_classifications_m_e_w_u;

# call predict_repeat_metric_euclidean_weights_uniform() for timings w/out data conversion overhead of XS_pack*() & XS_unpack*()
#for (my integer $i = 0; $i < $timing_repetitions; $i++) {
#    $tests_classifications_m_e_w_u = $knn->predict_metric_euclidean_weights_uniform($test_data);
#}

$tests_classifications_m_e_w_u = $knn->predict_repeat_metric_euclidean_weights_uniform($test_data, $timing_repetitions);

my number $time_total_m_e_w_u = time() - $time_start_m_e_w_u;
print 'time total:   ' . $time_total_m_e_w_u . ' seconds' . "\n";
#print 'in k_nearest_neighbors_m_e_w_uD.pl, returned from call to $knn->predict_metric_euclidean_weights_uniform(), received $tests_classifications_m_e_w_u = ', Dumper($tests_classifications_m_e_w_u), "\n";
print 'in k_nearest_neighbors_m_e_w_uD.pl, returned from call to $knn->predict_metric_euclidean_weights_uniform(), received $tests_classifications_m_e_w_u = ', "\n";
foreach my string $test_classifications_m_e_w_u (@{$tests_classifications_m_e_w_u}) { print $test_classifications_m_e_w_u, "\n"; }
