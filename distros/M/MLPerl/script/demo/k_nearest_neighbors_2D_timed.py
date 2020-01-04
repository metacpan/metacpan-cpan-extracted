#!/usr/bin/env python3

# MLPerl, K Nearest Neighbors 2D, Demo Driver
# Load training points, find K nearest neighbors to classify test points


VERSION = 0.007000

import sys
import numpy as np
from sklearn.neighbors import KNeighborsClassifier
import time

# [ BEGIN INPUT DATA SIZES ]
data_sizes_all = [
    '25 25 50',
    '50 50 100',
#    '125 125 250',
#    '250 250 500',
#    '500 500 1000',
#    '1250 1250 2500',
#    '2500 2500 5000',
#    '5000 5000 10000',
#    '12500 12500 25000',
#    '25000 25000 50000',
#    '50000 50000 100000'
]
for data_sizes in data_sizes_all:
    data_sizes_underscores = data_sizes
    data_sizes_underscores = data_sizes_underscores.replace(" ", "_")
    file_name = 'script/demo/k_nearest_neighbors_2D_data_' + data_sizes_underscores + '.py';

    # read external data
    FILE_HANDLE = open(file_name, "r")
    if FILE_HANDLE.mode != 'r': sys.exit("ERROR EMLKNN2D10: Can not open file ", file_name, " for reading, dying")
    else: print('Opened file ', "'", file_name, "'", ' for reading', "\n")
    file_lines = FILE_HANDLE.read()
    FILE_HANDLE.close()

    # initialize local variables to hold external data
    train_data_A = None
    train_data_B = None
    test_data = None

    # load external data
    exec(file_lines)

    # format train data, concatenate all train data arrays
    train_data = np.concatenate((train_data_A, train_data_B))

    # generate train data classifications
    train_classifications = np.concatenate((['0' for _ in range(len(train_data_A))], ['1' for _ in range(len(train_data_B))]))

    # create KNN classifier
    k = 3
    knn = KNeighborsClassifier(
        n_jobs=1, algorithm='brute', n_neighbors=k, weights='uniform', metric='euclidean')

    # fit KNN classifier to training data
    knn.fit(train_data, train_classifications)

    # [ BEGIN TIMING REPETITIONS ]
    timing_repetitions_all = [ 1, 5, 10, 25, 50, 100, 250, 500 ]
    for timing_repetitions in timing_repetitions_all:

        # generate and display KNN classifier's predictions
        # run repeatedly for timing purposes
        time_start = time.time()
        test_classifications = None
        for i in range(timing_repetitions):
            test_classifications = knn.predict(test_data)
        time_total = time.time() - time_start
        print(str(timing_repetitions) + ' ' + str(data_sizes) + ' ' + ('%.3f' % time_total))
#        for i in range(len(test_classifications)): print(test_classifications[i])
    # [ END TIMING REPETITIONS ]

    print("\n")
# [ END INPUT DATA SIZES ]
