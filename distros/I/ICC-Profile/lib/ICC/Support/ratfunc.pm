package ICC::Support::ratfunc;

use strict;
use Carp;

our $VERSION = 0.10;

# revised 2016-10-26
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# enable static variables
use feature 'state';

=encoding utf-8

This module implements a simple rational function ('ratfunc') transform for 3-channel data.

The transform is explained in the document 'rational_function_color_transform.txt'.

The primary application is converting RGB camera/scanner data to XYZ.

We often use a 3x4 matrix to do this,

	| a11, a12, a13, a14 |
	| a21, a22, a23, a24 |
	| a31, a32, a33, a34 |

To use this matrix, we add a column containing '1' to the input data,

	[R, G, B] => [R, G, B, 1]

Then we use matrix multiplication to compute the XYZ values from these augmented RGB values.

	[X, Y, Z] = [3x4 matrix] x [R, G, B, 1]

If the camera or scanner has RGB spectral sensitivities derived from color matching functions (Luther-Ives condition), the accuracy
of this simple transform will be excellent. However, the spectral sensitivity curves are not always optimal.

We may be able to achieve slightly better results using rational functions. A rational function is the ratio of two polynomial
functions. We use extremely simple, linear functions of RGB. We extend the 3x4 matrix by adding three rows to get a 6x4 matrix,

	| a11, a12, a13, a14 |
	| a21, a22, a23, a24 |
	| a31, a32, a33, a34 |
	| a41, a42, a43,  1  |
	| a51, a52, a53,  1  |
	| a61, a62, a63,  1  |

Now, when we multiply by the augmented RGB matrix, we get,

	[Xn, Yn, Zn, Xd, Yd, Zd] = [6x4 matrix] x [R, G, B, 1]

Then we reduce these values to ratios,

	[X, Y, Z] = [Xn/Xd, Yn/Yd, Zn/Zd]

If the added coefficients, a41, a42, ... a63, are all zero, the denominators will all be 1, and the transform is the same as the 3x3
matrix with offsets. If these coefficients are non-zero, the X, Y, Z functions will be non-linear, which may improve the accuracy of
the transform.

The advantage of this transform is that it provides some additional degrees of freedom compared to the 3x3 matrix. This allows us to
'fix' some points to improve the reproduction of a particular original. The transform may have some curvature, but it is smooth and
gradual, so congruence is maintained. This transform cannot improve the color quality of the sensor, but it can be used to fine tune
images.

The object's matrix is compatible with the XS function 'ICC::Support::Image::ratfunc_transform_float'. The intention is to optimize
the matrix using the 'ratfunc.pm' object, then transform images using the XS function.

The size of the object's matrix is always 6x4. If we attempt to make a larger matrix, an error occurs. If we supply a smaller matrix,
the missing coefficients are those of the identity matrix. The identity matrix looks like this,

	| 1, 0, 0, 0 |
	| 0, 1, 0, 0 |
	| 0, 0, 1, 0 |
	| 0, 0, 0, 1 |
	| 0, 0, 0, 1 |
	| 0, 0, 0, 1 |

For example, a 3x3 matrix will be copied to the first three rows and columns of the above identity matrix. In that case, the 'ratfunc'
transform will be the same as the 'matf' transform (straight matrix multiplication).

=cut

# create new ratfunc object
# returns an empty object with no parameters
# hash keys are: ('header', 'matrix', 'offset')
# 'header' value is a hash reference
# 'matrix' value is a 2D array reference -or- Math::Matrix object
# returns identity object with an empty hash ({})
# when the parameters are input and output arrays, the 'fit' method is called on the object
# parameter: ()
# parameter: ({})
# parameter: (ref_to_attribute_hash)
# parameter: (matf_object)
# parameters: (ref_to_input_array, ref_to_output_array)
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty ratfunc object
	my $self = [
		{},    # header
		[],    # matrix
	];

	# local parameter
	my ($info);

	# if there are parameters
	if (@_) {
		
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
			
			# make new ratfunc object from attribute hash
			_new_from_hash($self, shift());
			
		# if one parameter, a 'matf' object
		} elsif (@_ == 1 && UNIVERSAL::isa(ref($_[0]), 'ICC::Profile::matf')) {
			
			# make new ratfunc object from 'matf' object
			_new_from_matf($self, shift());
			
		# if two or three parameters
		} elsif (@_ == 2 || @_ == 3) {
			
			# fit the object to data
			($info = fit($self, @_)) && croak("\'fit\' routine failed with error $info");
			
		} else {
			
			# error
			croak('\'ratfunc\' invalid parameter(s)');
			
		}
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# get/set reference to header hash
# parameters: ([ref_to_new_hash])
# returns: (ref_to_hash)
sub header {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
			
			# set header to new hash
			$self->[0] = {%{shift()}};
			
		} else {
			
			# error
			croak('\'header\' attribute must be a hash reference');
			
		}
		
	}

	# return reference
	return($self->[0]);

}

# get/set reference to matrix array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub matrix {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a reference to a 2-D array -or- Math::Matrix object
		if (@_ == 1 && ((ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {ref() eq 'ARRAY'} @{$_[0]}) || UNIVERSAL::isa($_[0], 'Math::Matrix'))) {
			
			# verify number of rows
			($#{$_[0]} < 6) || croak('\'matrix\' array has more than 6 rows');
			
			# make identity matrix (6x4)
			$self->[1] = bless([
				[1, 0, 0, 0],
				[0, 1, 0, 0],
				[0, 0, 1, 0],
				[0, 0, 0, 1],
				[0, 0, 0, 1],
				[0, 0, 0, 1],
			], 'Math::Matrix');
			
			# for each row
			for my $i (0 .. $#{$_[0]}) {
				
				# verify number of columns
				($#{$_[0]->[$i]} < 4) || croak('\'matrix\' array has more than 4 columns');
				
				# for each column
				for my $j (0 .. $#{$_[0]->[$i]}) {
					
					# verify matrix element is a number
					(Scalar::Util::looks_like_number($_[0]->[$i][$j])) || croak('\'matrix\' element not numeric');
					
					# copy matrix element
					$self->[1][$i][$j] = $_[0]->[$i][$j];
					
				}
				
			}
			
		} else {
			
			# error
			croak('\'matrix\' attribute must be a 2-D array reference or Math::Matrix object');
			
		}
		
	}

	# return object reference
	return($self->[1]);

}

# fit ratfunc object to data
# uses LAPACK dgels function to perform a least-squares fit
# fitting is done with or without offset, according to offset_flag
# input and output are 2D array references -or- Math::Matrix objects
# parameters: (ref_to_input_array, ref_to_output_array, [offset_flag])
# returns: (dgels_info_value)
sub fit {

	# get parameters
	my ($self, $in, $out, $oflag) = @_;

	# local variables
	my ($info, $ab);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# verify ICC::Support::Lapack module is loaded
	($lapack) || croak('\'fit\' method requires ICC::Support::Lapack module');

	# resolve offset flag
	$oflag = 0 if (! defined($oflag));

	# verify input array
	(ref($in) eq 'ARRAY' && ref($in->[0]) eq 'ARRAY' && ! ref($in->[0][0])) || UNIVERSAL::isa($in, 'Math::Matrix') || croak('fit input not a 2-D array reference');

	# verify output array
	(ref($out) eq 'ARRAY' && ref($out->[0]) eq 'ARRAY' && ! ref($out->[0][0])) || UNIVERSAL::isa($out, 'Math::Matrix') || croak('fit output not a 2-D array reference');

	# verify array dimensions
	($#{$in} == $#{$out}) || croak('input and output arrays have different number of rows');
	($#{$in->[0]} == 2) || croak('input samples must have 3 elements');
	($#{$out->[0]} == 2) || croak('output samples must have 3 elements');

	# fit the matrix
	($info, $ab) = ICC::Support::Lapack::matf_fit($in, $out, $oflag);

	# check result
	carp('fit failed - bad parameter when calling dgels') if ($info < 0);
	carp('fit failed - A matrix not full rank') if ($info > 0);

	# initialize matrix object
	$self->[1] = bless([], 'Math::Matrix');

	# for each row
	for my $i (0 .. 2) {
		
		# for each column
		for my $j (0 .. 2) {
			
			# set matrix element (transposing)
			$self->[1][$i][$j] = $ab->[$j][$i];
			
		}
		
		# set offset value
		$self->[1][$i][3] = $oflag ? $ab->[3][$i] : 0;
		
		# set divisor row
		$self->[1][$i + 3] = [0, 0, 0, 1];
		
	}

	# return info value
	return($info);

}

# transform data
# supported input types:
# parameters: (list, [hash])
# parameters: (vector, [hash])
# parameters: (matrix, [hash])
# parameters: (Math::Matrix_object, [hash])
# parameters: (structure, [hash])
# returns: (same_type_as_input)
sub transform {

	# set hash value (0 or 1)
	my $h = ref($_[-1]) eq 'HASH' ? 1 : 0;

	# if input a 'Math::Matrix' object
	if (@_ == $h + 2 && UNIVERSAL::isa($_[1], 'Math::Matrix')) {
		
		# call matrix transform
		&_trans2;
		
	# if input an array reference
	} elsif (@_ == $h + 2 && ref($_[1]) eq 'ARRAY') {
		
		# if array contains numbers (vector)
		if (! ref($_[1][0]) && @{$_[1]} == grep {Scalar::Util::looks_like_number($_)} @{$_[1]}) {
			
			# call vector transform
			&_trans1;
			
		# if array contains vectors (2-D array)
		} elsif (ref($_[1][0]) eq 'ARRAY' && @{$_[1]} == grep {ref($_) eq 'ARRAY' && Scalar::Util::looks_like_number($_->[0])} @{$_[1]}) {
			
			# call matrix transform
			&_trans2;
			
		} else {
			
			# call structure transform
			&_trans3;
			
		}
		
	# if input a list (of numbers)
	} elsif (@_ == $h + 1 + grep {Scalar::Util::looks_like_number($_)} @_) {
		
		# call list transform
		&_trans0;
		
	} else {
		
		# error
		croak('invalid transform input');
		
	}
	
}

=cut

# inverse transform
# note: number of undefined output values must equal number of defined input values
# note: input array contains the final calculated input values upon return
# parameters: (ref_to_input_array, ref_to_output_array)
sub inverse {

	# get parameters
	my ($self, $in, $out) = @_;

	# local variables
	my ($i, $j, @si, @so);
	my ($int, $info, $delta, $sys, $res, $mat);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# initialize indices
	$i = $j = -1;

	# build slice arrays while validating input and output arrays
	((grep {$i++; defined() && push(@si, $i)} @{$in}) == (grep {$j++; ! defined() && push(@so, $j)} @{$out})) || croak('wrong number of undefined values');

	# for each undefined output value
	for my $i (@so) {
		
		# set to 0
		$out->[$i] = 0;
		
	}

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute initial transform values
		$int = ICC::Support::Lapack::matf_vec_trans($out, $self->[1]);
		
		# for each input
		for my $i (0 .. $#si) {
			
			# for each output
			for my $j (0 .. $#so) {
				
				# copy Jacobian value to system matrix
				$sys->[$i][$j] = $self->[1][$si[$i]][$so[$j]];
				
			}
			
			# compute residual value
			$res->[$i][0] = $in->[$si[$i]] - $int->[$si[$i]];
			
		}
		
		# solve for delta values
		($info, $delta) = ICC::Support::Lapack::solve($sys, $res);
		
		# report linear system error
		($info) && print "ratfunc inverse error $info: @{$in}\n";
		
		# for each output value
		for my $i (0 .. $#so) {
			
			# add delta value
			$out->[$so[$i]] += $delta->[$i][0];
			
		}
		
		# compute final transform values
		@{$in} = @{ICC::Support::Lapack::matf_vec_trans($out, $self->[1])};
		
	} else {
		
		# compute initial transform values
		$int = [_trans0($self, @{$out})];
		
		# for each input
		for my $i (0 .. $#si) {
			
			# for each output
			for my $j (0 .. $#so) {
				
				# copy Jacobian value to solution matrix
				$mat->[$i][$j] = $self->[1][$si[$i]][$so[$j]];
				
			}
			
			# save residual value to solution matrix
			$mat->[$i][$#si + 1] = $in->[$si[$i]] - $int->[$si[$i]];
			
		}
		
		# bless Matrix
		bless($mat, 'Math::Matrix');
		
		# solve for delta values
		$delta = $mat->solve || print "ratfunc inverse error: @{$in}\n";
		
		# for each output value
		for my $i (0 .. $#so) {
			
			# add delta value
			$out->[$so[$i]] += $delta->[$i][0];
			
		}
		
		# compute final transform values
		@{$in} = _trans0($self, @{$out});
		
	}
	
}

# compute Jacobian matrix
# note: input values only required for output values
# parameters: ([input_vector])
# returns: (ref_to_Jacobian_matrix, [output_vector])
sub jacobian {

	# get object reference
	my $self = shift();

	# if output values wanted
	if (wantarray) {
		
		# return Jacobian and output values
		return(bless(Storable::dclone($self->[1]), 'Math::Matrix'), _trans1($self, $_[0]));
		
	} else {
		
		# return Jacobian only
		return(bless(Storable::dclone($self->[1]), 'Math::Matrix'));
		
	}
	
}

=cut

# get number of input channels
# returns: (number)
sub cin {

	# get object reference
	my $self = shift();

	# return
	return(3);

}

# get number of output channels
# returns: (number)
sub cout {

	# get object reference
	my $self = shift();

	# return
	return(3);

}

# print object contents to string
# format is an array structure
# parameter: ([format])
# returns: (string)
sub sdump {

	# get parameters
	my ($self, $p) = @_;

	# local variables
	my ($fmt, $s, $rows, $fn);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 'm';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# get matrix rows
	$rows = $#{$self->[1]};

	# if empty object
	if ($rows < 0) {
		
		# append string
		$s .= "<empty object>\n";
		
	} else {
		
		# append string
		$s .= "matrix values\n";
		
		# for each row
		for my $i (0 .. $rows) {
			
			# make number format
			$fn = '  %10.5f' x @{$self->[1][$i]};
			
			# append matrix row
			$s .= sprintf("$fn\n", @{$self->[1][$i]});
			
		}
		
	}

	# return string
	return($s);

}

# recursive transform
# array structure is traversed until scalar arrays are found and transformed
# parameters: (ref_to_object, subroutine_reference, input_array_reference, output_array_reference)
sub _crawl {

	# get parameters
	my ($self, $sub, $in, $out) = @_;

	# if input is a vector (reference to a numeric array)
	if (@{$in} == grep {Scalar::Util::looks_like_number($_)} @{$in}) {
		
		# transform input vector and copy to output
		@{$out} = @{$sub->($self, $in)};
		
	} else {
		
		# for each input element
		for my $i (0 .. $#{$in}) {
			
			# if an array reference
			if (ref($in->[$i]) eq 'ARRAY') {
				
				# transform next level
				_crawl($self, $sub, $in->[$i], $out->[$i] = []);
				
			} else {
				
				# error
				croak('invalid input structure');
				
			}
			
		}
		
	}
	
}

# transform list
# parameters: (object_reference, list, [hash])
# returns: (list)
sub _trans0 {

	# local variables
	my ($self, $hash, @out, $den);

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# validate number of input channels
	(@_ == 3) || croak('input samples must have 3 channels');

	# augment input sample
	push(@_, 1);

	# for each output
	for my $i (0 .. 2) {
		
		# compute denominator
		$den = ICC::Shared::dotProduct(\@_, $self->[1][$i + 3]);
		
		# add matrix value
		$out[$i] = ($den == 0) ? 'inf' : ICC::Shared::dotProduct(\@_, $self->[1][$i])/$den;
		
	}

	# return output data
	return(@out);

}

# transform vector
# parameters: (object_reference, vector, [hash])
# returns: (vector)
sub _trans1 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# validate number of input channels
	(@{$in} == 3) || croak('input samples must have 3 channels');

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output vector using BLAS dgemv function
		return(ICC::Support::Lapack::ratfunc_vec_trans($in, $self->[1]));
		
	} else {
		
		# return
		return([_trans0($self, @{$in})]);
		
	}

}

# transform matrix (2-D array -or- Math::Matrix object)
# parameters: (object_reference, matrix, [hash])
# returns: (matrix)
sub _trans2 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($info, $out, $aug, $den);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# validate number of input channels
	(@{$in->[0]} == 3) || croak('input samples must have 3 channels');

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output matrix using BLAS dgemm function
		$out = ICC::Support::Lapack::ratfunc_mat_trans($in, $self->[1]);
		
	} else {
		
		# for each row
		for my $i (0 .. $#{$in}) {
			
			# augment input sample
			$aug = [@{$in->[$i]}, 1];
			
			# for each column
			for my $j (0 .. 2) {
				
				# compute denominator
				$den = ICC::Shared::dotProduct($aug, $self->[1][$j + 3]);
				
				# add dot product
				$out->[$i][$j] = ($den == 0) ? 'inf' : ICC::Shared::dotProduct($aug, $self->[1][$j])/$den;
				
			}
			
		}
		
	}

	# return output matrix (Math::Matrix object or 2-D array)
	return(UNIVERSAL::isa($in, 'Math::Matrix') ? bless($out, 'Math::Matrix') : $out);

}

# transform structure
# parameters: (object_reference, structure, [hash])
# returns: (structure)
sub _trans3 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# transform the array structure
	_crawl($self, \&_trans1, $in, my $out = []);

	# return output structure
	return($out);

}

# make new ratfunc object from matf object
# parameters: (ref_to_object, matf_object)
sub _new_from_matf {

	# get parameters
	my ($self, $matf) = @_;

	# local variables
	my ($value);

	# make identity matrix (6x4)
	$self->[1] = bless([
		[1, 0, 0, 0],
		[0, 1, 0, 0],
		[0, 0, 1, 0],
		[0, 0, 0, 1],
		[0, 0, 0, 1],
		[0, 0, 0, 1],
	], 'Math::Matrix');

	# get 'matf' matrix
	$value = $matf->matrix;

	# verify number of rows
	($#{$value} < 6) || croak('\'matf\' matrix has more than 6 rows');

	# for each row
	for my $i (0 .. $#{$value}) {
		
		# verify number of columns
		($#{$value->[$i]} < 3) || croak('\'matf\' matrix has more than 3 columns');
		
		# for each column
		for my $j (0 .. $#{$value->[$i]}) {
			
			# verify matrix element is a number
			(Scalar::Util::looks_like_number($value->[$i][$j])) || croak('\'matf\' matrix element not numeric');
			
			# copy matrix element
			$self->[1][$i][$j] = $value->[$i][$j];
			
		}
		
	}

	# get 'matf' offset
	$value = $matf->offset;

	# verify number of elements
	($#{$value} < 3) || croak('\'matf\' offset has more than 3 elements');

	# for each element
	for my $i (0 .. $#{$value}) {
		
		# verify array element is a number
		(Scalar::Util::looks_like_number($value->[$i])) || croak('\'matf\' offset element not numeric');
		
		# copy offset to object
		$self->[1][$i][3] = $value->[$i];
		
	}
	
}

# make new ratfunc object from attribute hash
# hash keys are: ('header', 'matrix', 'offset')
# object elements not specified in the hash are unchanged
# parameters: (ref_to_object, ref_to_attribute_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($value);

	# make identity matrix (6x4)
	$self->[1] = bless([
		[1, 0, 0, 0],
		[0, 1, 0, 0],
		[0, 0, 1, 0],
		[0, 0, 0, 1],
		[0, 0, 0, 1],
		[0, 0, 0, 1],
	], 'Math::Matrix');

	# if 'header' key defined
	if (defined($hash->{'header'})) {
		
		# if reference to hash
		if (ref($hash->{'header'}) eq 'HASH') {
			
			# set object element
			$self->[0] = {%{$hash->{'header'}}};
			
		} else {
			
			# wrong data type
			croak('wrong \'header\' data type');
			
		}
		
	}

	# if 'matrix' key defined
	if (defined($hash->{'matrix'})) {
		
		# get value
		$value = $hash->{'matrix'};
		
		# if a reference to a 2-D array -or- Math::Matrix object
		if ((ref($value) eq 'ARRAY' && @{$value} == grep {ref() eq 'ARRAY'} @{$value}) || UNIVERSAL::isa($value, 'Math::Matrix')) {
			
			# verify number of rows
			($#{$value} < 6) || croak('\'matrix\' array has more than 6 rows');
			
			# for each row
			for my $i (0 .. $#{$value}) {
				
				# verify number of columns
				($#{$value->[$i]} < 4) || croak('\'matrix\' array has more than 4 columns');
				
				# for each column
				for my $j (0 .. $#{$value->[$i]}) {
					
					# verify matrix element is a number
					(Scalar::Util::looks_like_number($value->[$i][$j])) || croak('\'matrix\' element not numeric');
					
					# copy matrix element
					$self->[1][$i][$j] = $value->[$i][$j];
					
				}
				
			}
			
		} else {
			
			# wrong data type
			croak('wrong \'matrix\' data type');
			
		}
		
	}

	# if 'offset' key defined
	if (defined($hash->{'offset'})) {
		
		# get value
		$value = $hash->{'offset'};
		
		# if a reference to an array of scalars
		if (ref($value) eq 'ARRAY' && @{$value} == grep {! ref()} @{$value}) {
			
			# verify number of elements
			($#{$value} < 3) || croak('\'offset\' array has more than 3 elements');
			
			# for each element
			for my $i (0 .. $#{$value}) {
				
				# verify array element is a number
				(Scalar::Util::looks_like_number($value->[$i])) || croak('\'offset\' element not numeric');
				
				# copy offset to object
				$self->[1][$i][3] = $value->[$i];
				
			}
			
		} else {
			
			# wrong data type
			croak('wrong \'offset\' data type');
			
		}
		
	}
	
}

1;
