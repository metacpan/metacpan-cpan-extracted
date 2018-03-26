package ICC::Support::nMIX;

use strict;
use Carp;

our $VERSION = 0.31;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# enable static variables
use feature 'state';

# create new nMIX object
# parameter may be a hash -or- an ICC::Support::Chart object
# columns is an optional column slice for the chart clut data
# hash may contain references to clut array or delta array
# hash keys are: ('array', 'delta')
# parameter: ()
# parameter: (ref_to_attribute_hash)
# parameter: (chart_object, [columns])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty nMIX object
	my $self = [
		{},    # object header
		[],    # clut
		[],    # delta
		[],    # clut exp
		undef, # clut exp cache (for Lapack)
	];

	# if there are parameters
	if (@_) {
		
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
			
			# make new nMIX object from attribute hash
			_new_from_hash($self, @_);
			
		# if one or two parameters, first parameter an ICC::Support::Chart object
		} elsif ((@_ == 1 || @_ == 2) && UNIVERSAL::isa($_[0], 'ICC::Support::Chart')) {
			
			# make new nMIX object from chart
			_new_from_chart($self, @_);
			
		} else {
			
			# error
			croak('parameter must be a hash reference or ICC::Support::Chart object');
			
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
			
			# set header to copy of hash
			$self->[0] = {%{$_[0]}};
			
		} else {
			
			# error
			croak('parameter must be a hash reference');
			
		}
		
	}

	# return reference
	return($self->[0]);

}

# get/set reference to clut array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub array {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 2-D array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {ref() eq 'ARRAY'} @{$_[0]}) {
			
			# copy array to object and bless
			$self->[1] = bless(Storable::dclone($_[0]), 'Math::Matrix');
			
		# if one parameter, a Math::Matrix object
		} elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'Math::Matrix')) {
			
			# copy matrix to object
			$self->[1] = Storable::dclone($_[0]);
			
		} else {
			
			# error
			croak('clut must be a 2-D array reference or Math::Matrix object');
			
		}
		
		# for each corner point
		for my $i (0 .. $#{$self->[1]}) {
			
			# for each spectral value
			for my $j (0 .. $#{$self->[1][$i]}) {
				
				# set value to zero, if negative
				$self->[1][$i][$j] = 0 if ($self->[1][$i][$j] < 0);
				
			}
			
		}
		
		# update arrays
		_update_clut_exp($self);
		
	}

	# return reference
	return($self->[1]);

}

# get/set reference to delta array
# scalar value parameter fills array with that value
# parameters: ([ref_to_new_array -or- scalar_value])
# returns: (ref_to_array)
sub delta {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 1-D array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {Scalar::Util::looks_like_number($_)} @{$_[0]}) {
			
			# make delta array
			$self->[2] = [@{$_[0]}];
			
		# if one parameter, a scalar number
		} elsif (@_ == 1 && Scalar::Util::looks_like_number($_[0])) {
			
			# if array is defined
			if (defined($self->[1])) {
				
				# make delta array
				$self->[2] = [($_[0]) x @{$self->[1][0]}];
				
			} else {
				
				# error
				croak ('array must be defined when specifying delta as a scalar');
				
			}
			
		} else {
			
			# error
			croak('\'delta\' parameter must be a scalar or a 1-D array reference');
			
		}
		
		# update arrays
		_update_clut_exp($self);
		
	}

	# return reference
	return($self->[2]);

}

# get number of input channels
# returns: (number)
sub cin {

	# get object reference
	my $self = shift();

	# return
	return(int(log(@{$self->[1]})/log(2) + 1E-12));

}

# get number of output channels
# returns: (number)
sub cout {

	# get object reference
	my $self = shift();

	# return
	return(scalar(@{$self->[1][0]}));

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

# compute Jacobian matrix
# nominal input range is (0 - 1)
# hash key 'ubox' enables unit box extrapolation
# clipped outputs are extrapolated using Jacobian
# parameters: (input_vector, [hash])
# returns: (Jacobian_matrix, [output_vector])
sub jacobian {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($ext, $out, $jac, $jac_bc, $d, $s, $dx);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if extrapolation required (any input outside the unit box)
	if ($hash->{'ubox'} && grep {$_ < 0.0 || $_ > 1.0} @{$in}) {
		
		# compute intersection with unit box
		($ext, $in) = _intersect($in);
		
	}

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output using Lapack module
		$out = ICC::Support::Lapack::nMIX_vec_trans($in, $self->[4], $self->[2]);
		
		# compute Jacobian using Lapack module
		$jac = ICC::Support::Lapack::nMIX_jacobian($in, $self->[4], $self->[2], $out);
		
		# bless Jacobian as Math::Matrix object
		bless($jac, 'Math::Matrix');
		
	} else {
		
		# compute output values
		$out = _trans1($self, $in);
		
		# compute the barycentric jacobian
		$jac_bc = _barycentric_jacobian($in);
		
		# compute Jacobian (before exponentiation)
		$jac = $self->[3]->transpose * $jac_bc;
		
		# for each row (output)
		for my $i (0 .. $#{$jac}) {
			
			# get delta value
			$d = $self->[2][$i];
			
			# skip if delta is one
			next if ($d == 1);
			
			# get output value
			$s = $out->[$i];
			
			# compute exponentiation adjustment
			$dx = $s ? $d ? abs($s)**(1 - $d)/$d : $s : 0;
			
			# for each column (input)
			for my $j (0 .. $#{$jac->[0]}) {
				
				# adjust for exponentiation
				$jac->[$i][$j] *= $dx;
				
			}
			
		}
		
	}

	# if output values wanted
	if (wantarray) {
		
		# if output extrapolated
		if (defined($ext)) {
			
			# for each output
			for my $i (0 .. $#{$out}) {
				
				# add delta value
				$out->[$i] += ICC::Shared::dotProduct($jac->[$i], $ext);
				
			}
			
		}
		
		# return Jacobian and output vector
		return($jac, $out);
		
	} else {
		
		# return Jacobian only
		return($jac);
		
	}
	
}

# compute parametric Jacobian matrix
# parameters: (input_vector)
# returns: (parametric_jacobian_matrix)
sub parajac {

	# get parameters
	my ($self, $in) = @_;

	# return Jacobian matrix
	return(Math::Matrix->diagonal(_parametric($self, $in)));

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
	my ($coef, $sum, $product, @out);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output using Lapack module
		@out = @{ICC::Support::Lapack::nMIX_vec_trans(\@_, $self->[4], $self->[2])};
		
	} else {
		
		# compute output using '_trans1'
		@out = @{_trans1($self, \@_)};
		
	}

	# return
	return(@out);

}

# transform vector
# parameters: (object_reference, vector, [hash])
# returns: (vector)
sub _trans1 {
	
	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($coef, $sum, $out);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output using Lapack module
		$out = ICC::Support::Lapack::nMIX_vec_trans($in, $self->[4], $self->[2]);
		
	} else {
		
		# compute barycentric coefficients
		$coef = _barycentric($in);
		
		# for each output value
		for my $i (0 .. $#{$self->[3][0]}) {
			
			# initialize sum
			$sum = 0;
			
			# for each coefficient
			for my $j (0 .. $#{$coef}) {
				
				# add product to sum
				$sum += $self->[3][$j][$i] * $coef->[$j] if ($coef->[$j]);
				
			}
			
			# save result
			$out->[$i] = _pow1p($sum, $self->[2][$i]);
			
		}
		
	}

	# return
	return($out);

}

# transform matrix (2-D array -or- Math::Matrix object)
# parameters: (object_reference, matrix, [hash])
# returns: (matrix)
sub _trans2 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($coef, $sum, $product, $mean, $ratio, $out);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output using Lapack module
		$out = ICC::Support::Lapack::nMIX_mat_trans($in, $self->[4], $self->[2]);
		
	} else {
		
		# for each input vector
		for my $k (0 .. $#{$in}) {
			
			# compute barycentric coefficients
			$coef = _barycentric($in->[$k]);
				
			# for each output value
			for my $i (0 .. $#{$self->[3][0]}) {
				
				# initialize sum
				$sum = 0;
				
				# for each coefficient
				for my $j (0 .. $#{$coef}) {
					
					# add product to sum
					$sum += $self->[3][$j][$i] * $coef->[$j] if ($coef->[$j]);
					
				}
				
				# save result
				$out->[$k][$i] = _pow1p($sum, $self->[2][$i]);
				
			}
			
		}
		
	}

	# return
	return(UNIVERSAL::isa($in, 'Math::Matrix') ? bless($out, 'Math::Matrix') : $out);

}

# transform structure
# parameters: (object_reference, structure, [hash])
# returns: (structure)
sub _trans3 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($out);

	# transform the array structure
	_crawl($self, $in, $out = [], $hash);

	# return
	return($out);

}

# recursive transform
# array structure is traversed until scalar arrays are found and transformed
# parameters: (ref_to_object, input_array_reference, output_array_reference, hash)
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

# update exponentiated CLUT
# parameter: (ref_to_object)
sub _update_clut_exp {

	# get object reference
	my $self = shift();

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if clut and delta are defined and not null
	if (defined($self->[1]) && @{$self->[1]} && defined($self->[2]) && @{$self->[2]}) {
		
		# if ICC::Support::Lapack module is loaded
		if ($lapack) {
			
			# compute mixture array
			$self->[3] = ICC::Support::Lapack::nMIX_power($self->[1], $self->[2]);
			
			# create cached mixture array
			$self->[4] = ICC::Support::Lapack::cache_2D($self->[3]);
			
		} else {
			
			# for each row
			for my $i (0 .. $#{$self->[1]}) {
				
				# for each column
				for my $j (0 .. $#{$self->[1][0]}) {
					
					# exponentiate corner point value
					$self->[3][$i][$j] = _powm1($self->[1][$i][$j], $self->[2][$j]);
					
				}
				
			}
			
		}
		
	}

	# bless as Math::Matrix object
	bless($self->[3], 'Math::Matrix');

}

# compute barycentric coefficients
# parameter: (input_vector)
# returns: (coefficient_array)
sub _barycentric {

	# get parameter
	my $dev = shift();

	# local variables
	my ($devc, $coef);

	# compute complement values
	$devc = [map {1 - $_} @{$dev}];

	# initialize coefficient array
	$coef = [(1.0) x 2**@{$dev}];

	# for each coefficient
	for my $i (0 .. $#{$coef}) {
		
		# for each device value
		for my $j (0 .. $#{$dev}) {
			
			# if $j-th bit set
			if ($i >> $j & 1) {
				
				# multiply by device value
				$coef->[$i] *= $dev->[$j];
				
			} else {
				
				# multiply by (1 - device value)
				$coef->[$i] *= $devc->[$j];
				
			}
		
		}
	
	}

	# return
	return($coef);

}

# compute barycentric Jacobian matrix
# parameter: (input_vector)
# returns: (Jacobian_matrix)
sub _barycentric_jacobian {

	# get parameter
	my $dev = shift();

	# local variables
	my ($devc, $rows, $jac);

	# compute complement values
	$devc = [map {1 - $_} @{$dev}];

	# compute matrix rows
	$rows = 2**@{$dev};

	# for each matrix row
	for my $i (0 .. $rows - 1) {
		
		# initialize row
		$jac->[$i] = [(1.0) x @{$dev}];
		
		# for each matrix column
		for my $j (0 .. $#{$dev}) {
			
			# for each device value
			for my $k (0 .. $#{$dev}) {
				
				# if $k-th bit set
				if ($i >> $k & 1) {
					
					# multiply by device value -or- 1 (skip)
					$jac->[$i][$j] *= $dev->[$k] if ($j != $k);
					
				} else {
					
					# multiply by (1 - device value) -or- -1
					$jac->[$i][$j] *= ($j != $k) ? $devc->[$k] : -1;
					
				}
				
			}
			
		}
		
	}

	# return
	return(bless($jac, 'Math::Matrix'));

}

# find unit box intersection
# with line from input to box-center
# parameters: (input_vector)
# returns: (extrapolation_vector, intersection_vector)
sub _intersect {

	# get input values
	my ($in) = shift();

	# local variables
	my (@cin, $dmax, $ubox, $ext);

	# compute input to box-center difference
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

	# compute intersection vector (on surface of unit box)
	$ubox = [map {$_/$dmax + 0.5} @cin];

	# compute extrapolation vector (as Math::Matrix object)
	$ext = [map {$in->[$_] - $ubox->[$_]} (0 .. $#{$in})];

	# return
	return($ext, $ubox);

}

# compute parametric partial derivatives
# parameters: (object_reference, input_vector)
# returns: (partial_derivative_vector)
sub _parametric {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($bc, $cp, $d, $s1, $sum1, $sum2, $pj, $dk, $pd, $r);

	# calculate barycentric coordinates
	$bc = _barycentric($in);

	# get corner point matrix
	$cp = $self->[1];

	# for each delta/output value
	for my $i (0 .. $#{$self->[2]}) {
		
		# get delta value
		$d = $self->[2][$i];
		
		# if delta non-zeroish
		if (abs($d) >= 1E-5) {
			
			# initialize sums
			$sum1 = $sum2 = 0;
			
			# for each corner point
			for my $j (0 .. $#{$cp}) {
				
				# accumulate sums
				$sum1 += $s1 = $bc->[$j] * $cp->[$j][$i]**$d;
				$sum2 += $s1 * log($cp->[$j][$i]);
				
			}
			
			# compute partial derivative
			$pj->[$i] = $sum1**(1/$d) * ($sum2/$sum1 - log($sum1)/$d)/$d;
			
		} else {
			
			# for delta +/- 1E-5
			for my $k (0 .. 1) {
				
				# set delta
				$dk = $k ? -1E-5 : 1E-5;
				
				# initialize sums
				$sum1 = $sum2 = 0;
				
				# for each corner point
				for my $j (0 .. $#{$cp}) {
					
					# accumulate sums
					$sum1 += $s1 = $bc->[$j] * $cp->[$j][$i]**$dk;
					$sum2 += $s1 * log($cp->[$j][$i]);
					
				}
				
				# compute partial derivative
				$pd->[$k] = $sum1**(1/$dk) * ($sum2/$sum1 - log($sum1)/$dk)/$dk;
				
			}
			
			# compute interpolation ratio
			$r = 0.5 - $d/2E-5;
			
			# interpolate partial derivative
			$pj->[$i] = $r * $pd->[0] + (1 - $r) * $pd->[1];
			
		}
		
	}

	# return array of partial derivatives
	return($pj);

}

# exponentiate corner point
# uses expm1 function for small exponents
# parameters: (base, exponent)
# returns: (base^exponent)
sub _powm1 {

	# get parameters
	my ($base, $exp) = @_;

	if ($exp == 0.0) {
		
		if ($base > 0.0) {
			
			return(log($base))
			
		} else {
			
			return(-(DBL_MAX))
			
		}
		
	} elsif ($exp < 1.0) {
		
		if ($base > 0.0) {
			
			return(ICC::Support::Lapack::expm1(log($base) * $exp))
			
		} else {
			
			return(-1.0)
			
		}
		
	} else {
		
		if ($base > 0.0) {
			
			return(POSIX::pow($base, $exp))
			
		} else {
			
			return(0)
			
		}
		
	}
	
}

# exponentiate barycentric sum
# uses log1p function for small exponents
# parameters: (base, exponent)
# returns: (base^(1/exponent))
sub _pow1p {

	# get parameters
	my ($base, $exp) = @_;
	
	if ($exp == 0.0) {
		
		return(exp($base))
		
	} elsif ($exp < 1.0) {
		
		if ($base > -1.0) {
			
			return(exp(ICC::Support::Lapack::log1p($base)/$exp))
			
		} else {
			
			return(0.0)
			
		}
		
	} else {
		
		if ($base > 0.0) {
			
			return(POSIX::pow($base, 1.0/$exp))
			
		} else {
			
			return(0.0)
			
		}
		
	}
	
}

# make new nMIX object from attribute hash
# hash may contain pointers to clut array or delta array
# hash keys are: ('array', 'delta')
# object elements not specified in the hash are unchanged
# parameters: (ref_to_object, ref_to_attribute_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# local variable
	my ($value);

	# if 'array' attribute
	if (defined($value = $hash->{'array'})) {
		
		# if reference to a 2-D array
		if (ref($value) eq 'ARRAY' && @{$value} == grep {ref() eq 'ARRAY'} @{$value}) {
			
			# copy array to object and bless
			$self->[1] = bless(Storable::dclone($value), 'Math::Matrix');
			
		# if reference to a Math::Matrix object
		} elsif (UNIVERSAL::isa($value, 'Math::Matrix')) {
			
			# copy matrix to object
			$self->[1] = Storable::dclone($value);
			
		} else {
			
			# wrong data type
			croak('\'array\' must be a 2-D array reference or Math::Matrix object');
			
		}
		
		# for each corner point
		for my $i (0 .. $#{$self->[1]}) {
			
			# for each spectral value
			for my $j (0 .. $#{$self->[1][$i]}) {
				
				# set value to zero, if negative
				$self->[1][$i][$j] = 0 if ($self->[1][$i][$j] < 0);
				
			}
			
		}
		
	}

	# if 'delta' attribute
	if (defined($value = $hash->{'delta'})) {
		
		# if reference to a 1-D array (vector)
		if (ref($value) eq 'ARRAY' && @{$value} == grep {Scalar::Util::looks_like_number($_)} @{$value}) {
			
			# make delta array
			$self->[2] = [@{$value}];
			
		# if scalar number
		} elsif (Scalar::Util::looks_like_number($value)) {
			
			# if array is defined
			if (defined($self->[1])) {
				
				# make delta array
				$self->[2] = [($value) x @{$self->[1][0]}];
				
			} else {
				
				# error
				croak ('array must be defined when specifying delta as a scalar');
				
			}
			
		} else {
			
			# wrong data type
			croak('\'delta\' must be a scalar or a 1-D array reference');
			
		}
		
	} 

	# update arrays
	_update_clut_exp($self);

}

# make new nMIX object from ICC::Support::Chart object
# chart must contain device values and, spectral or XYZ values
# copies corner points into clut array, warns if corner point(s) missing
# parameters: (ref_to_object, ref_to_chart, [columns])
sub _new_from_chart {

	# get parameters
	my ($self, $chart, $cols) = @_;

	# local variables
	my ($dev, $fmt, $devc, $cs);

	# verify chart has device values
	($dev = $chart->device()) || croak('chart must have device values');

	# verify clut column slice is defined
	(defined($cols) || ($cols = $chart->spectral() || $chart->xyz())) || croak('clut data slice is undefined');

	# get format keys
	$fmt = $chart->fmt_keys($cols);

	# verify spectral or XYZ data
	((@{$fmt} == grep {m/^(?:(.*)\|)?(?:nm|SPECTRAL_NM_|SPECTRAL_NM|SPECTRAL_|NM_|R_)\d{3}$/} @{$fmt}) || (3 == grep {m/^(?:(.*)\|)?XYZ_[XYZ]$/} @{$fmt})) || warn('clut data neither spectral nor XYZ');

	# for each corner point
	for my $i (0 .. 2**@{$dev} - 1) {
		
		# for each device channel
		for my $j (0 .. $#{$dev}) {
			
			# get device value
			$devc->[$j] = $i >> $j & 1;
			
		}
		
		# get corner point samples
		($cs = $chart->ramp(sub {@{$devc} == grep {$devc->[$_] == $_[$_]} (0 .. $#{$devc})})) || croak("no chart samples for corner point [@{$devc}]\n");
		
		# save clut vector
		$self->[1][$i] = $chart->slice($chart->add_avg($cs), $cols)->[0];
		
		# discard avg sample
		pop(@{$chart->array()});
		
		# for each spectral value
		for my $j (0 .. $#{$self->[1][$i]}) {
			
			# if value is negative
			if ($self->[1][$i][$j] < 0) {
				
				# set value to zero
				$self->[1][$i][$j] = 0;
				
				# print warning
				print "clut value [$i][$j] was negative, set to 0\n";
				
			}
			
		}
		
	}

	# bless clut
	bless($self->[1], 'Math::Matrix');

}

1;