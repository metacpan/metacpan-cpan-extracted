# [[[ HEADER ]]]
package MLPerl::Classifier::KNeighbors;
use strict;
use warnings;
use RPerl::AfterSubclass;
our $VERSION = 0.007_000;

# [[[ OO INHERITANCE ]]]
use parent qw(MLPerl::Classifier);
use MLPerl::Classifier;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls) # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitCStyleForLoops)  # USER DEFAULT 6: allow C-style for() loop headers
## no critic qw(ProhibitParensWithBuiltins)  # USER DEFAULT 7: allow explicit parentheses for clearer order-of-operations precedence
## no critic qw(ProhibitExcessComplexity)  # SYSTEM SPECIAL 5: allow complex code inside subroutines, must be after line 1
## no critic qw(RequireCarping)  # SYSTEM SPECIAL 13: allow die instead of croak

# [[[ INCLUDES ]]]
use MLPerl::Classifier::KNeighbors::Neighbor2D;
#use Data::Dumper;

# DEV NOTE, CORRELATION #MLCKNN00: unpredictable behavior when (number of unique train_classifications > 2) or (n_neighbors is even)
# because this allows nearest neighbors' classification counts to be equal;
# see 'NEED ANSWER: selects arbitrary classification when counts are equal, properly handle equal classification counts?'

# PYTHON
# KNeighborsClassifier(
# algorithm='auto',
# leaf_size=30,
# metric='minkowski',
# metric_params=None,
# n_jobs=None,
# n_neighbors=3,
# p=2,
# weights='uniform')

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    algorithm   => my string  $TYPED_algorithm   = 'auto',       # default
    leaf_size   => my integer $TYPED_leaf_size   = 30,           # default
    metric      => my string  $TYPED_metric      = 'minkowski',  # default
#    metric_params => my FOO $TYPED_metric_params = ...,  # NEED UPGRADE: what kind of data structure should this be?
    n_jobs      => my integer $TYPED_n_jobs      = 1,  # number of parallel jobs to run for neighbors search; -1 means using all processors
    n_neighbors => my integer $TYPED_n_neighbors = 3,            # default
    p           => my integer $TYPED_p           = 2,            # default; power parameter for the Minkowski metric
    weights     => my string  $TYPED_weights     = 'uniform',    # default

    train_data            => my number_arrayref_arrayref $TYPED_train_data            = undef,
    train_classifications => my string_arrayref          $TYPED_train_classifications = undef
};

# NEED UPGRADE: change Neighbor2D to inherit from MathPerl::...::Point2D???

# NEED UPGRADE, FUTURE META-PARAMETERS: choice between parallelizing across training points VS serial saving only nearest k training points VS hybrid serialized nearest k training points w/ follow-up combination of nearest k's

# [[[ SUBROUTINES & OO METHODS ]]]

# no actual fitting for KNN, just set properties
sub fit {
    { my void::method $RETURN_TYPE };
    ( my MLPerl::Classifier::KNeighbors $self,
      my number_arrayref_arrayref $train_data,
      my string_arrayref          $train_classifications ) = @ARG;

    $self->{train_data} = $train_data;
    $self->{train_classifications} = $train_classifications;

    return;
}


# repeatedly call predict() for timing purposes
sub predict_repeat {
    { my string_arrayref::method $RETURN_TYPE };
    ( my MLPerl::Classifier::KNeighbors $self, my number_arrayref_arrayref $test_data, my integer $timing_repetitions ) = @ARG;

    my string_arrayref $tests_classifications;

    for (my integer $repetition = 0; $repetition < $timing_repetitions; $repetition++) {
        $tests_classifications = $self->predict($test_data);
    }

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_repeat(), about to return $tests_classifications =', "\n", string_arrayref_to_string($tests_classifications), "\n";

    return $tests_classifications;
}


# repeatedly call predict_metric_euclidean_weights_uniform() for timing purposes
sub predict_repeat_metric_euclidean_weights_uniform {
    { my string_arrayref::method $RETURN_TYPE };
    ( my MLPerl::Classifier::KNeighbors $self, my number_arrayref_arrayref $test_data, my integer $timing_repetitions ) = @ARG;

    my string_arrayref $tests_classifications;

    for (my integer $repetition = 0; $repetition < $timing_repetitions; $repetition++) {
        $tests_classifications = $self->predict_metric_euclidean_weights_uniform($test_data);
    }

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_repeat_metric_euclidean_weights_uniform(), about to return $tests_classifications =', "\n", string_arrayref_to_string($tests_classifications), "\n";

    return $tests_classifications;
}


# predict the class labels for the provided data
sub predict {
    { my string_arrayref::method $RETURN_TYPE };
    ( my MLPerl::Classifier::KNeighbors $self, my number_arrayref_arrayref $test_data ) = @ARG;

    my integer $test_data_count = scalar @{$test_data};

    # AVOID SEGMENTATION FAULT: create new string_arrayref of size $test_data_count, to receive predict_single() return values
#    my string_arrayref $tests_classifications = [];
    my string_arrayref $tests_classifications->[$test_data_count - 1] = undef;

    # call KNN for each testing point
#    PARALLEL__CALL_PREDICT_SINGLE:
    for (my integer $i = 0; $i < $test_data_count; $i++) {
#        print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict(), have $i = ', $i, ', about to call predict_single()...', "\n";

        $tests_classifications->[$i] = $self->predict_single($test_data->[$i]);

#        print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict(), have $i = ', $i, ', returned from predict_single()...', "\n";
    }

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict(), about to return $tests_classifications =', "\n", string_arrayref_to_string($tests_classifications), "\n";

    return $tests_classifications;
}


# predict the class labels for the provided data, optimized for Euclidean distance and uniform weights
sub predict_metric_euclidean_weights_uniform {
    { my string_arrayref::method $RETURN_TYPE };
    ( my MLPerl::Classifier::KNeighbors $self, my number_arrayref_arrayref $test_data ) = @ARG;

    my integer $test_data_count = scalar @{$test_data};

    # AVOID SEGMENTATION FAULT: create new string_arrayref of size $test_data_count, to receive predict_single() return values
#    my string_arrayref $tests_classifications = [];
    my string_arrayref $tests_classifications->[$test_data_count - 1] = undef;

    # call KNN for each testing point
#    PARALLEL__CALL_PREDICT_SINGLE:
    for (my integer $i = 0; $i < $test_data_count; $i++) {
        $tests_classifications->[$i] = $self->predict_single_metric_euclidean_weights_uniform($test_data->[$i]);
    }

    return $tests_classifications;
}


# find the K Nearest Neighbors and classification of a test point in 2D
sub predict_single {
    { my string::method $RETURN_TYPE };
    ( my MLPerl::Classifier::KNeighbors $self, my number_arrayref $test_data_single ) = @ARG;

    my integer $train_data_count = scalar @{$self->{train_data}};
    my integer $n_neighbors_index_max = $self->{n_neighbors} - 1;

    # initialize size of $neighbors to n_neighbors
    my MLPerl::Classifier::KNeighbors::Neighbor2D_arrayref $neighbors->[$self->{n_neighbors} - 1] = undef;

    # [ OPTIMIZED FOR MEMORY & SPEED ]
    # store only n_neighbors distances, faster, uses less memory
    for (my integer $i = 0; $i <= $n_neighbors_index_max; $i++) {
        $neighbors->[$i] = MLPerl::Classifier::KNeighbors::Neighbor2D->new();
        $neighbors->[$i]->{distance} = -1;
    }

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single(), done initializing $neighbors', "\n";

    # NEED FIX: RPerl incorrectly believes for-loop-scoped variable instantiations overlap
    # ERROR ECOGEASRP012, CODE GENERATOR, ABSTRACT SYNTAX TO RPERL: variable '$train_data_single' already declared in this scope, namespace 'MLPerl::Classifier::KNeighbors::', subroutine/method 'predict_single()', dying
    my number_arrayref $train_data_single;
    my number $distance;
    my number $neighbor_largest_distance_value;
    my integer $neighbor_largest_distance_index;

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single(), have $self->{metric} = ', $self->{metric}, "\n";

    # calculate the Manhattan or Euclidean or Minkowski distance between $test_data_single and each $train_data_single;
    if ($self->{metric} eq 'manhattan') {
#        SERIAL__CALCULATE_DISTANCES_MANHATTAN:
        for (my integer $i = 0; $i < $train_data_count; $i++) {
            $train_data_single = $self->{train_data}->[$i];

            # [ PARALLEL, UN-OPTIMIZED FOR MEMORY & SPEED ]
            # store all distances, slower, uses more memory;
            # attach calculated distance to each $train_data_single by creating new Neighbor object;
            # does not modify more than one element of $neighbors at a time, so thread safe here in for() loop;
            # does not modify $self->{train_data} directly, so thread safe in parent subroutine predict()
#            $neighbors->[$i] = MLPerl::Classifier::KNeighbors::Neighbor2D->new();
#            $neighbors->[$i]->{data} = $train_data_single;
#            $neighbors->[$i]->{classification} = $self->{train_classifications}->[$i];
#            $neighbors->[$i]->{distance} = (abs ($train_data_single->[0] - $test_data_single->[0])) +
#                                           (abs ($train_data_single->[1] - $test_data_single->[1]));

            # [ SERIAL, OPTIMIZED FOR MEMORY & SPEED ]
            # store only n_neighbors distances, faster, uses less memory;
            # attach calculated distance to a $train_data_single only if among lowest n_neighbors distances;
            # does     modify more than one element of $neighbors at a time, so NOT thread safe here in for() loop;
            # does not modify $self->{train_data} directly, so thread safe in parent subroutine predict()
            $distance = (abs ($train_data_single->[0] - $test_data_single->[0])) +
                        (abs ($train_data_single->[1] - $test_data_single->[1]));

            # DEV NOTE, CORRELATION #MLCKNN01: begin duplicate code
            # store first n_neighbors distances directly, do not test values
            if ( $i <= $n_neighbors_index_max ) {
                $neighbors->[$i]->{data} = $train_data_single;
                $neighbors->[$i]->{classification} = $self->{train_classifications}->[$i];
                $neighbors->[$i]->{distance} = $distance;
            }
            else {  # before storing additional distances, test values
                # [ OPTIMIZED FOR SPEED ]
                # search for largest distance, O(n_neighbors)
                $neighbor_largest_distance_value = $neighbors->[0]->{distance};
                $neighbor_largest_distance_index = 0;
                for (my integer $j = 1; $j <= $n_neighbors_index_max; $j++) {
                    # NEED ANSWER: selects arbitrary neighbor when distances are equal, properly handle equal distances?
                    if ($neighbors->[$j]->{distance} > $neighbor_largest_distance_value) {
                        $neighbor_largest_distance_value = $neighbors->[$j]->{distance};
                        $neighbor_largest_distance_index = $j;
                    }
                }
                # only test largest stored distance, overwrite if beaten
                if ( $neighbors->[$neighbor_largest_distance_index]->{distance} > $distance ) {
                     $neighbors->[$neighbor_largest_distance_index]->{data} = $train_data_single;
                     $neighbors->[$neighbor_largest_distance_index]->{classification} = $self->{train_classifications}->[$i];
                     $neighbors->[$neighbor_largest_distance_index]->{distance} = $distance;
                }
            # DEV NOTE, CORRELATION #MLCKNN01: end duplicate code

                # [ UN-OPTIMIZED FOR SPEED ]
#                # NEED ANSWER: selects arbitrary neighbor when distances are equal, properly handle equal distances?
#                # sort distances, O(n_neighbors**2)
#                $neighbors = [ sort {$a->{distance} <=> $b->{distance}} @{$neighbors} ];
#                # only test largest stored distance, overwrite if beaten
#                if ( $neighbors->[$n_neighbors_index_max]->{distance} > $distance ) {   
#                    $neighbors->[$n_neighbors_index_max]->{data} = $train_data_single;
#                    $neighbors->[$n_neighbors_index_max]->{classification} = $self->{train_classifications}->[$i];
#                    $neighbors->[$n_neighbors_index_max]->{distance} = $distance;
#                }
            }
        }
    }
    elsif ($self->{metric} eq 'euclidean') {
#        SERIAL__CALCULATE_DISTANCES_EUCLIDEAN:
        for (my integer $i = 0; $i < $train_data_count; $i++) {
            $train_data_single = $self->{train_data}->[$i];

            # store only n_neighbors distances
            $distance = sqrt(($train_data_single->[0] - $test_data_single->[0])**2 +
                             ($train_data_single->[1] - $test_data_single->[1])**2);

#            print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single(), have $i = ', $i, ', $distance = ', $distance, "\n";

            # DEV NOTE, CORRELATION #MLCKNN01: begin duplicate code
            # store first n_neighbors distances directly, do not test values
            if ( $i <= $n_neighbors_index_max ) {
                $neighbors->[$i]->{data} = $train_data_single;
                $neighbors->[$i]->{classification} = $self->{train_classifications}->[$i];
                $neighbors->[$i]->{distance} = $distance;
            }
            else {  # before storing additional distances, test values
                # search for largest distance, O(n_neighbors)
                $neighbor_largest_distance_value = $neighbors->[0]->{distance};
                $neighbor_largest_distance_index = 0;
                for (my integer $j = 1; $j <= $n_neighbors_index_max; $j++) {
                    # NEED ANSWER: selects arbitrary neighbor when distances are equal, properly handle equal distances?
                    if ($neighbors->[$j]->{distance} > $neighbor_largest_distance_value) {
                        $neighbor_largest_distance_value = $neighbors->[$j]->{distance};
                        $neighbor_largest_distance_index = $j;
                    }
                }
                # only test largest stored distance, overwrite if beaten
                if ( $neighbors->[$neighbor_largest_distance_index]->{distance} > $distance ) {
                     $neighbors->[$neighbor_largest_distance_index]->{data} = $train_data_single;
                     $neighbors->[$neighbor_largest_distance_index]->{classification} = $self->{train_classifications}->[$i];
                     $neighbors->[$neighbor_largest_distance_index]->{distance} = $distance;
                }
            }
            # DEV NOTE, CORRELATION #MLCKNN01: end duplicate code
        }
    }
    elsif ($self->{metric} eq 'minkowski') {
        if ($self->{p} <= 0) {
            die 'ERROR EMLKNN2D01: Minkowski distance power must be greater than 0, dying';
        }

#        SERIAL__CALCULATE_DISTANCES_MINKOWSKI:
        for (my integer $i = 0; $i < $train_data_count; $i++) {
            $train_data_single = $self->{train_data}->[$i];

            # store only n_neighbors distances
            $distance = (((abs ($train_data_single->[0] - $test_data_single->[0])) ** $self->{p}) +
                         ((abs ($train_data_single->[1] - $test_data_single->[1])) ** $self->{p}))
                            ** (1 / $self->{p});

            # DEV NOTE, CORRELATION #MLCKNN01: begin duplicate code
            # store first n_neighbors distances directly, do not test values
            if ( $i <= $n_neighbors_index_max ) {
                $neighbors->[$i]->{data} = $train_data_single;
                $neighbors->[$i]->{classification} = $self->{train_classifications}->[$i];
                $neighbors->[$i]->{distance} = $distance;
            }
            else {  # before storing additional distances, test values
                # search for largest distance, O(n_neighbors)
                $neighbor_largest_distance_value = $neighbors->[0]->{distance};
                $neighbor_largest_distance_index = 0;
                for (my integer $j = 1; $j <= $n_neighbors_index_max; $j++) {
                    # NEED ANSWER: selects arbitrary neighbor when distances are equal, properly handle equal distances?
                    if ($neighbors->[$j]->{distance} > $neighbor_largest_distance_value) {
                        $neighbor_largest_distance_value = $neighbors->[$j]->{distance};
                        $neighbor_largest_distance_index = $j;
                    }
                }
                # only test largest stored distance, overwrite if beaten
                if ( $neighbors->[$neighbor_largest_distance_index]->{distance} > $distance ) {
                     $neighbors->[$neighbor_largest_distance_index]->{data} = $train_data_single;
                     $neighbors->[$neighbor_largest_distance_index]->{classification} = $self->{train_classifications}->[$i];
                     $neighbors->[$neighbor_largest_distance_index]->{distance} = $distance;
                }
            }
            # DEV NOTE, CORRELATION #MLCKNN01: end duplicate code
        }
    }
    else {
            die q{ERROR EMLKNN2D00: Unknown distance metric '} . $self->{metric} .
                q{', must be 'manhattan' or 'euclidean' or 'minkowski', dying};
    }

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single(), after calculating distances, have $neighbors = ', Dumper($neighbors), "\n";

    # count occurrences of each classification, O(n_neighbors);
    # does not modify $self->{train_data} directly, so thread safe in parent subroutine predict()
    my integer_hashref $k_nearest_classification_counts = {};

#    SERIAL__COUNT_GROUPS:
    for (my integer $i = 0; $i < $self->{n_neighbors}; $i++) {
        my string $classification = $neighbors->[$i]->{classification};
        if (not exists $k_nearest_classification_counts->{$classification}) {
            $k_nearest_classification_counts->{$classification} = 0;
        }
        if ($self->{weights} eq 'uniform') {
            $k_nearest_classification_counts->{$classification} += 1;
        }
        elsif ($self->{weights} eq 'distance') {


            # NEED TEST: ensure we are actually getting the correct inverse-distance
            # NEED TEST: ensure we are actually getting the correct inverse-distance
            # NEED TEST: ensure we are actually getting the correct inverse-distance


            $k_nearest_classification_counts->{$classification} += (1 / $neighbors->[$i]->{distance});
        }
        else {
            die q{ERROR EMLKNN2D02: Unknown weight function '} . $self->{weights} .
                q{', must be 'uniform' or 'distance' or callable subroutine, dying};
        }
    }

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single(), after selecting K nearest neighbors and counting classification occurrences, have $k_nearest_classification_counts = ', Dumper($k_nearest_classification_counts), "\n";

    # [ UN-OPTIMIZED FOR SPEED ]
#    # sort classifications by count, O(unique classifications ** 2)
#    # NEED ANSWER: selects arbitrary classification when counts are equal, properly handle equal classification counts?
#    my string_hashref $k_nearest_classifications_sorted =
#        [ sort { $k_nearest_classification_counts->{$a} <=> $k_nearest_classification_counts->{$b} } 
#            keys %{$k_nearest_classification_counts} ];
#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single(), have $k_nearest_classifications_sorted = ', Dumper($k_nearest_classifications_sorted), "\n";
#    # select highest classification by count
#    my string  $k_nearest_classification       = $k_nearest_classifications_sorted->[-1];
#    my integer $k_nearest_classification_count = $k_nearest_classification_counts->{$k_nearest_classification};

    # [ OPTIMIZED FOR SPEED ]
    # search for largest classification count, O(unique classifications)
    my string_arrayref $k_nearest_classification_counts_keys = [keys %{$k_nearest_classification_counts}];
    my number  $classifications_largest_count_value = $k_nearest_classification_counts->{$k_nearest_classification_counts_keys->[0]};
    my string  $classifications_largest_count_key = $k_nearest_classification_counts_keys->[0];
    my integer $k_nearest_classification_counts_keys_count = scalar @{$k_nearest_classification_counts_keys};
    # NEED ANSWER: selects arbitrary classification when counts are equal, properly handle equal classification counts?
#    SERIAL__FIND_LARGEST_GROUP:
    for (my integer $j = 1; $j < $k_nearest_classification_counts_keys_count; $j++) {
        if ($k_nearest_classification_counts->{$k_nearest_classification_counts_keys->[$j]} > $classifications_largest_count_value) {
            $classifications_largest_count_value = $k_nearest_classification_counts->{$k_nearest_classification_counts_keys->[$j]};
            $classifications_largest_count_key = $k_nearest_classification_counts_keys->[$j];
        }
    }

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single(), have final $classifications_largest_count_value = ', $classifications_largest_count_value, "\n";
#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single(), about to return $classifications_largest_count_key = ', $classifications_largest_count_key, "\n";

    return $classifications_largest_count_key;
}


# find the K Nearest Neighbors and classification of a test point in 2D, optimized for Euclidean distance and uniform weights
sub predict_single_metric_euclidean_weights_uniform {
    { my string::method $RETURN_TYPE };
    ( my MLPerl::Classifier::KNeighbors $self, my number_arrayref $test_data_single ) = @ARG;

    my integer $train_data_count = scalar @{$self->{train_data}};
    my integer $n_neighbors_index_max = $self->{n_neighbors} - 1;

    # initialize size of $neighbors to n_neighbors
    my MLPerl::Classifier::KNeighbors::Neighbor2D_arrayref $neighbors->[$self->{n_neighbors} - 1] = undef;

    # [ OPTIMIZED FOR MEMORY & SPEED ]
    # store only n_neighbors distances, faster, uses less memory
    for (my integer $i = 0; $i <= $n_neighbors_index_max; $i++) {
        $neighbors->[$i] = MLPerl::Classifier::KNeighbors::Neighbor2D->new();
        $neighbors->[$i]->{distance} = -1;
    }

    # NEED FIX: RPerl incorrectly believes for-loop-scoped variable instantiations overlap;
    # does not actually affect this subroutine because only euclidean distance is implemented, make change here to match predict_single()
    # ERROR ECOGEASRP012, CODE GENERATOR, ABSTRACT SYNTAX TO RPERL: variable '$train_data_single' already declared in this scope, namespace 'MLPerl::Classifier::KNeighbors::', subroutine/method 'predict_single()', dying
    my number_arrayref $train_data_single;
    my number $distance;
    my number $neighbor_largest_distance_value;
    my integer $neighbor_largest_distance_index;

    # calculate the Euclidean distance between $test_data_single and each $train_data_single;
    # attach calculated distance to each $train_data_single by creating new Neighbor object;
    # does not modify $self->{train_data} directly, so thread safe in parent subroutine predict()
#    SERIAL__CALCULATE_DISTANCES_EUCLIDEAN:
    for (my integer $i = 0; $i < $train_data_count; $i++) {
        $train_data_single = $self->{train_data}->[$i];

        # store only n_neighbors distances
        $distance = sqrt(($train_data_single->[0] - $test_data_single->[0])**2 +
                         ($train_data_single->[1] - $test_data_single->[1])**2);

        # DEV NOTE, CORRELATION #MLCKNN01: begin duplicate code
        # store first n_neighbors distances directly, do not test values
        if ( $i <= $n_neighbors_index_max ) {
            $neighbors->[$i]->{data} = $train_data_single;
            $neighbors->[$i]->{classification} = $self->{train_classifications}->[$i];
            $neighbors->[$i]->{distance} = $distance;
        }
        else {  # before storing additional distances, test values
            $neighbor_largest_distance_value = $neighbors->[0]->{distance};
            $neighbor_largest_distance_index = 0;
            # search for largest distance, O(n_neighbors)
            for (my integer $j = 1; $j <= $n_neighbors_index_max; $j++) {
                # NEED ANSWER: selects arbitrary neighbor when distances are equal, properly handle equal distances?
                if ($neighbors->[$j]->{distance} > $neighbor_largest_distance_value) {
                    $neighbor_largest_distance_value = $neighbors->[$j]->{distance};
                    $neighbor_largest_distance_index = $j;
                }
            }
            # only test largest stored distance, overwrite if beaten
            if ( $neighbors->[$neighbor_largest_distance_index]->{distance} > $distance ) {
                 $neighbors->[$neighbor_largest_distance_index]->{data} = $train_data_single;
                 $neighbors->[$neighbor_largest_distance_index]->{classification} = $self->{train_classifications}->[$i];
                 $neighbors->[$neighbor_largest_distance_index]->{distance} = $distance;
            }
        }
        # DEV NOTE, CORRELATION #MLCKNN01: end duplicate code
    }

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single_metric_euclidean_weights_uniform(), after calculating distances, have $neighbors = ', Dumper($neighbors), "\n";

    # count occurrences of each classification, O(n_neighbors);
    # does not modify $self->{train_data} directly, so thread safe in parent subroutine predict()
    my integer_hashref $k_nearest_classification_counts = {};

#    SERIAL__COUNT_GROUPS__WEIGHTS_UNIFORM:
    for (my integer $i = 0; $i < $self->{n_neighbors}; $i++) {
        my string $classification = $neighbors->[$i]->{classification};
        if (not exists $k_nearest_classification_counts->{$classification}) {
            $k_nearest_classification_counts->{$classification} = 0;
        }
        $k_nearest_classification_counts->{$classification} += 1;
    }

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single_metric_euclidean_weights_uniform(), after selecting K nearest neighbors and counting classification occurrences, have $k_nearest_classification_counts = ', Dumper($k_nearest_classification_counts), "\n";

    # search for largest classification count, O(unique classifications)
    my string_arrayref $k_nearest_classification_counts_keys = [keys %{$k_nearest_classification_counts}];
    my number  $classifications_largest_count_value = $k_nearest_classification_counts->{$k_nearest_classification_counts_keys->[0]};
    my string  $classifications_largest_count_key = $k_nearest_classification_counts_keys->[0];
    my integer $k_nearest_classification_counts_keys_count = scalar @{$k_nearest_classification_counts_keys};
    # NEED ANSWER: selects arbitrary classification when counts are equal, properly handle equal classification counts?
#    SERIAL__FIND_LARGEST_GROUP:
    for (my integer $j = 1; $j < $k_nearest_classification_counts_keys_count; $j++) {
        if ($k_nearest_classification_counts->{$k_nearest_classification_counts_keys->[$j]} > $classifications_largest_count_value) {
            $classifications_largest_count_value = $k_nearest_classification_counts->{$k_nearest_classification_counts_keys->[$j]};
            $classifications_largest_count_key = $k_nearest_classification_counts_keys->[$j];
        }
    }

#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single_metric_euclidean_weights_uniform(), have final $classifications_largest_count_value = ', $classifications_largest_count_value, "\n";
#    print {*STDERR} 'in MLPerl::Classifier::KNeighbors::predict_single_metric_euclidean_weights_uniform(), about to return $classifications_largest_count_key = ', $classifications_largest_count_key, "\n";

    return $classifications_largest_count_key;
}

1;    # end of class
