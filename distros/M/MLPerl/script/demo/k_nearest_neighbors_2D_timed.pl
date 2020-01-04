#!/usr/bin/env perl

# MLPerl, K Nearest Neighbors 2D, Demo Driver
# Load training points, find K nearest neighbors to classify test points

use RPerl;  use strict;  use warnings;
our $VERSION = 0.007_000;


use MLPerl::PythonShims qw(concatenate for_range);
use MLPerl::Classifier::KNeighbors;
use Time::HiRes qw(time);

# [ BEGIN INPUT DATA SIZES ]
my string_arrayref $data_sizes_all = [
#    '25 25 50',
#    '50 50 100',
#    '125 125 250',
    '250 250 500',
#    '500 500 1000',
#    '1250 1250 2500',
#    '2500 2500 5000',
#    '5000 5000 10000',
#    '12500 12500 25000',
#    '25000 25000 50000',
#    '50000 50000 100000'
];
foreach my string $data_sizes (@{$data_sizes_all}) {
    my string $data_sizes_underscores = $data_sizes;
    $data_sizes_underscores =~ s/\ /_/g;
    my string $file_name = 'script/demo/k_nearest_neighbors_2D_data_' . ($data_sizes_underscores) . '.pl';

    # read external data
    (open my filehandleref $FILE_HANDLE, '<', $file_name) and (print 'Opened file ' . q{'} . $file_name . q{'} . ' for reading' . "\n")
        or (die 'ERROR EMLKNN2D10: Cannot open file ' . q{'} . $file_name . q{'} . ' for reading, ' . $OS_ERROR . ', dying' . "\n");
    read $FILE_HANDLE, my string $file_lines, -s $FILE_HANDLE;
    close $FILE_HANDLE
        or die 'ERROR EMLKNN2D11: Cannot close file ' . q{'} . $file_name . q{'} . ' after reading, ' . $OS_ERROR . ', dying' . "\n";

    # initialize local variables to hold external data
    my number_arrayref_arrayref $train_data_A = undef;
    my number_arrayref_arrayref $train_data_B = undef;
    my number_arrayref_arrayref $test_data = undef;

    # load external data
    eval($file_lines);

    # format train data, concatenate all train data arrays
    my number_arrayref_arrayref $train_data = concatenate($train_data_A, $train_data_B);

    # generate train data classifications
    my string_arrayref $train_classifications = concatenate(for_range('0', (scalar @{$train_data_A})), for_range('1', (scalar @{$train_data_B})));

    # create KNN classifier
    my integer $k = 3;
    my object $knn = MLPerl::Classifier::KNeighbors->new();
        $knn->set_n_jobs(1);  $knn->set_algorithm('brute');  $knn->set_n_neighbors($k);  $knn->set_metric('euclidean');

    # fit KNN classifier to training data
    $knn->fit($train_data, $train_classifications);

    # [ BEGIN TIMING REPETITIONS ]
    my integer_arrayref $timing_repetitions_all = [ 1, 5, 10, 25, 50, 100, 250, 500 ];
    foreach my integer $timing_repetitions (@{$timing_repetitions_all}) {

        # generate and display KNN classifier's predictions
        # run repeatedly for timing purposes
        my number $time_start = time();
        my string_arrayref $tests_classifications;
        for (my integer $i = 0; $i < $timing_repetitions; $i++) {
            $tests_classifications = $knn->predict($test_data); }
        my number $time_total = time() - $time_start;
        print $timing_repetitions . q{ } . $data_sizes . q{ } . sprintf("%.3f", $time_total) . "\n";
#        foreach my string $test_classifications (@{$tests_classifications}) { print $test_classifications, "\n"; }
    }  # [ END TIMING REPETITIONS ]

    print "\n";
}  # [ END INPUT DATA SIZES ]
