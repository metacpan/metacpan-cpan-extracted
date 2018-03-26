package ICC::Profile::mAB_;

use strict;
use Carp;

our $VERSION = 2.51;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# use POSIX math
use POSIX ();

# create new mAB_ object
# hash may contain pointers to B-curves, matrix, M-curves, CLUT, or A-curves
# keys are: ('b_curves', 'matrix', 'm_curves', 'clut', 'a_curves')
# tag elements not specified in the hash are left empty
# parameters: ()
# parameters: (ref_to_attribute_hash)
# parameters: (ref_to_matrix-based_profile_object)
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty mAB_ object
	my $self = [
		{},     # object header
		[],     # processing elements
		0x00,   # transform mask
		0x00    # clipping mask
	];

	# if there are parameters
	if (@_) {
		
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
			
			# make new mAB_ tag from attribute hash
			_new_from_hash($self, @_);
			
		# if one parameter, an ICC::Profile object
		} elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'ICC::Profile')) {

			# make new mAB_ tag from ICC::Profile object
			_newICCmatrix($self, @_);

		} else {
			
			# error
			croak('parameter must be a hash reference or a display matrix profile');
			
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
			$self->[0] = shift();
			
		} else {
			
			# error
			croak('parameter must be a hash reference');
			
		}
		
	}

	# return reference
	return($self->[0]);

}

# get/set processing element array reference
# parameters: ([ref_to_array])
# returns: (ref_to_array)
sub array {

	# get object reference
	my $self = shift();

	# if parameter
	if (@_) {
		
		# verify array reference
		(ref($_[0]) eq 'ARRAY') || croak('not an array reference');
		
		# set array reference
		$self->[1] = [@{shift()}];
		
	}

	# return array reference
	return($self->[1]);

}

# get/set reference to B-curves 'cvst' object
# parameters: ([ref_to_new_object])
# returns: (ref_to_object)
sub b_curves {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 'cvst' object
		if (@_ == 1 && UNIVERSAL::isa($_[0], 'ICC::Profile::cvst')) {
			
			# set B-curves to new object
			$self->[1][0] = shift();
			
			# set transform mask bit
			$self->[2] |= 0x01;
			
		} else {
			
			# error
			croak('parameter must be a \'cvst\' object');
			
		}
		
	}

	# return object reference
	return($self->[1][0]);

}

# get/set reference to matrix 'matf' object
# parameters: ([ref_to_new_object])
# returns: (ref_to_object)
sub matrix {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, an 'matf' object
		if (@_ == 1 && UNIVERSAL::isa($_[0], 'ICC::Profile::matf')) {
			
			# set matrix to new object
			$self->[1][1] = shift();
			
			# set transform mask bit
			$self->[2] |= 0x02;
			
		} else {
			
			# error
			croak('parameter must be an \'matf\' object');
			
		}
		
	}

	# return object reference
	return($self->[1][1]);

}

# get/set reference to M-curves 'cvst' object
# parameters: ([ref_to_new_object])
# returns: (ref_to_object)
sub m_curves {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 'cvst' object
		if (@_ == 1 && UNIVERSAL::isa($_[0], 'ICC::Profile::cvst')) {
			
			# set M-curves to new object
			$self->[1][2] = shift();
			
			# set transform mask bit
			$self->[2] |= 0x04;
			
		} else {
			
			# error
			croak('parameter must be a \'cvst\' object');
			
		}
		
	}

	# return object reference
	return($self->[1][2]);

}

# get/set reference to CLUT 'clut' object
# parameters: ([ref_to_new_object])
# returns: (ref_to_object)
sub clut {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 'clut' object
		if (@_ == 1 && UNIVERSAL::isa($_[0], 'ICC::Profile::clut')) {
			
			# set CLUT to new object
			$self->[1][3] = shift();
			
			# set transform mask bit
			$self->[2] |= 0x08;
			
		} else {
			
			# error
			croak('parameter must be a \'clut\' object');
			
		}
		
	}

	# return object reference
	return($self->[1][3]);

}

# get/set reference to A-curves 'cvst' object
# parameters: ([ref_to_new_object])
# returns: (ref_to_object)
sub a_curves {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 'cvst' object
		if (@_ == 1 && UNIVERSAL::isa($_[0], 'ICC::Profile::cvst')) {
			
			# set A-curves to new object
			$self->[1][4] = shift();
			
			# set transform mask bit
			$self->[2] |= 0x10;
			
		} else {
			
			# error
			croak('parameter must be a \'cvst\' object');
			
		}
		
	}

	# return object reference
	return($self->[1][4]);

}

# get/set transform mask
# bits 4-3-2-1-0 correpsond to A-CLUT-M-MATRIX-B
# parameters: ([new_mask_value])
# returns: (mask_value)
sub mask {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter
		if (@_ == 1) {
			
			# set object transform mask value
			$self->[2] = shift();
			
		} else {
			
			# error
			croak('more than one parameter');
			
		}
		
	}

	# return transform mask value
	return($self->[2]);

}

# get/set clipping mask
# bits 4-3-2-1-0 correpsond to A-CLUT-M-MATRIX-B
# parameters: ([new_mask_value])
# returns: (mask_value)
sub clip {
	
	# get object reference
	my $self = shift();
	
	# if there are parameters
	if (@_) {
		
		# if one parameter
		if (@_ == 1) {
			
			# set object clipping mask value
			$self->[3] = shift();
			
		} else {
			
			# error
			croak('more than one parameter');
			
		}
		
	}
	
	# return clipping mask value
	return($self->[3]);
	
}

# create mAB_ tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty mAB_ object
	my $self = [
		{},     # object header
		[],     # processing elements
		0x00,   # transform mask
		0x00    # clipping mask
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read mAB_ data from profile
	_readICCmAB_($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes mAB_ tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write mAB_ data to profile
	_writeICCmAB_($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_clut_size)
sub size {

	# get parameters
	my ($self) = @_;

	# local variables
	my ($size);

	# set header size
	$size = 32;

	# for each B-curve
	for my $curve (@{$self->[1][0]->array()}) {
		
		# add curve size
		$size += $curve->size;
		
		# pad to 4-bytes
		$size += (-$size % 4);
		
	}

	# if matrix defined
	if (defined($self->[1][1])) {
		
		# add matrix size (48 bytes)
		$size += 48;
		
	}

	# if M-curves defined
	if (defined($self->[1][2])) {
		
		# for each M-curve
		for my $curve (@{$self->[1][2]->array()}) {
			
			# add curve size
			$size += $curve->size;
			
			# pad to 4-bytes
			$size += (-$size % 4);
			
		}
	
	}

	# if CLUT defined
	if (defined($self->[1][3])) {
		
		# add CLUT size (nCLUT object)
		$size += 20 + $self->[1][3]->_clut_size($self->[1][3][0]{'clut_bytes'} || 2);
		
		# pad to 4-byte boundary
		$size += (-$size % 4);
		
	}

	# if A-curves defined
	if (defined($self->[1][4])) {
		
		# for each A-curve
		for my $curve (@{$self->[1][4]->array()}) {
			
			# add curve size
			$size += $curve->size;
			
			# pad to 4-bytes
			$size += (-$size % 4);
			
		}
	
	}

	# return size
	return($size);

}

# get number of input channels
# returns: (number)
sub cin {

	# get object reference
	my $self = shift();

	# return
	return($self->[1][-1]->cin());

}

# get number of output channels
# returns: (number)
sub cout {

	# get object reference
	my $self = shift();

	# return
	return($self->[1][0]->cout());

}

# transform data
# transform mask enables/disables individual tag elements
# clipping mask enables/disables individual tag output clipping
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
# transform mask enables/disables individual tag elements
# parameters: (input_vector, [hash])
# returns: (Jacobian_matrix, [output_vector])
sub jacobian {

	# get parameters
	my ($self, $data, $hash) = @_;

	# local variables
	my ($jac, $jaci);

	# for each processing element (note: sequence is from the last element to the first)
		for my $i (reverse(0 .. $#{$self->[1]})) {
		
		# if processing element defined, and transform mask bit set
		if (defined($self->[1][$i]) && $self->[2] & 0x01 << $i) {
			
			# compute Jacobian matrix and transform data
			($jaci, $data) = $self->[1][$i]->jacobian($data, $hash);
			
			# multiply Jacobian matrices
			$jac = defined($jac) ? $jaci * $jac : $jaci;
			
		}
		
	}

	# if Jacobian matrix is undefined, use identity matrix
	$jac = Math::Matrix->diagonal((1) x @{$data}) if (! defined($jac));

	# if output values wanted
	if (wantarray) {
		
		# return Jacobian and output values
		return($jac, $data);
		
	} else {
		
		# return Jacobian only
		return($jac);
		
	}
	
}

# get/set PCS encoding
# for use with ICC::Support::PCS objects
# parameters: ([PCS_encoding])
# returns: (PCS_encoding)
sub pcs {

	# get parameters
	my ($self, $pcs) = @_;

	# if PCS parameter is supplied
	if (defined($pcs)) {
		
		# if a valid PCS encoding
		if (grep {$pcs == $_} (3, 8)) {
			
			# copy to tag header hash
			$self->[0]{'pcs_encoding'} = $pcs;
			
			# return PCS encoding
			return($pcs);
			
		} else {
			
			# error
			croak('invalid PCS encoding');
			
		}
		
	} else {
		
		# if PCS is defined in tag header
		if (defined($self->[0]{'pcs_encoding'})) {
			
			# return PCS encoding
			return($self->[0]{'pcs_encoding'});
			
		} else {
			
			# error
			croak('can\'t determine PCS encoding');
			
		}
		
	}
	
}

# get/set white point
# parameters: ([white_point])
# returns: (white_point)
sub wtpt {

	# get parameters
	my ($self, $wtpt) = @_;

	# if white point parameter is supplied
	if (defined($wtpt)) {
		
		# if an array of three scalars
		if (@{$wtpt} == 3 && 3 == grep {! ref()} @{$wtpt}) {
			
			# copy to tag header hash
			$self->[0]{'wtpt'} = $wtpt;
			
			# return white point
			return($wtpt);
			
		} else {
			
			# error
			croak('invalid white point');
			
		}
		
	} else {
		
		# if white point is defined in tag header
		if (defined($self->[0]{'wtpt'})) {
			
			# return return white point
			return($self->[0]{'wtpt'});
			
		} else {
			
			# error
			croak('can\'t determine white point');
			
		}
		
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
	my ($element, $fmt, $s, $pt, $st);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 's';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# if format contains 'o'
	if ($fmt =~ m/s/) {
		
		# get default parameter
		$pt = $p->[-1];
		
		# for each processing element
		for my $i (0 .. $#{$self->[1]}) {
			
			# get element reference
			$element = $self->[1][$i];
			
			# if processing element is undefined
			if (! defined($element)) {
				
				# append message
				$s .= "\tprocessing element is undefined\n";
				
			# if processing element is not a blessed object
			} elsif (! Scalar::Util::blessed($element)) {
				
				# append message
				$s .= "\tprocessing element is not a blessed object\n";
				
			# if processing element has an 'sdump' method
			} elsif ($element->can('sdump')) {
				
				# get 'sdump' string
				$st = $element->sdump(defined($p->[$i + 1]) ? $p->[$i + 1] : $pt);
				
				# prepend tabs to each line
				$st =~ s/^/\t/mg;
				
				# append 'sdump' string
				$s .= $st;
				
			# processing element is object without an 'sdump' method
			} else {
				
				# append object info
				$s .= sprintf("\t'%s' object, (0x%x)\n", ref($element), $element);
				
			}
			
		}
		
	}

	# return
	return($s);

}

# transform list
# parameters: (object_reference, list, [hash])
# returns: (list)
sub _trans0 {

	# local variables
	my ($self, $hash, $data);

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# process data
	$data = _trans1($self, [@_], $hash);

	# return list
	return(@{$data});

}

# transform vector
# parameters: (object_reference, vector, [hash])
# returns: (vector)
sub _trans1 {

	# get parameters
	my ($self, $data, $hash) = @_;

	# for each processing element (note: sequence is from the last element to the first)
	for my $i (reverse(0 .. $#{$self->[1]})) {
		
		# if processing element defined, and transform mask bit set
		if (defined($self->[1][$i]) && $self->[2] & 0x01 << $i) {
			
			# transform data
			$data = $self->[1][$i]->_trans1($data, $hash);
			
			# clip output values if clipping mask bit set
			ICC::Shared::clip_struct($data) if ($self->[3] & 0x01 << $i);
			
		}
		
	}
	
	# return
	return($data);
	
}

# transform matrix (2-D array -or- Math::Matrix object)
# parameters: (object_reference, matrix, [hash])
# returns: (matrix)
sub _trans2 {

	# get parameters
	my ($self, $data, $hash) = @_;

	# for each processing element (note: sequence is from the last element to the first)
	for my $i (reverse(0 .. $#{$self->[1]})) {
		
		# if processing element defined, and transform mask bit set
		if (defined($self->[1][$i]) && $self->[2] & 0x01 << $i) {
			
			# transform data
			$data = $self->[1][$i]->_trans2($data, $hash);
			
			# clip output values if clipping mask bit set
			ICC::Shared::clip_struct($data) if ($self->[3] & 0x01 << $i);
			
		}
		
	}

	# return
	return($data);

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

# check object structure
# parameter: (ref_to_object)
# returns: (number_input_channels, number_output_channels)
sub _check {

	# get object reference
	my $self = shift();

	# local variables
	my (@class, $ci, $co);

	# make object class array
	@class = qw(ICC::Profile::cvst ICC::Profile::matf ICC::Profile::cvst ICC::Profile::clut ICC::Profile::cvst);

	# verify number of processing elements
	($#{$self->[1]} <= 4) || croak('\'mAB_\' object has too many processing elements');

	# for each processing element (note: sequence is from the last element to the first)
	for my $i (reverse(0 .. $#{$self->[1]})) {
		
		# if element is defined (matrix and M-curves to may be undefined)
		if (defined($self->[1][$i])) {
			
			# verify element has correct class
			(ref($self->[1][$i]) eq $class[$i]) || croak("'mAB_' processing element $i has wrong class");
			
			# if element has 'cin' method
			if ($self->[1][$i]->can('cin')) {
				
				# if number of input channels is undefined
				if (! defined($ci)) {
					
					# set number of input channels
					$ci = $self->[1][$i]->cin();
					
				}
				
				# if number of output channels is defined
				if (defined($co)) {
					
					# verify input channels of this element match output channels of previous element
					($self->[1][$i]->cin() == $co) || croak("'mAB_' processing element $i has wrong number of channels");
					
				}
				
			}
			
			# if element has 'cout' method
			if ($self->[1][$i]->can('cout')) {
				
				# set number of output channels
				$co = $self->[1][$i]->cout();
				
			}
			
		}
		
	}

	# verify B-curves are defined
	(defined($self->[1][0])) || croak('B-curves are required');

	# verify matrix and M-curves are both defined, or neither
	(defined($self->[1][1]) xor defined($self->[1][2])) && croak('matrix and M-curves must both be defined, or neither');

	# verify CLUT and A-curves are both defined, or neither
	(defined($self->[1][3]) xor defined($self->[1][4])) && croak('CLUT and A-curves must both be defined, or neither');

	# if matrix defined
	if (defined($self->[1][1])) {
		
		# verify object has 3 output channels
		($co == 3) || croak("matrix processing element not permitted with $co output channels");
		
		# verify matrix size (3x3)
		($self->[1][1]->cin() == 3 && $self->[1][1]->cout() == 3) || croak('matrix processing element matrix wrong size');
		
		# verify offset size (undefined, 0 or 3)
		(! defined($self->[1][1][2]) || @{$self->[1][1][2]} == 0 || @{$self->[1][1][2]} == 3) || croak('matrix processing element offset wrong size');
		
	}

	# return
	return($ci, $co);

}

# set M-curves, matrix, and B-curves
# equivalent to a matrix-based display profile
# parameters: (ref_to_object, ref_to_profile_object)
sub _newICCmatrix {

	# get parameters
	my ($self, $disp) = @_;

	# local variables
	my (@XYZ, @TRC, $wtpt, $bkpt, $id, $mat);

	# verify an RGB/XYZ display profile
	(UNIVERSAL::isa($disp, 'ICC::Profile') && $disp->profile_header->[3] eq 'mntr' && $disp->profile_header->[4] eq 'RGB ' && $disp->profile_header->[5] eq 'XYZ ') || croak('not an RGB-XYZ display profile');

	# get primary tags
	@XYZ = $disp->tag(qw(rXYZ gXYZ bXYZ));

	# get TRC tags
	@TRC = $disp->tag(qw(rTRC gTRC bTRC));

	# verify a matrix profile
	(@XYZ == 3 && @TRC == 3) || croak('not a matrix profile');

	# set input colorspace
	$self->[0]{'input_cs'} = 'RGB ';

	# set output colorspace
	$self->[0]{'output_cs'} = 'XYZ ';

	# set PCS encoding
	$self->[0]{'pcs_encoding'} = 7;

	# get white point tag
	$wtpt = $disp->tag('wtpt');

	# set white point value
	$self->[0]{'wtpt'} = [@{$wtpt->XYZ}] if (defined($wtpt));

	# get black point tag
	$bkpt = $disp->tag('bkpt');

	# set black point value
	$self->[0]{'bkpt'} = [@{$bkpt->XYZ}] if (defined($bkpt));

	# make identity curve
	$id = ICC::Profile::curv->new();

	# make Math::Matrix object from primary tags
	$mat = Math::Matrix->new(map {$_->XYZ()} @XYZ)->transpose->multiply_scalar(32768/65535);

	# set B-curves
	$self->[1][0] = ICC::Profile::cvst->new([$id, $id, $id]);

	# set matrix
	$self->[1][1] = ICC::Profile::matf->new({'matrix' => $mat});

	# set M-curves
	$self->[1][2] = ICC::Profile::cvst->new(Storable::dclone(\@TRC));

	# set transform mask
	$self->[2] = 0x07;

}

# make new mAB_ tag from attribute hash
# hash may contain pointers to B-curves, matrix, M-curves, CLUT, or A-curves
# keys are: ('b_curves', 'matrix', 'm_curves', 'clut', 'a_curves')
# tag elements not specified in the hash are left empty
# parameters: (ref_to_object, ref_to_attribute_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# set attribute list (key => [reference_type, array_index])
	my %list = ('b_curves' => ['ICC::Profile::cvst', 0], 'matrix' => ['ICC::Profile::matf', 1], 'm_curves' => ['ICC::Profile::cvst', 2], 'clut' => ['ICC::Profile::clut', 3], 'a_curves' => ['ICC::Profile::cvst', 4]);

	# for each attribute
	for my $attr (keys(%{$hash})) {
		
		# if value defined
		if (defined($hash->{$attr})) {
			
			# if correct reference type
			if (ref($hash->{$attr}) eq $list{$attr}[0]) {
				
				# set tag element
				$self->[1][$list{$attr}[1]] = $hash->{$attr};
				
				# set transform mask bit
				$self->[2] |= (0x01 << $list{$attr}[1]);
				
			} else {
				
				# error
				croak("wrong object type for $attr key");
				
			}
			
		}
		
	}
	
}

# read mAB_ tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCmAB_ {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, @mft, $pel, $mark, @mat, $bytes, $gsa);

	# set tag signature
	$self->[0]{'signature'} = $tag->[0];

	# set input colorspace
	$self->[0]{'input_cs'} = $parent->[1][4];

	# set output colorspace
	$self->[0]{'output_cs'} = $parent->[1][5];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag header
	read($fh, $buf, 32);

	# unpack header
	@mft = unpack('a4 x4 C2 x2 N5', $buf);
	
	# verify tag signature
	($mft[0] eq 'mAB ') or croak('wrong tag type');

	# verify number input channels (1 to 15)
	($mft[1] > 0 && $mft[1] < 16) || croak('unsupported number of input channels');

	# verify number output channels (1 to 15)
	($mft[2] > 0 && $mft[2] < 16) || croak('unsupported number of output channels');

	# if B-curves are defined
	if ($mft[3]) {
		
		# make 'cvst' object for B-curves
		$pel = ICC::Profile::cvst->new();
		
		# set file pointer to start of first B-curve
		$mark = $tag->[1] + $mft[3];
		
		# for each output channel
		for my $i (0 .. $mft[2] - 1) {
			
			# adjust file pointer to 4-byte boundary
			$mark += (-$mark % 4);
			
			# seek to start of curve
			seek($fh, $mark, 0);
			
			# read curve type
			read($fh, $buf, 4);
			
			# if 'curv' type
			if ($buf eq 'curv') {
				
				# parse 'curv' object
				$pel->[1][$i] = ICC::Profile::curv->new_fh($self, $fh, ['cvst', $mark, 0, 0]);
				
			} elsif ($buf eq 'para') {
				
				# parse 'para' object
				$pel->[1][$i] = ICC::Profile::para->new_fh($self, $fh, ['cvst', $mark, 0, 0]);
				
			} else {
				
				# error
				croak('unsupported curve type or invalid tag structure');
				
			}
			
			# mark current file pointer location
			$mark = tell($fh);
			
		}
		
		# set signature
		$pel->[0]{'signature'} = 'mAB_';
		
		# add processing element
		$self->[1][0] = $pel;
		
		# set transform mask
		$self->[2] |= 0x01;
		
	}

	# if matrix is defined
	if ($mft[4]) {
		
		# make 'matf' object for matrix
		$pel = ICC::Profile::matf->new();
		
		# seek to start of matrix
		seek($fh, $tag->[1] + $mft[4], 0);
		
		# read matrix
		$pel->_read_matf($fh, 3, 3, 1, 2);
		
		# set signature
		$pel->[0]{'signature'} = 'mAB_';
		
		# add processing element
		$self->[1][1] = $pel;
		
		# set transform mask
		$self->[2] |= 0x02;
		
	}

	# if M-curves are defined
	if ($mft[5]) {
		
		# make 'cvst' object for M-curves
		$pel = ICC::Profile::cvst->new();
		
		# set file pointer to start of first M-curve
		$mark = $tag->[1] + $mft[5];
		
		# for each output channel
		for my $i (0 .. $mft[2] - 1) {
			
			# adjust file pointer to 4-byte boundary
			$mark += (-$mark % 4);
			
			# seek to start of curve
			seek($fh, $mark, 0);
			
			# read curve type
			read($fh, $buf, 4);
			
			# if 'curv' type
			if ($buf eq 'curv') {
				
				# parse 'curv' object
				$pel->[1][$i] = ICC::Profile::curv->new_fh($self, $fh, ['cvst', $mark, 0, 0]);
				
			} elsif ($buf eq 'para') {
				
				# parse 'para' object
				$pel->[1][$i] = ICC::Profile::para->new_fh($self, $fh, ['cvst', $mark, 0, 0]);
				
			} else {
				
				# error
				croak('unsupported curve type or invalid tag structure');
				
			}
			
			# mark current file pointer location
			$mark = tell($fh);
			
		}
		
		# set signature
		$pel->[0]{'signature'} = 'mAB_';
		
		# add processing element
		$self->[1][2] = $pel;
		
		# set transform mask
		$self->[2] |= 0x04;
		
	}

	# if CLUT defined
	if ($mft[6]) {
		
		# make 'clut' object for CLUT
		$pel = ICC::Profile::clut->new();
		
		# seek to start of CLUT
		seek($fh, $tag->[1] + $mft[6], 0);
		
		# read header
		read($fh, $buf, 20);
		
		# unpack header
		@mat = unpack('C17', $buf);
		
		# get CLUT byte width
		$bytes = pop(@mat);
		
		# save CLUT byte width
		$pel->[0]{'clut_bytes'} = $bytes;
		
		# set number of input channels
		$pel->[0]{'input_channels'} = $mft[1];

		# set number of output channels
		$pel->[0]{'output_channels'} = $mft[2];

		# make grid size array
		$gsa = [grep {$_} @mat];
		
		# read 'clut' data
		$pel->_read_clut($fh, $mft[2], $gsa, $bytes);
		
		# save grid size array
		$pel->[2] = [@{$gsa}];
		
		# set signature
		$pel->[0]{'signature'} = 'mAB_';
		
		# add processing element
		$self->[1][3] = $pel;
		
		# set transform mask
		$self->[2] |= 0x08;
		
	}

	# if A-curves are defined
	if ($mft[7]) {
		
		# make 'cvst' object for A-curves
		$pel = ICC::Profile::cvst->new();
		
		# set file pointer to start of first A-curve
		$mark = $tag->[1] + $mft[7];
		
		# for each input channel
		for my $i (0 .. $mft[1] - 1) {
			
			# adjust file pointer to 4-byte boundary
			$mark += (-$mark % 4);
			
			# seek to start of curve
			seek($fh, $mark, 0);
			
			# read curve type
			read($fh, $buf, 4);
			
			# if 'curv' type
			if ($buf eq 'curv') {
				
				# parse 'curv' object
				$pel->[1][$i] = ICC::Profile::curv->new_fh($self, $fh, ['cvst', $mark, 0, 0]);
				
			} elsif ($buf eq 'para') {
				
				# parse 'para' object
				$pel->[1][$i] = ICC::Profile::para->new_fh($self, $fh, ['cvst', $mark, 0, 0]);
				
			} else {
				
				# error
				croak('unsupported curve type or invalid tag structure');
				
			}
			
			# mark current file pointer location
			$mark = tell($fh);
			
		}
		
		# set signature
		$pel->[0]{'signature'} = 'mAB_';
		
		# add processing element
		$self->[1][4] = $pel;
		
		# set transform mask
		$self->[2] |= 0x10;
		
	}

}

# write mAB_ tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCmAB_ {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my (@mft, $offset, @mat, $bytes, $size);

	# set tag type
	$mft[0] = 'mAB ';

	# check object structure
	@mft[1, 2] = _check($self);

	# initialize offset
	$offset = 32;

	# set offset to B-curves
	$mft[3] = 32;

	# if B-curves defined
	if (defined($self->[1][0])) {
		
		# for each B-curve
		for my $curve (@{$self->[1][0]->array()}) {
			
			# add curve size
			$offset += $curve->size;
			
			# pad to 4-bytes
			$offset += (-$offset % 4);
			
		}
		
	} else {
		
		# error
		croak('B-curves are required');
		
	}

	# if matrix is defined
	if (defined($self->[1][1])) {
		
		# verify output channels
		($mft[2] == 3) || croak('3 output channels required for matrix');
		
		# set offset
		$mft[4] = $offset;
		
		# increment offset for matrix size
		$offset += 48;
		
	} else {
		
		# set offset
		$mft[4] = 0;
		
	}

	# if M-curves defined
	if (defined($self->[1][2])) {
		
		# verify output channels
		($mft[2] == 3) || croak('3 output channels required for M-curves');
		
		# set offset
		$mft[5] = $offset;
		
		# for each M-curve
		for my $curve (@{$self->[1][2]->array()}) {
			
			# add curve size
			$offset += $curve->size;
			
			# pad to 4-bytes
			$offset += (-$offset % 4);
			
		}
		
	} else {
		
		# set offset
		$mft[5] = 0;
		
	}

	# if CLUT defined
	if (defined($self->[1][3])) {
		
		# set offset
		$mft[6] = $offset;
		
		# get CLUT data size
		$bytes = $self->[1][3][0]{'clut_bytes'} || 2;
		
		# add CLUT size to offset
		$offset += 20 + $self->[1][3]->_clut_size($bytes);
		
		# pad to 4-byte boundary
		$offset += (-$offset % 4);
		
	} else {
		
		# set offset
		$mft[6] = 0;
		
	}

	# if A-curves defined
	if (defined($self->[1][4])) {
		
		# set offset
		$mft[7] = $offset;
		
	} else {
		
		# set offset
		$mft[7] = 0;
		
	}

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write header
	print $fh pack('a4 x4 C2 x2 N5', @mft);

	# seek start of B-curves
	seek($fh, $tag->[1] + $mft[3], 0);

	# for each B-curve
	for my $curve (@{$self->[1][0]->array()}) {
		
		# write curve object
		$curve->write_fh($self->[1][0], $fh, ['cvst', tell($fh), 0, 0]);
		
		# add padding to 4-byte boundary
		seek($fh, (-tell($fh) % 4), 1);
		
	}

	# if matrix is defined
	if (defined($self->[1][1])) {
		
		# seek start of matrix
		seek($fh, $tag->[1] + $mft[4], 0);
		
		# write matrix
		$self->[1][1]->_write_matf($fh, 1, 2);
		
	}

	# if M-curves are defined
	if (defined($self->[1][2])) {
		
		# seek start of M-curves
		seek($fh, $tag->[1] + $mft[5], 0);
		
		# for each M-curve
		for my $curve (@{$self->[1][2]->array()}) {
			
			# write curve object
			$curve->write_fh($self->[1][2], $fh, ['cvst', tell($fh), 0, 0]);
			
			# add padding to 4-byte boundary
			seek($fh, (-tell($fh) % 4), 1);
			
		}
		
	}

	# if CLUT is defined
	if (defined($self->[1][3])) {
		
		# for each possible input channel
		for my $i (0 .. 15) {
			
			# set grid size
			$mat[$i] = $self->[1][3]->gsa->[$i] || 0;
			
		}
		
		# set CLUT byte width
		$mat[16] = $bytes;
		
		# seek start of CLUT
		seek($fh, $tag->[1] + $mft[6], 0);
		
		# write CLUT header
		print $fh pack('C17 x3', @mat);
		
		# write CLUT
		$self->[1][3]->_write_clut($fh, $self->[1][3]->gsa(), $bytes);
		
	}

	# if A-curves are defined
	if (defined($self->[1][4])) {
		
		# seek start of A-curves
		seek($fh, $tag->[1] + $mft[7], 0);
		
		# for each M-curve
		for my $curve (@{$self->[1][4]->array()}) {
			
			# write curve object
			$curve->write_fh($self->[1][4], $fh, ['cvst', tell($fh), 0, 0]);
			
			# add padding to 4-byte boundary
			seek($fh, (-tell($fh) % 4), 1);
			
		}
		
	}
	
}

1;
