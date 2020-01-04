#!/usr/bin/env python3
# coding: utf-8

import numpy as np
# DELETED GRAPHICS: import matplotlib

#language_suffix           = 'pl'
language_suffix           = 'py'

train_and_test_data_sizes_all = [
#    [   25,   25,    50 ],
#    [   50,   50,   100 ],
#    [  125,  125,   250 ],
#    [  250,  250,   500 ],
#    [  500,  500,  1000 ],
#    [ 1250, 1250,  2500 ],
#    [ 2500, 2500,  5000 ],
#    [ 5000, 5000, 10000 ],
    [ 12500, 12500, 25000 ],
    [ 25000, 25000, 50000 ],
    [ 50000, 50000, 100000 ],
]

import math
def scalar_arrayref_arrayref_to_string(input_data):
    column_tab   = '    '
    column_width = 10
    log10_max    = 2

    output_string = '[' + '\n'
    i_max = len(input_data)
    for i in range(i_max):
        output_string += '    [ '
        j_max = len(input_data[i])
        for j in range(j_max):
#            element_to_string = str(input_data[i][j])  # high-precision, 20 significant digits, too much for now
            element_to_string = "%.9f" % input_data[i][j]
            post_space_count = column_width - len(element_to_string)

            # align negative signs
            if (input_data[i][j] >= 0):
                output_string += ' '
                post_space_count -= 1

            # align decimal points & right brackets
            if (abs(input_data[i][j]) > 1):
                pre_space_count = log10_max - math.floor(math.log10(abs(input_data[i][j])))
                output_string += (' ' * pre_space_count)  # align decimal points
                post_space_count += (log10_max - pre_space_count)  # align right brackets
            else:
                output_string += (' ' * log10_max)

            output_string += element_to_string

            # align elements in columns
            if (j < (j_max - 1)):
                output_string += ',' + column_tab  # comma nestled after element
#                output_string += column_tab       # comma spaced  after element, NEEDS ALIGN

            # align right brackets
            output_string += (' ' * post_space_count)          # comma nestled after element
#            output_string += ', ' + (' ' * post_space_count)  # comma spaced  after element, NEEDS ALIGN

        output_string += ' ]'
        if (i < (i_max - 1)):
            output_string += ','
        output_string += '\n'
    output_string += ']'
    return output_string


# [ BEGIN DATA SIZES ]
for train_and_test_data_index in range(len(train_and_test_data_sizes_all)):
    train_and_test_data_sizes = train_and_test_data_sizes_all[train_and_test_data_index]
    train_data_A_size = train_and_test_data_sizes[0]
    train_data_B_size = train_and_test_data_sizes[1]
    test_data_size    = train_and_test_data_sizes[2]

    # choose a fixed random number generator seed for reproducibility of training and test data
    np.random.seed(123456789)

    # generate random 2d elliptical training data for 2 classifications
    mean_0,mean_1 = [0, 0],[0, 0]
    covariant_0,covariant_1 = [[1, 0], [0, 10]],[[10, 0], [0, 1]]
    train_data_A_x, train_data_A_y = np.random.multivariate_normal(mean_0, covariant_0, train_data_A_size).T
    train_data_B_x, train_data_B_y = np.random.multivariate_normal(mean_1, covariant_1, train_data_B_size).T
    # DELETED GRAPHICS: display training data

    # format train data, concatenate arrays containing x and y coordinates
    train_data_A, train_data_B = np.c_[train_data_A_x, train_data_A_y], np.c_[train_data_B_x, train_data_B_y]

    # generate random bivariate test data
    mean_test, covariant_test = [0,0], [[10, 0], [0,10]]
    test_data_x, test_data_y = np.random.multivariate_normal(mean_test, covariant_test, test_data_size).T
    test_data = np.c_[test_data_x,test_data_y]
    # DELETED GRAPHICS: display test data

    # PYTHON OUTPUT
    if (language_suffix == 'py'):
        file_string = '#!/usr/bin/env python3' + '\n'
        file_string += 'import numpy as np' + '\n'
        file_string += 'train_data_A = np.array(\n' + scalar_arrayref_arrayref_to_string(train_data_A) + '\n' + ')' + '\n'
        file_string += 'train_data_B = np.array(\n' + scalar_arrayref_arrayref_to_string(train_data_B) + '\n' + ')' + '\n'
        file_string += 'test_data = np.array(\n' + scalar_arrayref_arrayref_to_string(test_data) + '\n' + ')' + '\n'

    # PERL OUTPUT
    if (language_suffix == 'pl'):
        file_string = '#!/usr/bin/env perl' + '\n'
        file_string += '$train_data_A =\n' + scalar_arrayref_arrayref_to_string(train_data_A) + ';\n'
        file_string += '$train_data_B =\n' + scalar_arrayref_arrayref_to_string(train_data_B) + ';\n'
        file_string += '$test_data = ' + scalar_arrayref_arrayref_to_string(test_data) + ';\n'

    file_name = 'k_nearest_neighbors_2D_data_' + str(train_data_A_size) + '_' + str(train_data_B_size) + '_' + str(test_data_size) + '.' + language_suffix
    print('file_name = ' + file_name)
    file_handle = open(file_name, "w")
    file_handle.write(file_string)
    file_handle.close()

# [ END DATA SIZES ]
