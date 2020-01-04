#!/usr/bin/env perl

# MLPerl, K Nearest Neighbors 2D, Demo Driver
# Load training points, find K nearest neighbors to classify test points

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '0' >>>
# <<< EXECUTE_SUCCESS: '1' >>>
# <<< EXECUTE_SUCCESS: '0' >>>


use RPerl;  use strict;  use warnings;
our $VERSION = 0.006_000;

use MLPerl::PythonShims qw(concatenate for_range);
use MLPerl::Classifier::KNeighbors;

# read external data
my string $file_name = 'script/demo/k_nearest_neighbors_2D_data_50_50_100.pl';
open my filehandleref $FILE_HANDLE, '<', $file_name
    or die 'ERROR EMLKNN2D10: Cannot open file ' . q{'} . $file_name . q{'} . ' for reading, ' . $OS_ERROR . ', dying' . "\n";
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
my object $knn = MLPerl::Classifier::KNeighbors->new();  $knn->set_n_neighbors($k);  $knn->set_metric('euclidean');

# fit KNN classifier to training data
$knn->fit($train_data, $train_classifications);

# generate and display KNN classifier's predictions
my string_arrayref $tests_classifications = $knn->predict($test_data);
foreach my string $test_classifications (@{$tests_classifications}) { print $test_classifications, "\n"; }
