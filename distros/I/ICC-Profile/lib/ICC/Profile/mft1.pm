package ICC::Profile::mft1;

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

# create new mft1 object
# hash may contain pointers to matrix, input curves, CLUT, or output curves
# keys are: ('matrix', 'input', 'clut', 'output')
# tag elements not specified in the hash are left empty
# parameters: ([ref_to_attribute_hash])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty mft1 object
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
			
			# make new mft1 tag from attribute hash
			_new_from_hash($self, @_);
			
		} else {
			
			# error
			croak('parameter must be a hash reference');
			
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
			
			# warn if 'matf' object has offset values
			(@{$_[0]->offset()}) || carp('offset values in matrix object are not supported');
			
			# set matrix to new object
			$self->[1][0] = shift();
			
			# set transform mask bit
			$self->[2] |= 0x01;
			
		} else {
			
			# error
			croak('parameter must be an \'matf\' object');
			
		}
		
	}

	# return object reference
	return($self->[1][0]);

}

# get/set reference to input curves 'cvst' object
# parameters: ([ref_to_new_object])
# returns: (ref_to_object)
sub input {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 'cvst' object
		if (@_ == 1 && UNIVERSAL::isa($_[0], 'ICC::Profile::cvst')) {
			
			# set input curves to new object
			$self->[1][1] = shift();
			
			# set transform mask bit
			$self->[2] |= 0x02;
			
		} else {
			
			# error
			croak('parameter must be a \'cvst\' object');
			
		}
		
	}

	# return object reference
	return($self->[1][1]);

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
			$self->[1][2] = shift();
			
			# set transform mask bit
			$self->[2] |= 0x04;
			
		} else {
			
			# error
			croak('parameter must be a \'clut\' object');
			
		}
		
	}

	# return object reference
	return($self->[1][2]);

}

# get/set reference to output curves 'cvst' object
# parameters: ([ref_to_new_object])
# returns: (ref_to_object)
sub output {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, a 'cvst' object
		if (@_ == 1 && UNIVERSAL::isa($_[0], 'ICC::Profile::cvst')) {
			
			# set output curves to new object
			$self->[1][3] = shift();
			
			# set transform mask bit
			$self->[2] |= 0x08;
			
		} else {
			
			# error
			croak('parameter must be a \'cvst\' object');
			
		}
		
	}

	# return object reference
	return($self->[1][3]);

}

# get/set transform mask
# bits 3-2-1-0 correpsond to OUTPUT-CLUT-INPUT-MATRIX
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
# bits 3-2-1-0 correpsond to OUTPUT-CLUT-INPUT-MATRIX
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

# create mft1 tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty mft1 object
	my $self = [
		{},     # object header
		[],     # processing elements
		0x00,   # transform mask
		0x00    # clipping mask
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read mft1 data from profile
	_readICCmft1($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes mft1 tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write mft1 data to profile
	_writeICCmft1($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_clut_size)
sub size {

	# get parameters
	my ($self) = @_;

	# set header size
	my $size = 48;

	# add size of input tables (assumes 'curv' objects)
	$size += $self->[1][1]->cin() * 256;

	# add size of clut
	$size += $self->[1][2]->_clut_size(1);

	# add size of output tables (assumes 'curv' objects)
	$size += $self->[1][3]->cin() * 256;

	# return size
	return($size);

}

# get number of input channels
# returns: (number)
sub cin {

	# get object reference
	my $self = shift();

	# return
	return($self->[1][1]->cin());

}

# get number of output channels
# returns: (number)
sub cout {

	# get object reference
	my $self = shift();

	# return
	return($self->[1][3]->cout());

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

	# for each processing element
	for my $i (0 .. $#{$self->[1]}) {
		
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
		if ($pcs == 0) {
			
			# copy to tag header hash
			$self->[0]{'pcs_encoding'} = $pcs;
			
			# return PCS encoding
			return($pcs);
			
		} else {
			
			# error
			croak('invalid PCS encoding');
			
		}
		
	} else {
		
		# if tag PCS is L*a*b*
		if (($self->[0]{'input_cs'} eq 'Lab ' && $self->[0]{'output_cs'} ne 'XYZ ') || ($self->[0]{'input_cs'} ne 'XYZ ' && $self->[0]{'output_cs'} eq 'Lab ')) {
			
			# return PCS type (8-bit CIELab)
			return(0);
			
		# if tag PCS is XYZ
		} elsif (($self->[0]{'input_cs'} eq 'XYZ ' && $self->[0]{'output_cs'} ne 'Lab ') || ($self->[0]{'input_cs'} ne 'Lab ' && $self->[0]{'output_cs'} eq 'XYZ ')) {
			
			# error
			croak('invalid PCS encoding');
			
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

	# for each processing element
	for my $i (0 .. $#{$self->[1]}) {
		
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

	# for each processing element
	for my $i (0 .. $#{$self->[1]}) {
		
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
# returns: (number_input_channels, number_output_channels, grid_size)
sub _check {

	# get object reference
	my $self = shift();

	# local variables
	my (@class, $ci, $co, $gsa);

	# make object class array
	@class = qw(ICC::Profile::matf ICC::Profile::cvst ICC::Profile::clut ICC::Profile::cvst);

	# verify number of processing elements
	($#{$self->[1]} == 3) || croak('\'mft1\' object has wrong number of processing elements');

	# for each processing element
	for my $i (0 .. 3) {
		
		# if element is defined (matrix may be undefined)
		if (defined($self->[1][$i])) {
			
			# verify element has correct class
			(ref($self->[1][$i]) eq $class[$i]) || croak("'mft1' processing element $i is wrong object type");
			
			# if not matrix processing element
			if ($i) {
				
				# if number of input channels is undefined
				if (! defined($ci)) {
					
					# set number of input channels
					$ci = $self->[1][$i]->cin();
					
				}
				
				# if number of output channels is defined
				if (defined($co)) {
					
					# verify input channels of this element match output channels of previous element
					($self->[1][$i]->cin() == $co) || croak("'mft1' processing element $i has wrong number of input channels");
					
				}
				
				# set number of output channels
				$co = $self->[1][$i]->cout();
				
			} else {
				
				# verify matrix has 3 input and 3 output channels
				($self->[1][0]->cin() == 3 && $self->[1][0]->cout() == 3) || croak("'mft1' matrix processing element wrong size");
				
				# warn if matrix has non-zero offset values
				(defined($self->[1][0]->offset) && grep {$_} @{$self->[1][0]->offset}) && carp("'mft1' matrix processing element has non-zero offset values")
				
			}
			
		# if not matrix processing element
		} elsif ($i) {
			
			# error
			croak("'mft1' processing element $i is missing");
			
		}
		
	}

	# get 'clut' grid size array
	$gsa = $self->[1][2]->gsa();

	# verify 'clut' grid points are same for each channel
	(@{$gsa} == grep {$_ == $gsa->[0]} @{$gsa}) || croak("'mft1' clut processing element grid points vary by channel");

	# verify input 'cvst' elements are 'curv' objects
	(@{$self->[1][1]->array} == map {UNIVERSAL::isa($_, 'ICC::Profile::curv')} @{$self->[1][1]->array}) || croak("'mft1' input processing element has wrong curve type");

	# verify input 'curv' objects have 256 entries
	(@{$self->[1][1]->array} == grep {@{$_->array} == 256} @{$self->[1][1]->array}) || croak("'mft1' input processing element has wrong number of curve entries");

	# verify output 'cvst' elements are 'curv' objects
	(@{$self->[1][3]->array} == map {UNIVERSAL::isa($_, 'ICC::Profile::curv')} @{$self->[1][3]->array}) || croak("'mft1' output processing element has wrong curve type");

	# verify output 'curv' objects have 256 entries
	(@{$self->[1][3]->array} == grep {@{$_->array} == 256} @{$self->[1][3]->array}) || croak("'mft1' output processing element has wrong number of curve entries");

	# return
	return($ci, $co, $gsa->[0]);

}

# make new mft1 tag from attribute hash
# hash may contain pointers to matrix, input curves, CLUT, or output curves
# keys are: ('matrix', 'input', 'clut', 'output')
# tag elements not specified in the hash are left empty
# parameters: (ref_to_object, ref_to_attribute_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# set attribute list (key => [reference_type, array_index])
	my %list = ('matrix' => ['ICC::Profile::matf', 0], 'input' => ['ICC::Profile::cvst', 1], 'clut' => ['ICC::Profile::clut', 2], 'output' => ['ICC::Profile::cvst', 3]);

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

# read mft1 tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCmft1 {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, @mft, $input, $gsa, $output);

	# set tag signature
	$self->[0]{'signature'} = $tag->[0];

	# if 'A2Bx' tag
	if ($tag->[0] =~ m|^A2B[0-2]$|) {
		
		# set input colorspace
		$self->[0]{'input_cs'} = $parent->[1][4];
		
		# set output colorspace
		$self->[0]{'output_cs'} = $parent->[1][5];
		
	# if 'B2Ax' tag
	} elsif ($tag->[0] =~ m|^B2A[0-2]$|) {
		
		# set input colorspace
		$self->[0]{'input_cs'} = $parent->[1][5];
		
		# set output colorspace
		$self->[0]{'output_cs'} = $parent->[1][4];
		
	# if 'prex' tag
	} elsif ($tag->[0] =~ m|^pre[0-2]$|) {
		
		# set input colorspace
		$self->[0]{'input_cs'} = $parent->[1][5];
		
		# set output colorspace
		$self->[0]{'output_cs'} = $parent->[1][5];
		
	# if 'gamt' tag
	} elsif ($tag->[0] eq 'gamt') {
		
		# set input colorspace
		$self->[0]{'input_cs'} = $parent->[1][5];
		
		# set output colorspace
		$self->[0]{'output_cs'} = 'gamt';
		
	}

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag header
	read($fh, $buf, 12);

	# unpack header
	@mft = unpack('a4 x4 C3', $buf);

	# verify tag signature
	($mft[0] eq 'mft1') or croak('wrong tag type');

	# verify number input channels (1 to 15)
	($mft[1] > 0 && $mft[1] < 16) || croak('unsupported number of input channels');

	# verify number output channels (1 to 15)
	($mft[2] > 0 && $mft[2] < 16) || croak('unsupported number of output channels');

	# make 'matf' object for matrix
	$self->[1][0] = ICC::Profile::matf->new();

	# read matrix
	$self->[1][0]->_read_matf($fh, 3, 3, 0, 2);

	# set signature
	$self->[1][0][0]{'signature'} = 'mft1';

	# for each input curve
	for my $i (0 .. $mft[1] - 1) {
		
		# read curve values
		read($fh, $buf, 256);
		
		# make 'curv' object
		$input->[$i] = ICC::Profile::curv->new([map {$_/255} unpack('C*', $buf)]);
		
	}

	# make 'cvst' object for input curves
	$self->[1][1] = ICC::Profile::cvst->new($input);

	# set signature
	$self->[1][1][0]{'signature'} = 'mft1';

	# make gsa array
	$gsa = [($mft[3]) x $mft[1]];

	# make 'clut' object for CLUT
	$self->[1][2] = ICC::Profile::clut->new();

	# read 'clut' data
	$self->[1][2]->_read_clut($fh, $mft[2], $gsa, 1);
	
	# save 'clut' gsa
	$self->[1][2][2] = $gsa;

	# save CLUT byte width
	$self->[1][2][0]{'clut_bytes'} = 1;

	# set number of input channels
	$self->[1][2][0]{'input_channels'} = $mft[1];

	# set number of output channels
	$self->[1][2][0]{'output_channels'} = $mft[2];

	# set signature
	$self->[1][2][0]{'signature'} = 'mft1';

	# for each output curve
	for my $i (0 .. $mft[2] - 1) {
		
		# read curve values
		read($fh, $buf, 256);
		
		# make 'curv' object
		$output->[$i] = ICC::Profile::curv->new([map {$_/255} unpack('C*', $buf)]);
		
	}

	# make 'cvst' object for output curves
	$self->[1][3] = ICC::Profile::cvst->new($output);

	# set signature
	$self->[1][3][0]{'signature'} = 'mft1';

	# set transform mask (enabling matrix if input colorspace is XYZ)
	$self->[2] = $self->[0]{'input_cs'} eq 'XYZ ' ? 0x0F : 0x0E;

}

# write mft1 tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCmft1 {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my (@mft, $offset, $mat, $bytes, $size);
	my (@mat);

	# set tag type
	$mft[0] = 'mft1';

	# check object structure
	@mft[1, 2, 3] = _check($self);

	# if 'matf' object is defined
	if (defined($self->[1][0])) {
		
		# get matrix
		$mat = $self->[1][0]->matrix();
		
		# copy matrix values
		@mft[4 .. 12] = ICC::Shared::v2s15f16(@{$mat->[0]}, @{$mat->[1]}, @{$mat->[2]});

		
	} else {
		
		# copy identity matrix
		@mft[4 .. 12] = (65536, 0, 0, 0, 65536, 0, 0, 0, 65536);
		
	}

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write mft tag header
	print $fh pack('a4 x4 C3 x N9', @mft);

	# for each input channel
	for my $i (0 .. $mft[1] - 1) {
		
		# write table values
		print $fh pack('C*', map {$_ < 0 ? 0 : ($_ > 1 ? 255 : $_ * 255 + 0.5)} @{$self->[1][1]->array->[$i]->array});
		
	}

	# write clut
	$self->[1][2]->_write_clut($fh, $self->[1][2]->gsa(), 1);

	# for each output channel
	for my $i (0 .. $mft[2] - 1) {
		
		# write table values
		print $fh pack('C*', map {$_ < 0 ? 0 : ($_ > 1 ? 255 : $_ * 255 + 0.5)} @{$self->[1][3]->array->[$i]->array});
		
	}
	
}

1;