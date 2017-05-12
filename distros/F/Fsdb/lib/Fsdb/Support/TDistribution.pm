#!/usr/bin/perl -w

#
# Fsdb::Support::TDistribution.pm
# Copyright (C) 1995-1998 by John Heidemann <johnh@ficus.cs.ucla.edu>
# $Id: c16ee50eb7a15728d65c5c44ec920470ba64d366 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

#
# This code is a Perl port of Geoff Kuenning's C-lanague statistics
# program (stats.c), but modified to use alpha instead of gamma.
#

package Fsdb::Support::TDistribution;


=head1 NAME

Fsdb::Support::TDistribution - t-distributions for stats

=head1 SYNOPSIS

    use Fsdb::Support::TDistribution;

    $stats = new DbStats(options);

=cut
#'


use Exporter 'import';
@EXPORT = qw();
@EXPORT_OK = qw(t_distribution);
($VERSION) = 1.0;

use Carp qw(croak);
#'

# interval vars
my(@t_nus, %t_values, @t_alphas);
my($inited) = undef;


=head2 init_t_distr

internal intialization

=cut
sub init_t_distr {
    my($t_values) = "
alphas: 0.4, 0.3, 0.2, 0.1, 0.06666666666667, 0.05, 0.04, 0.03333333333333, 0.025, 0.02, 0.01666666666667, 0.0125, 0.01, 0.00833333333333, 0.00625, 0.005
1: 0.325, 0.727, 1.376, 3.078, 4.702, 6.314, 7.916, 9.524, 12.706, 15.895, 19.043, 25.452, 31.821, 38.342, 51.334, 63.657
2: 0.289, 0.617, 1.061, 1.886, 2.456, 2.920, 3.320, 3.679, 4.303, 4.849, 5.334, 6.205, 6.965, 7.665, 8.897, 9.925
3: 0.277, 0.584, 0.978, 1.638, 2.045, 2.353, 2.605, 2.823, 3.182, 3.482, 3.738, 4.177, 4.541, 4.864, 5.408, 5.841
4: 0.271, 0.569, 0.941, 1.533, 1.879, 2.132, 2.333, 2.502, 2.776, 2.999, 3.184, 3.495, 3.747, 3.966, 4.325, 4.604
5: 0.267, 0.559, 0.920, 1.476, 1.790, 2.015, 2.191, 2.337, 2.571, 2.757, 2.910, 3.163, 3.365, 3.538, 3.818, 4.032
6: 0.265, 0.553, 0.906, 1.440, 1.735, 1.943, 2.104, 2.237, 2.447, 2.612, 2.748, 2.969, 3.143, 3.291, 3.528, 3.707
7: 0.263, 0.549, 0.896, 1.415, 1.698, 1.895, 2.046, 2.170, 2.365, 2.517, 2.640, 2.841, 2.998, 3.130, 3.341, 3.499
8: 0.262, 0.546, 0.889, 1.397, 1.670, 1.860, 2.004, 2.122, 2.306, 2.449, 2.565, 2.752, 2.896, 3.018, 3.211, 3.355
9: 0.261, 0.543, 0.883, 1.383, 1.650, 1.833, 1.973, 2.086, 2.262, 2.398, 2.508, 2.685, 2.821, 2.936, 3.116, 3.250
10: 0.260, 0.542, 0.879, 1.372, 1.634, 1.812, 1.948, 2.058, 2.228, 2.359, 2.465, 2.634, 2.764, 2.872, 3.043, 3.169
11: 0.260, 0.540, 0.876, 1.363, 1.621, 1.796, 1.928, 2.036, 2.201, 2.328, 2.430, 2.593, 2.718, 2.822, 2.985, 3.106
12: 0.259, 0.539, 0.873, 1.356, 1.610, 1.782, 1.912, 2.017, 2.179, 2.303, 2.402, 2.560, 2.681, 2.782, 2.939, 3.055
13: 0.259, 0.538, 0.870, 1.350, 1.601, 1.771, 1.899, 2.002, 2.160, 2.282, 2.379, 2.533, 2.650, 2.748, 2.900, 3.012
14: 0.258, 0.537, 0.868, 1.345, 1.593, 1.761, 1.887, 1.989, 2.145, 2.264, 2.359, 2.510, 2.624, 2.720, 2.868, 2.977
15: 0.258, 0.536, 0.866, 1.341, 1.587, 1.753, 1.878, 1.978, 2.131, 2.249, 2.342, 2.490, 2.602, 2.696, 2.841, 2.947
16: 0.258, 0.535, 0.865, 1.337, 1.581, 1.746, 1.869, 1.968, 2.120, 2.235, 2.327, 2.473, 2.583, 2.675, 2.817, 2.921
17: 0.257, 0.534, 0.863, 1.333, 1.576, 1.740, 1.862, 1.960, 2.110, 2.224, 2.315, 2.458, 2.567, 2.657, 2.796, 2.898
18: 0.257, 0.534, 0.862, 1.330, 1.572, 1.734, 1.855, 1.953, 2.101, 2.214, 2.303, 2.445, 2.552, 2.641, 2.778, 2.878
19: 0.257, 0.533, 0.861, 1.328, 1.568, 1.729, 1.850, 1.946, 2.093, 2.205, 2.293, 2.433, 2.539, 2.627, 2.762, 2.961
20: 0.257, 0.533, 0.860, 1.325, 1.564, 1.725, 1.844, 1.940, 2.086, 2.197, 2.285, 2.423, 2.528, 2.614, 2.748, 2.845
21: 0.257, 0.592, 0.859, 1.323, 1.561, 1.721, 1.840, 1.935, 2.080, 2.189, 2.277, 2.414, 2.518, 2.603, 2.735, 2.831
22: 0.256, 0.532, 0.858, 1.321, 1.558, 1.717, 1.835, 1.930, 2.074, 2.183, 2.269, 2.405, 2.508, 2.593, 2.724, 2.819
23: 0.256, 0.532, 0.858, 1.319, 1.556, 1.714, 1.832, 1.926, 2.069, 2.177, 2.263, 2.398, 2.500, 2.584, 2.713, 2.807
24: 0.256, 0.531, 0.857, 1.318, 1.553, 1.711, 1.828, 1.922, 2.064, 2.172, 2.257, 2.391, 2.492, 2.575, 2.704, 2.797, 
25: 0.256, 0.531, 0.856, 1.316, 1.551, 1.708, 1.825, 1.918, 2.060, 2.167, 2.251, 2.385, 2.485, 2.568, 2.695, 2.787
26: 0.256, 0.531, 0.856, 1.315, 1.549, 1.706, 1.822, 1.915, 2.056, 2.162, 2.246, 2.379, 2.479, 2.561, 2.687, 2.779
27: 0.256, 0.531, 0.855, 1.314, 1.547, 1.703, 1.819, 1.912, 2.052, 2.158, 2.242, 2.373, 2.473, 2.554, 2.680, 2.771
28: 0.256, 0.530, 0.855, 1.313, 1.546, 1.701, 1.817, 1.909, 2.048, 2.154, 2.237, 2.368, 2.467, 2.548, 2.673, 2.763
29: 0.256, 0.530, 0.854, 1.311, 1.544, 1.699, 1.814, 1.906, 2.045, 2.150, 2.233, 2.364, 2.462, 2.543, 2.667, 2.756
30: 0.256, 0.530, 0.854, 1.310, 1.543, 1.697, 1.812, 1.904, 2.042, 2.147, 2.230, 2.360, 2.457, 2.537, 2.661, 2.750
40: 0.255, 0.529, 0.851, 1.303, 1.532, 1.684, 1.796, 1.886, 2.021, 2.123, 2.203, 2.329, 2.423, 2.501, 2.619, 2.704
50: 0.255, 0.528, 0.849, 1.299, 1.526, 1.676, 1.787, 1.875, 2.009, 2.109, 2.188, 2.311, 2.403, 2.479, 2.594, 2.678
75: 0.254, 0.527, 0.846, 1.293, 1.517, 1.665, 1.775, 1.861, 1.992, 2.090, 2.167, 2.287, 2.377, 2.450, 2.562, 2.643
100: 0.254, 0.526, 0.845, 1.290, 1.513, 1.660, 1.769, 1.855, 1.984, 2.081, 2.157, 2.276, 2.364, 2.436, 2.547, 2.626
10000: 0.253, 0.524, 0.842, 1.282, 1.501, 1.645, 1.751, 1.834, 1.960, 2.054, 2.127, 2.241, 2.326, 2.395, 2.501, 2.57
";
    # In a previous version, and in Geoff's code, the last line
    # was listed as MAXINT (Geoff) or 2^31-1 (my code).
    # My code broke on 64-bit comptuers (welcome to 2001!)
    # when n exceeded 2^31.  Yuri Pradkin proceeded to exercise
    # this bug.
    # Geoff's code wouldn't have broken,
    # BUT IMHO linear interpolation between such widely disparate numbers
    # doesn't make sense.  I therefore define 10000 (arbitarily)    
    # as infinity, and added code below to handle values greater than that.
    # This approach is all very hackish; I need to consult a Real
    # Statistician. ---johnh 2011-03-10
    my($nui) = -1;
    foreach (split(/\n/, $t_values)) {
	next if (/^\s*$/);
	my(@values) = split(/[ \t\n:,]+/, $_);
	$values[0] = 0 if ($values[0] eq 'alphas');
	my($nu) = $values[0] + 0; shift @values;
	if ($nui >= 0) {
	    push (@t_nus, $nu);
	    croak("Bad number of values in table.\n") if ($#values != $#t_alphas);
	};
	foreach $i (0..$#values) {
	    croak("Zero t_value for nu=$nu, alpha=$alpha.\n") if ($values[$i] == 0);
	    if ($nui >= 0) {
	        $t_values{$nu,$t_alphas[$i]} = $values[$i] + 0.0;
	    } else {
		$t_alphas[$i] = $values[$i];
	    };
	};
	$nui++;
    };
    $inited = 1;
}


=head2 interpolate

Linear interpolation, given
desired x, x bounding (low and high) x and y values.

=cut
sub interpolate {
    my($x, $x_low, $x_high, $y_low, $y_high) = @_;
    return $y_low + (($x - $x_low) / ($x_high - $x_low)) * ($y_high - $y_low);
}

=head2 floats_equal

compare to floating point numbers with a bit of fuzz

=cut
sub floats_equal {
    my($a, $b) = @_;
    my $delta = $a-$b;  $delta = -$delta if ($delta < 0.0);
    return $delta < 0.000001;
}


=head2 t_distribution($nu, $alpha)

Return the value interpolated from a t-distribution.

=cut
# Geoff's version was in terms of gamma (1-alpha), but that was confusing.
# '
sub t_distribution {
    my($nu, $alpha) = @_;   # degrees of freedom, confidence half-interval
    croak("Bad (negative) nu: $nu.\n") if ($nu <= 0);

    &init_t_distr() if (!$inited);

    # search in the alpha dimension    
    croak("Alpha value too high, off of left of table.")
	if ($alpha > $t_alphas[0]);
    my($alphai);
    for ($alphai = 0; $alphai <= $#t_alphas; $alphai++) {
        last if ($t_alphas[$alphai] <= $alpha);
    };
    croak("Alpha value too low, off of right of table.")
        if ($alphai > $#t_alphas);
    my($alpha_left) = $t_alphas[$alphai-1];
    my($alpha_right) = $t_alphas[$alphai];

    # search in the nu dimension    
    my($nui);
    for ($nui = 0; $nui <= $#t_nus; $nui++) {
	last if ($t_nus[$nui] >= $nu);
    };	
    my($nu_less, $nu_more);
    if ($nui > $#t_nus) {
	# at infinity?
	$nu_less = $nu_more = $#t_nus;
    } elsif ($t_nus[$nui] == $nu) {
	$nu_less = $nu_more = $nui;
    } else{
        $nu_less = $t_nus[$nui-1];
	$nu_more = $t_nus[$nui];
    };
    
    # now do interopation, if necssary
    if (floats_equal($t_alphas[$alphai], $alpha)) {
	if ($nu_less == $nu_more) {
	    # print "exact match\n";
	    return $t_values{$t_nus[$nu_more],$alpha};
	} else {
	    # print "interpolate nu: $nu ($nu_less,$nu_more)\n";
	    return &interpolate($nu, $nu_less, $nu_more, 
			$t_values{$nu_less,$alpha}, $t_values{$nu_more,$alpha});
	};
    } elsif ($t_nus[$nui] == $nu) {
	# print "interpolate alpha: $alpha ($alpha_left,$alpha_right)\n";
        return &interpolate($alpha, $alpha_left, $alpha_right,
			$t_values{$nu,$alpha_left}, $t_values{$nu,$alpha_right});
    } else {
        croak("Neither nu nor alpha match, case not implemented.");
		# Geoff's code:
		# value_low = interpolate (alpha,
		#   alphas[alpha_index - 1],
		#   alphas[alpha_index],
		#   t_values[nu_index - 1].values[alpha_index - 1],
		#   t_values[nu_index - 1].values[alpha_index]);
		# value_high = interpolate (alpha,
		#   alphas[alpha_index - 1],
		#   alphas[alpha_index],
		#   t_values[nu_index].values[alpha_index - 1],
		#   t_values[nu_index].values[alpha_index]);
		# return interpolate ((double) nu,
		#   (double) t_values[nu_index - 1].nu,
		#   (double) t_values[nu_index].nu,
		#   value_low,
		#   value_high);
    };
}

1;
