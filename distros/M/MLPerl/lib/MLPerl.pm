# [[[ HEADER ]]]
package MLPerl;
use strict;
use warnings;
use RPerl::AfterSubclass;
# DEV NOTE, CORRELATION #rp016: CPAN's underscore-is-beta (NOT RPerl's underscore-is-comma) numbering scheme utilized here, to preserve trailing zeros
our $VERSION = '0.101000';

# [[[ OO INHERITANCE ]]]
use parent qw(RPerl::CompileUnit::Module::Class);  # no non-system inheritance, only inherit from base class
use RPerl::CompileUnit::Module::Class;

# [[[ EXPORTS ]]]

# DEV NOTE: outside of RPerl itself, the only subroutines which should be in @EXPORT are data conversion routines for RPerl data types and data structures, 
# and which have unique names, such as full-length-name stringify routines;
# the only subroutines which should be in @EXPORT_OK are those meant for public use and which have unique names;
# all other subroutines should be invoked with their entire package name prefix

use RPerl::Exporter 'import';
#our @EXPORT = (
#                @MLPerl::BAZ::BAT::EXPORT,
#                );
#our @EXPORT_OK = (
#                @MLPerl::FOO::BAR::EXPORT_OK,
#                );

# [[[ INCLUDES ]]]
use MLPerl::Config;

# DEV NOTE: must explicitly import each subroutine in @EXPORT_OK

#use MLPerl::FOO::BAR qw(foo bar);
#use MLPerl::BAZ::BAT;

# [[[ OO PROPERTIES ]]]
our hashref $properties = {};

1;    # end of class

__END__

=encoding utf8

=for comment DEV NOTE: BEGIN INLINE CSS DIV

=begin html

<div id="scoped-content"><style type="text/css" scoped>

table.rperl {
    border-style: solid;
    border-width: 2px;
}

table.rperl > tbody > tr > th {
    background-color: #e0e0e0;
    text-align: center;
}

table.rperl > tbody > tr:nth-child(odd)  { background-color: #f5f5f5; }
table.rperl > tbody > tr:nth-child(even) { background-color: #ffffff; }

table.rperl > tbody > tr > th, td {
    border-style: solid;
    border-width: 1px;
    border-color: #cccccc;
    padding: 5px;
}

/* disable ".pod p" margins inside tables only */
table.rperl > tbody > tr > th > p { margin: 0px; }
table.rperl > tbody > tr > td > p { margin: 0px; }

/* right alignment for numeric precedence column of operators tables */
table.operators > tbody > tr > td:nth-child(5)  { text-align: right; }

</style>

=end html

=head1 NAME

MLPerl

Machine Learning in Perl, Using the RPerl Optimizing Compiler

=head1 DESCRIPTION

B<MLPerl> is a collection of algorithms and data structures used for building machine learning applications in Perl.  For general info:

L<http://mlperl.org>

L<http://rperl.org>

L<http://perlcommunity.org>

=head1 SYNOPSIS, KNN 2D BRUTE FORCE

Filename F<script/demo/k_nearest_neighbors_2D.pl>:

    #!/usr/bin/env perl
    
    # MLPerl, K Nearest Neighbors 2D, Demo Driver
    # Load training points, find K nearest neighbors to classify test points

    use RPerl;  use strict;  use warnings;
    our $VERSION = 0.007_000;

    use MLPerl::PythonShims qw(concatenate for_range);
    use MLPerl::Classifier::KNeighbors;

    # read external data
    my string $file_name = $ARGV[0];
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

=head1 SYNOPSIS, KNN 2D BRUTE FORCE, EXECUTE

=for rperl X<noncode>

    $ ./script/demo/k_nearest_neighbors_2D.pl ./script/demo/k_nearest_neighbors_2D_data_25_25_50.pl

=for rperl X</noncode>

=head1 SYNOPSIS, KNN 2D BRUTE FORCE, COMPILE & EXECUTE

=for rperl X<noncode>

    $ export RPERL_DEBUG=1 && export RPERL_VERBOSE=1
    $ rperl -V lib/MLPerl/Classifier/KNeighbors.pm
    $ ./script/demo/k_nearest_neighbors_2D.pl ./script/demo/k_nearest_neighbors_2D_data_25_25_50.pl

=for rperl X</noncode>

=head1 SEE ALSO

L<RPerl>

L<rperl>

=head1 AUTHOR

B<William N. Braswell, Jr.>

L<mailto:wbraswell@NOSPAM.cpan.org>

=for comment DEV NOTE: END INLINE CSS DIV

=for html </div>

=cut
