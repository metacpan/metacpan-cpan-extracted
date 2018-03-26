package ICC::Support::nPINT;

use strict;
use Carp;

our $VERSION = 0.71;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# support modules
use File::Glob;
use POSIX ();

=encoding utf-8

n-channel polynomial interpolation engine (nPINT), inspired by Francois Lekien, Chad Coulliette and Jerry
Marsden, authors of "Tricubic interpolation in three dimensions" and "Tricubic Engine Technical Notes and
Full Matrix".

create new nPINT object parameter hash structure:

 {'pda' => [polynomial_degree_array], 'coef' => [nPINT_coefficients]}

the polynomial_degree_array contains the polynomial degree for each input channel, e.g. [3, 3, 3, 3] => 4
channels, each of degree 3

the nPINT coefficients define the behavior of the model. they are normally obtained using the 'fit'
method, which uses linear least squares to fit the model to the supplied data. the number of rows in the
coefficient array is equal to the product of each channel's degree + 1, e.g. if the pda is [3, 3, 3, 3],
there are 256 coefficient rows. the number columns in the coefficient array is equal to the number of
output channels.

=cut

# optional usage forms:
# parameters: ()
# parameters: (ref_to_parameter_hash)
# parameters: (path_to_storable_file)
# returns: (object_reference)
sub new {

	# get object class
	my $class = shift();

	# create empty nPINT object
	my $self = [
		{},     # object header
		[],     # input polynomial degree array
		[],     # output coefficient array
		undef   # cached output coefficient array
	];

	# if one parameter, a hash reference
	if (@_ == 1 && ref($_[0]) eq 'HASH') {
		
		# create new object from parameter hash
		_new_from_hash($self, @_);
		
	# if any parameters
	} elsif (@_) {
		
		# create new object from Storable file
		_new_from_storable($self, @_) || carp("couldn't read Storable file: $_[0]");
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# fit nPINT object to data
# uses LAPACK dgels function to perform a least-squares fit
# parameters: (ref_to_pda_array, ref_to_input_array, ref_to_output_array)
# returns: (dgels_info_value)
sub fit {

	# get parameters
	my ($self, $pda, $in, $out) = @_;

	# local variables
	my ($info, $cols, $coef);

	# get number of coefficients
	$cols = ICC::Support::Lapack::xcols($pda);
	
	# verify input is an array or Math::Matrix object
	(ref($in) eq 'ARRAY' || UNIVERSAL::isa($in, 'Math::Matrix')) || croak('improper input array type');

	# verify input structure
	(ref($in->[0]) eq 'ARRAY' && ! ref($in->[0][0])) || croak('improper input array structure');

	# verify output is an array or Math::Matrix object
	(ref($out) eq 'ARRAY' || UNIVERSAL::isa($out, 'Math::Matrix')) || croak('improper output array type');

	# verify output structure
	(ref($out->[0]) eq 'ARRAY' && ! ref($out->[0][0])) || croak('improper output array structure');

	# verify array dimensions
	($#{$in} == $#{$out}) || croak('fit input and output arrays have different number of rows');

	# fit nPINT model
	($info, $coef) = ICC::Support::Lapack::nPINT_fit($pda, $in, $out);

	# check result
	carp('fit failed - bad parameter when calling dgels') if ($info < 0);
	carp('fit failed - A matrix not full rank') if ($info > 0);

	# copy pda to object
	$self->[1] = [@{$pda}];

	# copy coefficients to object
	$self->[2] = [@{$coef}[0 .. $cols - 1]];

	# update cache
	$self->[3] = ICC::Support::Lapack::cache_2D($self->[2]);

	# return info value
	return($info);

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
			croak('parameter must be a hash reference');
			
		}
		
	}

	# return reference
	return($self->[0]);

}

# get/set reference to pda array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub pda {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, an array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
			
			# set CLUT to new array
			$self->[1] = [@{shift()}];
			
		} else {
			
			# error
			croak('parameter must be an array reference');
			
		}
		
	}

	# return reference
	return($self->[1]);

}

# get/set reference to coefficient array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub array {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, an array or a Math::Matrix object
		if (@_ == 1 && (ref($_[0]) eq 'ARRAY' || UNIVERSAL::isa($_[0], 'Math::Matrix'))) {
			
			# verify array structure
			(ref($_[0][0]) eq 'ARRAY' && ! ref($_[0][0][0])) || croak('improper coefficient array structure');
			
			# set CLUT to new array
			$self->[2] = bless(Storable::dclone(shift()), 'Math::Matrix');
			
			# update cache
			$self->[3] = ICC::Support::Lapack::cache_2D($self->[2]);
			
		} else {
			
			# error
			croak('improper coefficient array type');
			
		}
		
	}

	# return reference
	return($self->[2]);

}

# transform data
# nominal input range is (0 - 1)
# hash key 'ubox' enables unit box extrapolation
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

# inverse transform
# note: number of undefined output values must equal number of defined input values
# note: the input and output vectors contain the final solution on return
# hash key 'init' specifies initial value vector
# hash key 'ubox' enables unit box extrapolation
# parameters: (input_vector, output_vector, [hash])
# returns: (RMS_error_value)
sub inverse {

	# get parameters
	my ($self, $in, $out, $hash) = @_;

	# local variables
	my ($i, $j, @si, @so, $init);
	my ($int, $jac, $mat, $delta);
	my ($max, $elim, $dlim, $accum, $error);

	# initialize indices
	$i = $j = -1;

	# build slice arrays while validating input and output arrays
	((grep {$i++; defined() && push(@si, $i)} @{$in}) == (grep {$j++; ! defined() && push(@so, $j)} @{$out})) || croak('wrong number of undefined values');

	# get init array
	$init = $hash->{'init'};

	# for each undefined output value
	for my $i (@so) {
		
		# set to supplied initial value or 0.5
		$out->[$i] = defined($init->[$i]) ? $init->[$i] : 0.5;
		
	}

	# set maximum loop count
	$max = $hash->{'inv_max'} || 10;

	# loop error limit
	$elim = $hash->{'inv_elim'} || 1E-6;

	# set delta limit
	$dlim = $hash->{'inv_dlim'} || 0.5;

	# create empty solution matrix
	$mat = Math::Matrix->new([]);

	# compute initial transform values
	($jac, $int) = jacobian($self, $out, $hash);

	# solution loop
	for (1 .. $max) {
		
		# for each input
		for my $i (0 .. $#si) {
			
			# for each output
			for my $j (0 .. $#so) {
				
				# copy Jacobian value to solution matrix
				$mat->[$i][$j] = $jac->[$si[$i]][$so[$j]];
				
			}
			
			# save residual value to solution matrix
			$mat->[$i][$#si + 1] = $in->[$si[$i]] - $int->[$si[$i]];
			
		}
		
		# solve for delta values
		$delta = $mat->solve;
		
		# for each output value
		for my $i (0 .. $#so) {
			
			# add delta (limited using hyperbolic tangent)
			$out->[$so[$i]] += POSIX::tanh($delta->[$i][0]/$dlim) * $dlim;
			
		}
		
		# compute updated transform values
		($jac, $int) = jacobian($self, $out, $hash);
		
		# initialize error accumulator
		$accum = 0;
		
		# for each input
		for my $i (0 .. $#si) {
			
			# accumulate delta squared
			$accum += ($in->[$si[$i]] - $int->[$si[$i]])**2;
			
		}
		
		# compute RMS error
		$error = sqrt($accum/@si);
		
		# if error less than limit
		last if ($error < $elim);
		
	}

	# update input vector with final values
	@{$in} = @{$int};

	# return
	return($error);

}

# compute Jacobian matrix
# nominal input range is (0 - 1)
# hash key 'ubox' enables unit box extrapolation
# parameters: (input_vector, [hash])
# returns: (Jacobian_matrix, [output_vector])
sub jacobian {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($xflag, $ext, $ubox, $jac, $delta, $out);

	# verify input vector
	(ref($in) eq 'ARRAY' && @{$in} == @{$self->[1]} && @{$in} == grep {! ref()} @{$in}) || croak('invalid jacobian input');

	# if extrapolation required (any input outside the unit box)
	if ($xflag = $hash->{'ubox'} && grep {$_ < 0 || $_ > 1} @{$in}) {
		
		# get unit box intersection values
		($ext, $ubox) = _intersect($in);
		
		# get Jacobian (at unit box surface)
		$jac = ICC::Support::Lapack::nPINT_jacobian($self->[1], $ubox, $self->[3]);
		
	} else {
		
		# get Jacobian (at input values)
		$jac = ICC::Support::Lapack::nPINT_jacobian($self->[1], $in, $self->[3]);
	}

	# bless to Math::Matrix object
	bless($jac, 'Math::Matrix');

	# if output values wanted
	if (wantarray) {
		
		# if extrapolation required
		if ($xflag) {
			
			# compute ouptut values (at unit box surface)
			$out = ICC::Support::Lapack::nPINT_vec_trans($self->[1], $ubox, $self->[3]);
			
			# for each output
			for my $i (0 .. $#{$out}) {
				
				# add delta value
				$out->[$i] += ICC::Shared::dotProduct($jac->[$i], $ext);
				
			}
			
		} else {
			
			# compute ouptut values (at input values)
			$out = ICC::Support::Lapack::nPINT_vec_trans($self->[1], $in, $self->[3]);
			
		}
		
		# return Jacobian and output values
		return($jac, $out);
		
	} else {
		
		# return Jacobian only
		return($jac);
		
	}
	
}

# print object contents to string
# format is an array structure
# parameter: ([format])
# returns: (string)
sub sdump {

	# get parameters
	my ($self, $p) = @_;

	# local variables
	my ($s, $fmt);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 'undef';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# return
	return($s);

}

# transform list
# parameters: (object_reference, list, [hash])
# returns: (list)
sub _trans0 {

	# local variables
	my ($self, $hash);

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# call _trans1
	return(@{_trans1($self, \@_, $hash)});

}

# transform vector
# parameters: (object_reference, vector, [hash])
# returns: (vector)
sub _trans1 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($ext, $ubox, $out, $jac);

	# if unit box extrapolation
	if ($hash->{'ubox'} && grep {$_ < 0.0 || $_ > 1.0} @{$in}) {
		
		# get unit box intersection values
		($ext, $ubox) = _intersect($in);
		
		# get transformed values (at unit box surface)
		$out = ICC::Support::Lapack::nPINT_vec_trans($self->[1], $ubox, $self->[3]);
		
		# get Jacobian (at unit box surface)
		$jac = ICC::Support::Lapack::nPINT_jacobian($self->[1], $ubox, $self->[3]);
		
		# for each output
		for my $i (0 .. $#{$out}) {
			
			# add delta value
			$out->[$i] += ICC::Shared::dotProduct($jac->[$i], $ext);
			
		}
		
		# return extrapolated value
		return($out);
		
	} else {
		
		# call BLAS-based vector transform function
		return(ICC::Support::Lapack::nPINT_vec_trans($self->[1], $in, $self->[3]));
		
	}

}

# transform matrix (2-D array -or- Math::Matrix object)
# parameters: (object_reference, matrix, [hash])
# returns: (matrix)
sub _trans2 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variable
	my ($out);

	# if unit box extrapolation
	if ($hash->{'ubox'}) {
		
		# for each matrix row
		for my $i (0 .. $#{$in}) {
			
			# compute output vector
			$out->[$i] = _trans1($self, $in->[$i], $hash);
			
		}
		
	} else {
		
		# call BLAS-based vector transform function
		$out = ICC::Support::Lapack::nPINT_mat_trans($self->[1], $in, $self->[3]);
		
	}

	# return matrix, same form as input
	return(UNIVERSAL::isa($in, 'Math::Matrix') ? bless($out, 'Math::Matrix') : $out);

}

# transform structure
# parameters: (object_reference, structure, [hash])
# returns: (structure)
sub _trans3 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# transform the array structure
	_crawl($self, $in, my $out = []);

	# return output array reference
	return($out);

}

# recursive transform
# array structure is traversed until scalar arrays are found and transformed
# parameters: (object_reference, input_array_reference, output_array_reference, hash)
sub _crawl {

	# get parameters
	my ($self, $in, $out, $hash) = @_;

	# if input is a vector (reference to a scalar array)
	if (@{$in} == grep {! ref()} @{$in}) {
		
		# transform input vector and copy to output
		@{$out} = @{_trans1($self, $in, $hash)};
		
	} else {
		
		# for each input element
		for my $i (0 .. $#{$in}) {
			
			# if an array reference
			if (ref($in->[$i]) eq 'ARRAY') {
				
				# transform next level
				_crawl($self, $in->[$i], $out->[$i] = [], $hash);
				
			} else {
				
				# error
				croak('invalid transform input');
				
			}
			
		}
		
	}
	
}

# find unit box intersection
# with line from input to box-center
# parameters: (input_vector)
# returns: (extrapolation_vector, unit_box_intersection)
sub _intersect {

	# get input vector
	my $in = shift();

	# local variables
	my (@cin, $dmax, $ubox);

	# compute input to center difference
	@cin = map {$_ - 0.5} @{$in};

	# initialize
	$dmax = 0;

	# for each difference
	for (@cin) {
		
		# if larger absolute value
		if (abs($_) > $dmax) {
			
			# new max difference
			$dmax = abs($_);
			
		}
		
	}

	# multiply max difference by 2
	$dmax *= 2;

	# compute output values (on surface of unit box)
	$ubox = [map {$_/$dmax + 0.5} @cin];

	# return extrapolation vector ($in - $ubox) and unit-box intersection vector
	return([map {$in->[$_] - $ubox->[$_]} (0 .. $#{$in})], $ubox);

}

# make nPINT object from parameter hash
# parameters: (object_reference, ref_to_parameter_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($pda, $coef, $size);

	# get input polynomial degree array (pda) reference
	$pda = $hash->{'pda'} || croak('missing polynomial degree array');

	# get output coefficient array reference
	$coef = $hash->{'coef'} || croak('missing coefficient array');

	# verify pda structure
	(ref($pda) eq 'ARRAY' && ! ref($pda->[0])) || croak('improper polynomial degree array');

	# copy pda to object
	$self->[1] = [@{$pda}];

	# initialize coefficient array size
	$size = 1;

	# for each pda element
	for my $d (@{$pda}) {
		
		# multiply by (degree + 1)
		$size *= ($d + 1);
		
	}

	# verify coef is array or Math::Matrix object
	(ref($coef) eq 'ARRAY' || UNIVERSAL::isa($coef, 'Math::Matrix')) || croak('improper coefficient array type');

	# verify coef structure
	(ref($coef->[0]) eq 'ARRAY' && ! ref($coef->[0][0]) && @{$coef} == $size) || croak('improper coefficient array structure');

	# copy coefficient array to object
	$self->[2] = bless(Storable::dclone($coef), 'Math::Matrix');

	# update cache
	$self->[3] = ICC::Support::Lapack::cache_2D($self->[2]);

}

# make nPINT object from Storable file
# parameters: (object_reference, path_to_storable_file)
sub _new_from_storable {

	# get parameters
	my ($self, $path) = @_;

	# local variables
	my ($hash, @files);

	# resolve file list from path
	(@files = File::Glob::bsd_glob($path)) || croak('invalid file path');

	# verify file path is unique
	(@files == 1) || carp('file path not unique');

	# retrieve hash reference
	$hash = Storable::retrieve($files[0]);

	# if successful
	if (defined($hash)) {
		
		# create nPINT object from hash reference
		_new_from_hash($self, $hash);
		
		# return success flag
		return(1);
		
	} else {
		
		# return failure flag
		return(0);
		
	}
	
}

1;
