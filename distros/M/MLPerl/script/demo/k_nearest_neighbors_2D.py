#!/usr/bin/env python3

# MLPerl, K Nearest Neighbors 2D, Demo Driver
# Load training points, find K nearest neighbors to classify test points


VERSION = 0.007000

import sys
import numpy as np
from sklearn.neighbors import KNeighborsClassifier

# read external data
file_name = sys.argv[1]
FILE_HANDLE = open(file_name, "r")
if FILE_HANDLE.mode != 'r':
    sys.exit("ERROR EMLKNN2D10: Can not open file ", file_name, " for reading, dying")
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
knn = KNeighborsClassifier(n_neighbors=k, weights='uniform', metric='euclidean', p=2)

# fit KNN classifier to training data
knn.fit(train_data, train_classifications)

# generate and display KNN classifier's predictions
test_classifications = knn.predict(test_data)
for i in range(len(test_classifications)): print(test_classifications[i])
