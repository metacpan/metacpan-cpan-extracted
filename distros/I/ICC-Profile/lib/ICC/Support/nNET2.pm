package ICC::Support::nNET2;

use strict;
use Carp;

our $VERSION = 0.21;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# use POSIX math
use POSIX ();

# enable static variables
use feature 'state';

# list of functions to export
our @EXPORT = qw(rbf_g rbf_iq rbf_mq rbf_imq rbf_phs rbf_tps);

# list of valid kernel types
my @types = qw(CODE ICC::Support::geo1 ICC::Support::geo2);

# create new nNET object
# hash keys are: 'header', 'kernel', 'hidden', 'weight', 'offset', 'init'
# 'header' value is a hash reference
# 'kernel' value is an array reference of kernel objects -or- CODE references
# 'hidden' value is an array reference of CODE references
# 'weight' value is an array reference (2-D) -or- Math::Matrix object
# 'offset' value is an array reference
# 'init' value is a CODE reference
# parameters: ([ref_to_attribute_hash])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift;

	# local variable
	my ($code);

	# create empty nNET object
	my $self = [
		{},     # object header
		[],     # kernel array
		[],     # hidden array
		[],     # weight matrix
		[]      # offset vector
	];

	# if there are parameters
	if (@_) {
		
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
			
			# make new nNET object from attribute hash
			_new_from_hash($self, shift());
			
			# initialize object (if CODE reference defined)
			(defined($code = $self->[0]{'init'}) && &$code);
			
		} else {
			
			# error
			croak('\'nNET\' parameter must be a hash reference');
			
		}
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# initialize object
# calls 'init' CODE reference, if any
# used when retrieving an nNET object using Storable
sub init {

	# get object reference
	my $self = shift();

	# local variable
	my ($code);

	# initialize object (if CODE reference defined)
	(defined($code = $self->[0]{'init'}) && &$code);

}

# fit nNET object to data
# determines optimum 'weight' and 'offset' arrays
# kernel and hidden nodes are not modified by this method
# uses LAPACK dgelsd function to perform a least-squares fit
# fitting is done with or without offset, according to offset_flag
# input and output are 2D array references or Math::Matrix objects
# parameters: (ref_to_input_array, ref_to_output_array, [offset_flag])
# returns: (dgelsd_info_value)
sub fit {

	# get parameters
	my ($self, $in, $out, $oflag) = @_;

	# local variables
	my ($info, $hidden, $ab);

	# verify input array
	(ref($in) eq 'ARRAY' && ref($in->[0]) eq 'ARRAY' && ! ref($in->[0][0])) || (UNIVERSAL::isa($in, 'Math::Matrix')) || croak('fit input not a 2-D array reference');

	# verify output array
	(ref($out) eq 'ARRAY' && ref($out->[0]) eq 'ARRAY' && ! ref($out->[0][0])) || (UNIVERSAL::isa($out, 'Math::Matrix')) || croak('fit output not a 2-D array reference');

	# verify array dimensions
	($#{$in} == $#{$out}) || croak('fit input and output arrays have different number of rows');

	# compute hidden array
	$hidden = _hidden2($self, $in);

	# fit matrix and offset (hidden values to output values)
	($info, $ab) = ICC::Support::Lapack::nNET_fit($hidden, $out, defined($oflag) ? $oflag : 0);

	# check result
	carp('fit failed - bad parameter when calling dgelsd') if ($info < 0);
	carp('fit failed - SVD algorithm failed to converge') if ($info > 0);

	# initialize matrix and offset
	undef($self->[3]);
	undef($self->[4]);

	# for each output
	for my $i (0 .. $#{$out->[0]}) {
		
		# for each input
		for my $j (0 .. $#{$hidden->[0]}) {
			
			# set matrix element (transposing)
			$self->[3][$i][$j] = $ab->[$j][$i];
			
		}
		
	}
	
	# if offset flag
	if ($oflag) {
		
		# set offset
		$self->[4] = [@{$ab->[$#{$self->[1]} + 1]}];
		
	}

	# return info value
	return($info);

}

# get/set reference to header hash
# parameters: ([ref_to_new_hash])
# returns: (ref_to_hash)
sub header {

	# get parameters
	my ($self, $header) = @_;

	# if parameter supplied
	if (defined($header)) {
		
		# verify a hash reference
		(ref($header) eq 'HASH') || croak('\'nNET2\' header wrong data type');
		
		# copy header hash
		$self->[0] = {%{$header}};
		
	}

	# return hash
	return($self->[0]);

}

# get/set kernel array reference
# parameters: ([ref_to_array])
# returns: (ref_to_array)
sub kernel {

	# get parameters
	my ($self, $kernel) = @_;

	# if parameter supplied
	if (defined($kernel)) {
		
		# verify an array reference
		(ref($kernel) eq 'ARRAY') || croak('\'nNET2\' kernel wrong data type');
		
		# initialize object array
		$self->[1] = [];
		
		# for each kernel element
		for my $i (0 .. $#{$kernel}) {
			
			# if a valid kernel type
			if (grep {ref($kernel->[$i]) eq $_} @types) {
				
				# copy kernel object
				$self->[1][$i] = $kernel->[$i];
				
			} else {
				
				# wrong data type
				croak('\'nNET\' kernel element wrong data type');
				
			}
			
		}
		
	}

	# return kernel array
	return($self->[1]);

}

# get/set hidden array reference
# parameters: ([ref_to_array])
# returns: (ref_to_array)
sub hidden {

	# get parameters
	my ($self, $hidden) = @_;

	# if parameter supplied
	if (defined($hidden)) {
		
		# verify an array reference
		(ref($hidden) eq 'ARRAY') || croak('\'nNET2\' hidden wrong data type');
		
		# initialize object array
		$self->[2] = [];
		
		# for each hidden element
		for my $i (0 .. $#{$hidden}) {
			
			# if a CODE reference
			if (ref($hidden->[$i]) eq 'CODE') {
				
				# copy hidden element
				$self->[2][$i] = $hidden->[$i];
				
			} else {
				
				# wrong data type
				croak('\'nNET2\' hidden element wrong data type');
				
			}
			
		}
		
	}

	# return hidden array
	return($self->[2]);

}

# get/set reference to matrix array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub matrix {

	# get parameters
	my ($self, $matrix) = @_;

	# if parameter supplied
	if (defined($matrix)) {
		
		# verify a 2-D array reference or Math::Matrix object
		((ref($matrix) eq 'ARRAY' && @{$matrix} == grep {ref() eq 'ARRAY'} @{$matrix}) || UNIVERSAL::isa($matrix, 'Math::Matrix')) || croak('\'nNET2\' matrix wrong data type');
		
		# copy matrix
		$self->[3] = Storable::dclone($matrix);
		
	}

	# return matrix
	return($self->[3]);

}

# get/set reference to offset array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub offset {

	# get parameters
	my ($self, $offset) = @_;

	# if parameter supplied
	if (defined($offset)) {
		
		# verify a reference to array of scalars
		(ref($offset) eq 'ARRAY' && @{$offset} == grep {! ref()} @{$offset}) || croak('\'nNET2\' offset wrong data type');
		
		# copy offset
		$self->[4] = [@{$offset}];
		
	}

	# return offset
	return($self->[4]);

}

# add kernel objects
# parameters: (ref_to_array_of_objects)
# returns: (ref_to_array_of_geo_indices)
sub add_kernel {

	# get parameters
	my ($self, $kernel) = @_;

	# local variables
	my (@gx);

	# verify add_kernel parameter supplied
	(defined($kernel)) || carp('\'nNET2\' add_kernel parameter undefined');

	# wrap if not an array reference
	$kernel = [$kernel] if (ref($kernel) ne 'ARRAY');

	# for each kernel element
	for my $i (0 .. $#{$kernel}) {
		
		# if a valid kernel type
		if (grep {ref($kernel->[$i]) eq $_} @types) {
			
			# add kernel object
			push(@{$self->[1]}, $kernel->[$i]);
			
			# add geo index (kernel index + 1)
			push(@gx, $#{$self->[1]} + 1);
			
		} else {
			
			# wrong data type
			croak('\'nNET\' add_kernel element wrong data type');
			
		}
		
	}

	# return index array ref
	return(\@gx);

}

# add hidden subroutines
# parameters: (ref_to_array_of_CODE_refs)
# returns: (ref_to_array_of_hidden_indices)
sub add_hidden {

	# get parameters
	my ($self, $hidden) = @_;

	# local variables
	my (@hx);

	# verify add_hidden parameter supplied
	(defined($hidden)) || carp('\'nNET2\' add_hidden parameter undefined');

	# wrap if not an array reference
	$hidden = [$hidden] if (ref($hidden) ne 'ARRAY');

	# for each hidden element
	for my $i (0 .. $#{$hidden}) {
		
		# if a CODE reference
		if (ref($hidden->[$i]) eq 'CODE') {
			
			# add hidden element
			push(@{$self->[2]}, $hidden->[$i]);
			
			# add hidden index
			push(@hx, $#{$self->[2]});
			
		} else {
			
			# wrong data type
			croak('\'nNET2\' add_hidden element wrong data type');
			
		}
		
	}

	# return index array ref
	return(\@hx);

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

# inverse transform
# note: number of undefined output values must equal number of defined input values
# note: the input and output vectors contain the final solution on return
# hash key 'init' specifies initial value vector
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
# using numerical approximation
# parameters: (input_vector, [hash])
# returns: (Jacobian_matrix, [output_vector])
sub jacobian {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($out, $din, $dout, $delta, $jac);

	# get output array
	$out = _trans1($self, $in);

	# set delta
	$delta = 1E-9;

	# for each input channel
	for my $i (0 .. $#{$in}) {
		
		# copy input array
		@{$din} = @{$in};
		
		# add delta to input channel
		$din->[$i] += $delta;
		
		# compute new output values
		$dout = transform($self, $din);
		
		# for each output value
		for my $j (0 .. $#{$out}) {
			
			# compute Jacobian matrix element
			$jac->[$j][$i] = ($dout->[$j] - $out->[$j])/$delta;
			
		}
		
	}

	# bless Jacobian matrix
	bless($jac, 'Math::Matrix');

	# if array wanted
	if (wantarray) {
		
		# return Jacobian and output array
		return($jac, $out);
		
	} else {
		
		# return Jacobian
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

# radial basis function - Gaussian
# ϕ(r) = e^-(εr)²
# parameters: (radius, ε)
# returns: (ϕ)
sub rbf_g {
	
	# return function value
	return(exp(-($_[0] * $_[1])**2));
	
}

# radial basis function - Inverse quadratic
# ϕ(r) = 1/(1 + (εr)²)
# parameters: (radius, ε)
# returns: (ϕ)
sub rbf_iq {
	
	# return function value
	return(1/(1 + ($_[0] * $_[1])**2));
	
}

# radial basis function - Multiquadric
# ϕ(r) = sqrt(1 + (εr)²)
# parameters: (radius, ε)
# returns: (ϕ)
sub rbf_mq {
	
	# return function value
	return(sqrt(1 + ($_[0] * $_[1])**2));
	
}

# radial basis function - Inverse multiquadric
# ϕ(r) = 1/sqrt(1 + (εr)²)
# parameters: (radius, ε)
# returns: (ϕ)
sub rbf_imq {
	
	# return function value
	return(1/sqrt(1 + ($_[0] * $_[1])**2));
	
}

# radial basis function - Polyharmonic spline
# ϕ(r) = rᵏ, k = 1, 3, 5, ...
# ϕ(r) = rᵏln(r), k = 2, 4, 6, ...
# parameters: (radius, k)
# returns: (ϕ)
sub rbf_phs {
	
	# return function value
	return($_[1] % 2 ? $_[0]**$_[1] : $_[0]**$_[1] * log($_[0]));
	
}

# radial basis function - Thin plate spline
# ϕ(r) = r²ln(r)
# parameters: (radius)
# returns: (ϕ)
sub rbf_tps {
	
	# return function value
	return($_[0]**2 * log($_[0]));
	
}

# transform list
# parameters: (object_reference, list, [hash])
# returns: (list)
sub _trans0 {

	# local variables
	my ($self, $hash, @out);

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# compute output using '_trans1'
	@out = @{_trans1($self, \@_, $hash)};

	# return
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

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# call the BLAS dgemv function
		return(ICC::Support::Lapack::matf_vec_trans(_hidden($self, $in), $self->[3], $self->[4]));
		
	} else {
		
		croak('method not yet implemented');
		
	}
	
}

# transform matrix (2-D array -or- Math::Matrix object)
# parameters: (object_reference, matrix, [hash])
# returns: (matrix)
sub _trans2 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($out);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# call the BLAS dgemm function
		$out = ICC::Support::Lapack::matf_mat_trans(_hidden2($self, $in), $self->[3], $self->[4]);
		
	} else {
		
		croak('method not yet implemented');
		
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

	# transform the array structure
	_crawl($self, $in, my $out = [], $hash);

	# return
	return($out);

}

# recursive transform
# array structure is traversed until scalar arrays are found and transformed
# parameters: (ref_to_object, ref_to_input_array, ref_to_output_array, hash)
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

# compute hidden node output vector
# parameters: (ref_to_object, ref_to_input_vector)
# returns: (ref_to_output_vector)
sub _hidden {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my (@geo, @hidden);

	# init array
	@geo = ($in);

	# for each kernel node
	for my $node (@{$self->[1]}) {
		
		# if a code reference
		if (ref($node) eq 'CODE') {
			
			# call subroutine
			push(@geo, [&$node($in)]);
			
		# else an object
		} else {
			
			# call transform method
			push(@geo, [$node->transform($in)]);
			
		}
		
	}

	# for each hidden node
	for my $node (@{$self->[2]}) {
		
		# add hidden value(s)
		push(@hidden, &$node(\@geo));
		
	}

	# return
	return([@hidden]);

}

# compute hidden node output matrix
# parameters: (ref_to_object, ref_to_array_of_input_vectors)
# returns: (ref_to_array_of_output_vectors)
sub _hidden2 {

	# get parameters
	my ($self, $array) = @_;

	# local variables
	my (@geo, @hidden, @out);

	# for each input vector
	for my $in (@{$array}) {
		
		# init array
		@geo = ($in);
		
		# for each kernel node
		for my $node (@{$self->[1]}) {
			
			# if a code reference
			if (ref($node) eq 'CODE') {
				
				# call subroutine
				push(@geo, [&$node($in)]);
				
			# else an object
			} else {
				
				# call transform method
				push(@geo, [$node->transform($in)]);
				
			}
			
		}
		
		# init array
		@hidden = ();
		
		# for each hidden node
		for my $node (@{$self->[2]}) {
			
			# add hidden value(s)
			push(@hidden, &$node(\@geo));
			
		}
		
		# add to output array
		push(@out, [@hidden]);
		
	}

	# return
	return([@out]);

}

# make new nNET object from attribute hash
# hash may contain pointers to header, kernel, matrix, offset or init
# hash keys are: ('header', 'kernel', 'matrix', 'offset', 'init')
# object elements not specified in the hash are unchanged
# parameters: (ref_to_object, ref_to_attribute_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($header, $kernel, $hidden, $matrix, $offset, $init);

	# get header
	if ($header = $hash->{'header'}) {
		
		# verify a hash reference
		(ref($header) eq 'HASH') || croak('\'nNET\' header wrong data type');
		
		# copy header hash
		$self->[0] = {%{$header}};
		
	}

	# get kernel
	if ($kernel = $hash->{'kernel'}) {
		
		# verify an array reference
		(ref($kernel) eq 'ARRAY') || croak('\'nNET\' kernel wrong data type');
		
		# for each kernel element
		for my $i (0 .. $#{$kernel}) {
			
			# if a valid kernel type
			if (grep {ref($kernel->[$i]) eq $_} @types) {
				
				# copy kernel object
				$self->[1][$i] = $kernel->[$i];
				
			} else {
				
				# wrong data type
				croak('\'nNET\' kernel element wrong data type');
				
			}
			
		}
		
	}

	# get hidden
	if ($hidden = $hash->{'hidden'}) {
		
		# verify an array reference
		(ref($hidden) eq 'ARRAY') || croak('\'nNET\' hidden wrong data type');
		
		# for each hidden element
		for my $i (0 .. $#{$hidden}) {
			
			# if a CODE reference
			if (ref($hidden->[$i]) eq 'CODE') {
				
				# copy hidden element
				$self->[2][$i] = $hidden->[$i];
				
			} else {
				
				# wrong data type
				croak('\'nNET\' hidden element wrong data type');
				
			}
			
		}
		
	}

	# get matrix
	if ($matrix = $hash->{'matrix'}) {
		
		# verify a 2-D array reference or Math::Matrix object
		((ref($matrix) eq 'ARRAY' && @{$matrix} == grep {ref() eq 'ARRAY'} @{$matrix}) || UNIVERSAL::isa($matrix, 'Math::Matrix')) || croak('\'nNET\' matrix wrong data type');
		
		# copy matrix
		$self->[3] = Storable::dclone($matrix);
		
	}

	# get offset
	if ($offset = $hash->{'offset'}) {
		
		# verify a reference to array of scalars
		(ref($offset) eq 'ARRAY' && @{$offset} == grep {! ref()} @{$offset}) || croak('\'nNET\' offset wrong data type');
		
		# copy offset
		$self->[4] = [@{$offset}];
		
	}

	# get init
	if ($init = $hash->{'init'}) {
		
		# verify a CODE reference
		(ref($init) eq 'CODE') || croak('\'nNET\' init wrong data type');
		
		# set init
		$self->[0]{'init'} = $init;
		
	}
	
}

1;