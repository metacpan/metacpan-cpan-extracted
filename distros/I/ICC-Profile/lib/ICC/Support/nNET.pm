package ICC::Support::nNET;

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

# use POSIX math
use POSIX ();

# enable static variables
use feature 'state';

# list of valid kernel types
my @types = qw(CODE ICC::Support::rbf);

# create new nNET object
# hash may contain pointers to header, kernel, matrix, offset or init
# kernel is a reference to an array of kernel objects or CODE references
# matrix is a 2D array reference or Math::Matrix object
# offset is a 1D array reference
# hash keys are: ('header', 'kernel', 'matrix', 'offset', 'init')
# parameters: ([ref_to_attribute_hash])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift;

	# local variable
	my ($code);

	# create empty nNET object
	my $self = [
				{},		# object header
				[],		# kernel array
				[],		# matrix matrix
				[]		# offset vector
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
			croak('nNET parameter must be a hash reference');
			
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
# determines optimum 'matrix' and 'offset' arrays
# kernel nodes are not modified by this method
# uses LAPACK dgelsd function to perform a least-squares fit
# fitting is done with or without offset, according to offset_flag
# fitting is done to output or input-output difference, according to diff_mode_flag
# input and output are 2D array references or Math::Matrix objects
# parameters: (ref_to_input_array, ref_to_output_array, [offset_flag, [diff_mode_flag]])
# returns: (dgelsd_info_value)
sub fit {

	# get parameters
	my ($self, $in, $out, $oflag, $dflag) = @_;

	# local variables
	my ($dif, $info, $ab);

	# resolve offset flag
	$oflag = 0 if (! defined($oflag));

	# verify input array
	(ref($in) eq 'ARRAY' && ref($in->[0]) eq 'ARRAY' && ! ref($in->[0][0])) || (UNIVERSAL::isa($in, 'Math::Matrix')) || croak('fit input not a 2-D array reference');

	# verify output array
	(ref($out) eq 'ARRAY' && ref($out->[0]) eq 'ARRAY' && ! ref($out->[0][0])) || (UNIVERSAL::isa($out, 'Math::Matrix')) || croak('fit output not a 2-D array reference');

	# verify array dimensions
	($#{$in} == $#{$out}) || croak('fit input and output arrays have different number of rows');

	# if difference mode
	if ($dflag) {
		
		# verify array dimensions
		($#{$in->[0]} == $#{$out->[0]}) || croak('fit input and output arrays have different number of columns');
		
		# for each row
		for my $i (0 .. $#{$in}) {
			
			# for each column
			for my $j (0 .. $#{$in->[0]}) {
				
				# compute output-input difference
				$dif->[$i][$j] = $out->[$i][$j] - $in->[$i][$j];
				
			}
			
		}
		
	}

	# fit the matrix (hidden values to output or difference values)
	($info, $ab) = ICC::Support::Lapack::nNET_fit(_hidden2($self, $in), $dflag ? $dif : $out, $oflag);

	# check result
	carp('fit failed - bad parameter when calling dgelsd') if ($info < 0);
	carp('fit failed - SVD algorithm failed to converge') if ($info > 0);

	# initialize matrix
	$self->[2] = [];

	# for each output
	for my $i (0 .. $#{$out->[0]}) {
		
		# for each kernel node
		for my $j (0 .. $#{$self->[1]}) {
		
			# set matrix element (transposing)
			$self->[2][$i][$j] = $ab->[$j][$i];
			
		}
		
	}
	
	# if offset flag
	if ($oflag) {
		
		# set offset
		$self->[3] = [@{$ab->[$#{$self->[1]} + 1]}];
		
	} else {
		
		# no offset
		undef($self->[3]);
		
	}
	
	# if difference flag
	if ($dflag) {
		
		# for each row
		for my $i (0 .. $#{$self->[2]}) {
			
			# for each column
			for my $j (0 .. $#{$self->[2]}) {
				
				# add identity matrix element
				$self->[2][$i][$j + $#{$self->[1]} + 1] = ($i == $j) ? 1 : 0;
				
			}
			
		}
		
	}

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

# get/set kernel array reference
# parameters: ([ref_to_array])
# returns: (ref_to_array)
sub kernel {

	# get object reference
	my $self = shift();

	# if one parameter supplied
	if (@_ == 1) {
		
		# get parameter
		my $array = shift;
		
		# if an array reference
		if (ref($array) eq 'ARRAY') {
			
			# initialize array
			$self->[1] = [];
			
			# for each array element
			for my $i (0 .. $#{$array}) {
				
				# if array element is a valid kernel type
				if (grep {ref($array->[$i]) eq $_} @types) {
					
					# add array element
					$self->[1][$i] = $array->[$i];
					
				} else {
					
					# wrong data type
					croak('invalid nNET kernel array element');
					
				}
				
			}
			
		} else {
			
			# wrong data type
			croak('nNET kernel attribute must be an array reference');
			
		}
		
	} elsif (@_) {
		
		# error
		croak('too many parameters');
		
	}

	# return kernel array reference
	return($self->[1]);

}

# get/set reference to matrix
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub matrix {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a reference to 2D array
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && ref($_[0][0]) eq 'ARRAY') {
			
			# set object element
			$self->[2] = Storable::dclone(shift());
			
		# if one parameter, a reference to Math::Matrix object
		} elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'Math::Matrix')) {
			
			# set object element
			$self->[2] = Storable::dclone([@{shift()}]);
			
		} else {
			
			# wrong data type
			croak('nNET matrix attribute must be an array reference or Math::Matrix object');
			
		}
		
	}

	# return matrix reference
	return($self->[2]);

}

# get/set reference to offset array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub offset {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a reference to an array of scalars
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {! ref()} @{$_[0]}) {
			
			# set object element
			$self->[3] = [@{shift()}];
			
		} else {
			
			# wrong data type
			croak('nNET offset attribute must be an array reference');
			
		}
		
	}

	# return offset reference
	return($self->[3]);

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
# parameters: (input_vector, [hash])
# returns: (Jacobian_matrix, [output_vector])
sub jacobian {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($jac, $out);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# compute hidden Jacobian and output
	($jac, $out) = _hidden3($self, $in);

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# if output values wanted
		if (wantarray) {
			
			# return Jacobian and output
			return(bless(ICC::Support::Lapack::mat_xplus($self->[2], $jac), 'Math::Matrix'), ICC::Support::Lapack::matf_vec_trans($out, $self->[2], $self->[3]));
			
		} else {
			
			# return Jacobian only
			return(bless(ICC::Support::Lapack::mat_xplus($self->[2], $jac), 'Math::Matrix'));
			
		}
		
	} else {
		
		croak('method not yet implemented');
		
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

	# local variables
	my ($out);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# call the BLAS dgemv function
		return(ICC::Support::Lapack::matf_vec_trans(_hidden($self, $in), $self->[2], $self->[3]));
		
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
		$out = ICC::Support::Lapack::matf_mat_trans(_hidden2($self, $in), $self->[2], $self->[3]);
		
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
	my ($array, $node, $out);

	# get kernel array
	$array = $self->[1];

	# for each node
	for my $i (0 .. $#{$array}) {
		
		# get node
		$node = $array->[$i];
		
		# if a code reference
		if (ref($node) eq 'CODE') {
			
			# call subroutine
			$out->[$i] = &$node($in);
			
		# else a kernel object
		} else {
			
			# call transform method
			$out->[$i] = $node->transform($in);
			
		}
		
	}

	# if array rows < matrix columns (difference mode)
	if ($#{$array} < $#{$self->[2][0]}) {
		
		# append input values
		push(@{$out}, @{$in});
		
	}

	# return
	return($out);

}

# compute hidden node output matrix
# parameters: (ref_to_object, ref_to_array_of_input_vectors)
# returns: (ref_to_array_of_output_vectors)
sub _hidden2 {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($array, $node, $out);

	# get kernel array
	$array = $self->[1];

	# initialize output array
	$out = [];

	# for each input row
	for my $i (0 .. $#{$in}) {
		
		# for each node
		for my $j (0 .. $#{$array}) {
			
			# get node
			$node = $array->[$j];
			
			# if a code reference
			if (ref($node) eq 'CODE') {
				
				# call subroutine
				$out->[$i][$j] = &$node($in->[$i]);
				
			# else a kernel object
			} else {
				
				# call transform method
				$out->[$i][$j] = $node->transform($in->[$i]);
				
			}
			
		}
		
		# if array rows < matrix columns (difference mode)
		if ($#{$array} < $#{$self->[2][0]}) {
			
			# append input values
			push(@{$out->[$i]}, @{$in->[$i]});
			
		}
		
	}

	# return
	return($out);

}

# compute hidden node Jacobian matrix
# parameters: (ref_to_object, ref_to_input_vector)
# returns: (ref_to_Jacobian_matrix, [ref_to_output_vector])
sub _hidden3 {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($array, $node, $jac, $out);

	# get kernel array
	$array = $self->[1];

	# for each node
	for my $i (0 .. $#{$array}) {
		
		# get node
		$node = $array->[$i];
		
		# if a code reference
		if (ref($node) eq 'CODE') {
			
			# if output requested
			if (wantarray) {
				
				# compute numerical Jacobian
				$jac->[$i] = _numjac($node, $in);
				
				# call subroutine
				$out->[$i] = &$node($in);
				
			} else {
				
				# compute numerical Jacobian
				$jac->[$i] = _numjac($node, $in);
				
			}
			
		# else a kernel object
		} else {
			
			# if output requested
			if (wantarray) {
				
				# call jacobian method
				($jac->[$i], $out->[$i]) = $node->jacobian($in);
				
			} else {
				
				# call jacobian method
				$jac->[$i] = $node->jacobian($in);
				
			}
			
		}
		
	}
	
	# if array rows < matrix columns (difference mode)
	if ($#{$array} < $#{$self->[2][0]}) {
		
		# for each row
		for my $i (0 .. $#{$self->[2]}) {
			
			# for each column
			for my $j (0 .. $#{$self->[2]}) {
				
				# add identity matrix element
				$jac->[$i + $#{$self->[1]} + 1][$j] = $i == $j ? 1 : 0;
				
			}
			
		}
		
	}
	
	# if output vector requested
	if (wantarray) {
		
		# if array rows < matrix columns (difference mode)
		if ($#{$array} < $#{$self->[2][0]}) {
			
			# append input values
			push(@{$out}, @{$in});
			
		}
		
		# return
		return($jac, $out);
		
	} else {
		
		# return
		return($jac);
		
	}
	
}

# compute numerical Jacobian
# parameters: (code_reference, input_vector)
# output: (Jacobian_vector)
sub _numjac {

	# get parameters
	my ($node, $in) = @_;

	# local variables
	my ($delta, $ind, $out, $jac);

	# set delta value
	$delta = 1E-12;

	# compute nominal output
	$out = &$node($in);

	# for each input
	for my $i (0 .. $#{$in}) {
		
		# copy input values
		$ind = [@{$in}];
		
		# add input delta
		$ind->[$i] += $delta;
		
		# compute slope
		$jac->[$i] = (&$node($ind) - $out)/$delta;
		
	}

	# return Jacobian
	return($jac);

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
	my ($array, $code);

	# for each attribute
	for my $attr (keys(%{$hash})) {
		
		# if 'header'
		if ($attr eq 'header') {
			
			# if reference to hash
			if (ref($hash->{$attr}) eq 'HASH') {
				
				# set object element
				$self->[0] = {%{$hash->{$attr}}};
				
			} else {
				
				# wrong data type
				croak('nNET header attribute must be a hash reference');
				
			}
			
		# if 'kernel'
		} elsif ($attr eq 'kernel') {
			
			# if an array reference
			if (ref($hash->{$attr}) eq 'ARRAY') {
				
				# get array
				$array = $hash->{$attr};

				# for each array element
				for my $i (0 .. $#{$array}) {
					
					# if array element is a valid kernel type
					if (grep {ref($array->[$i]) eq $_} @types) {
						
						# add array element
						$self->[1][$i] = $array->[$i];
						
					} else {
						
						# wrong data type
						croak('invalid nNET kernel array element');
						
					}
					
				}
				
			} else {
				
				# wrong data type
				croak('nNET kernel attribute must be an array reference');
				
			}
			
		# if 'matrix'
		} elsif ($attr eq 'matrix') {
			
			# if reference to 2D array
			if (ref($hash->{$attr}) eq 'ARRAY' && ref($hash->{$attr}[0]) eq 'ARRAY') {
				
				# set object element
				$self->[2] = Storable::dclone($hash->{$attr});
				
			# if reference to Math::Matrix object
			} elsif (UNIVERSAL::isa($hash->{$attr}, 'Math::Matrix')) {
				
				# set object element
				$self->[2] = Storable::dclone([@{$hash->{$attr}}]);
				
			} else {
				
				# wrong data type
				croak('nNET matrix attribute must be a 2-D array reference or Math::Matrix object');
				
			}
			
		# if 'offset'
		} elsif ($attr eq 'offset') {
			
			# if reference to an array of scalars
			if (ref($hash->{$attr}) eq 'ARRAY' && @{$hash->{$attr}} == grep {! ref()} @{$hash->{$attr}}) {
				
				# set object element
				$self->[3] = [@{$hash->{$attr}}];
				
			} else {
				
				# wrong data type
				croak('nNET offset attribute must be an array reference');
				
			}
			
		# if 'init'
		} elsif ($attr eq 'init') {
			
			# if a CODE reference
			if (ref($hash->{$attr}) eq 'CODE') {
				
				# set object element
				$self->[0]{'init'} = $hash->{$attr};
				
			} else {
				
				# wrong data type
				croak('nNET init attribute must be a CODE reference');
				
			}
			
		}
		
	}
	
}

1;