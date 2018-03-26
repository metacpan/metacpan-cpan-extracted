package ICC::Profile::matf;

use strict;
use Carp;

our $VERSION = 0.33;

# revised 2016-12-03
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# enable static variables
use feature 'state';

# create new matf object
# hash keys are: ('header', 'matrix', 'offset')
# 'header' value is a hash reference
# 'matrix' value is a 2D array reference -or- Math::Matrix object -or- positive integer
# 'offset' value is a 1D array reference -or- numeric value
# when the 'matrix' value is a positive integer, an identity matrix of that size is created
# when the 'offset' value is a numeric value, an array containing that value is created
# when the parameters are input and output arrays, the 'fit' method is called on the object
# parameters: ([ref_to_attribute_hash])
# parameters: (ref_to_input_array, ref_to_output_array, [offset_flag])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty matf object
	my $self = [
		{},    # header
		[],    # matrix
		[]     # offset
	];
	
	# local parameter
	my ($info);

	# if there are parameters
	if (@_) {
		
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
			
			# make new matf object from attribute hash
			_new_from_hash($self, shift());
			
		# if two or three parameters
		} elsif (@_ == 2 || @_ == 3) {
			
			# fit the object to data
			($info = fit($self, @_)) && croak("'matf' fit operation failed with error $info");
			
		} else {
			
			# error
			croak('\'matf\' invalid parameter(s)');
			
		}
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# make CAT (chromatic adaptation transform) object
# using linear Bradford transform (see Annex E of 'ICC1v43_2010-12.pdf')
# default PCS is ICC D50, normalized to adopted white point (SRC)
# parameters: (src_XYZ_vector, [pcs_XYZ_vector])
# returns: (ref_to_object)
sub bradford {

	# get object class
	my $class = shift();

	# create empty matf object
	my $self = [
		{},    # header
		[],    # matrix
		[]     # offset
	];

	# local variables
	my ($brad, $srct, $pcst, $ratio);

	# get parameters
	my ($src, $pcs) = @_;

	# if pcs values are undefined
	if (! defined($pcs)) {
		
		# set pcs xyz values to ICC D50 (normalized)
		$pcs = [map {$_ * $src->[1]} 0.9642, 1, 0.8249];
		
	}

	# make Bradford matrix
	$brad = Math::Matrix->new(
		[0.8951, 0.2664, -0.1614],
		[-0.7502, 1.7135, 0.0367],
		[0.0389, -0.0685, 1.0296]
	);

	# compute pcs cone values
	$pcst = $brad * (Math::Matrix->new($pcs)->transpose);

	# compute src cone values
	$srct = $brad * (Math::Matrix->new($src)->transpose);

	# make cone ratio matrix
	$ratio = Math::Matrix->new(
		[$srct->[0][0]/$pcst->[0][0], 0, 0],
		[0, $srct->[1][0]/$pcst->[1][0], 0],
		[0, 0, $srct->[2][0]/$pcst->[2][0]]
	);

	# set header
	$self->[0] = {'src' => $src, 'pcs' => $pcs, 'type' => 'bradford'};

	# set matrix
	$self->[1] = ($ratio * $brad)->concat($brad)->solve;

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# make CAT (chromatic adaptation transform) object
# using CAT02 transform (see CIE CIECAM02)
# default PCS is ICC D50, normalized to adopted white point (SRC)
# parameters: (src_XYZ_vector, [pcs_XYZ_vector])
# returns: (ref_to_object)
sub cat02 {

	# get object class
	my $class = shift();

	# create empty matf object
	my $self = [
		{},    # header
		[],    # matrix
		[]     # offset
	];

	# local variables
	my ($cat02, $srct, $pcst, $ratio);

	# get parameters
	my ($src, $pcs) = @_;

	# if pcs values are undefined
	if (! defined($pcs)) {
		
		# set pcs xyz values to ICC D50 (normalized)
		$pcs = [map {$_ * $src->[1]} 0.9642, 1, 0.8249];
		
	}

	# make CAT02 matrix
	$cat02 = Math::Matrix->new(
		[0.7328, 0.4296, -0.1624],
		[-0.7036, 1.6975, 0.0061],
		[0.0030, 0.0136, 0.9834]
	);

	# compute pcs cone values
	$pcst = $cat02 * (Math::Matrix->new($pcs)->transpose);

	# compute src cone values
	$srct = $cat02 * (Math::Matrix->new($src)->transpose);

	# make cone ratio matrix
	$ratio = Math::Matrix->new(
		[$srct->[0][0]/$pcst->[0][0], 0, 0],
		[0, $srct->[1][0]/$pcst->[1][0], 0],
		[0, 0, $srct->[2][0]/$pcst->[2][0]]
	);

	# set header
	$self->[0] = {'src' => $src, 'pcs' => $pcs, 'type' => 'cat02'};

	# set matrix
	$self->[1] = ($ratio * $cat02)->concat($cat02)->solve;

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# make CAT (chromatic adaptation transform) object
# just scales the src XYZ values to the pcs, not a true CAT
# default PCS is ICC D50, normalized to adopted white point (SRC)
# parameters: (src_XYZ_vector, [pcs_XYZ_vector])
# returns: (ref_to_object)
sub quasi {

	# get object class
	my $class = shift();

	# create empty matf object
	my $self = [
		{},    # header
		[],    # matrix
		[]     # offset
	];

	# get parameters
	my ($src, $pcs) = @_;

	# if pcs values are undefined
	if (! defined($pcs)) {
		
		# set pcs xyz values to ICC D50 (normalized)
		$pcs = [map {$_ * $src->[1]} (0.9642, 1, 0.8249)];
		
	}

	# set header
	$self->[0] = {'src' => $src, 'pcs' => $pcs, 'type' => 'quasi'};

	# set matrix
	$self->[1] = Math::Matrix->diagonal($pcs->[0]/$src->[0], $pcs->[1]/$src->[1], $pcs->[2]/$src->[2]);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create inverse 'matf' object
# returns: (ref_to_object)
sub inv {

	# get object
	my $self = shift();

	# local variables
	my ($inv, $sys);

	# make new empty object
	$inv = ICC::Profile::matf->new();

	# if matrix is not empty
	if (defined($self->[1][0][0])) {
		
		# verify matrix is square
		(@{$self->[1]} == @{$self->[1][0]}) || croak('matrix must be square');
		
		# invert matrix
		$inv->[1] = $self->[1]->invert();
		
		# if offset is not empty
		if (defined($self->[2][0])) {
			
			# clone the parent matrix
			$sys = Storable::dclone($self->[1]);
			
			# for each matrix row
			for my $i (0 .. $#{$sys}) {
				
				# concatenate negative offsets
				push(@{$sys->[$i]}, -$self->[2][$i]);
				
			}
			
			# solve for new offsets
			$inv->[2] = $sys->solve->transpose->[0];
			
		}
		
	}

	# return object
	return($inv);

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
			croak('\'matf\' header attribute must be a hash reference');
			
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
		
		# if one parameter, a 2-D array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {ref() eq 'ARRAY'} @{$_[0]}) {
			
			# set matrix to clone of array
			$self->[1] = bless(Storable::dclone($_[0]), 'Math::Matrix');
			
		# if one parameter, a Math::Matrix object
		} elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'Math::Matrix')) {
			
			# set matrix to object
			$self->[1] = $_[0];
			
		} else {
			
			# error
			croak('\'matf\' matrix must be a 2-D array reference or Math::Matrix object');
			
		}
		
	}
	
	# return object reference
	return($self->[1]);
	
}

# get/set reference to offset array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub offset {
	
	# get object reference
	my $self = shift();
	
	# if there are parameters
	if (@_) {
		
		# if one parameter, an array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {! ref()} @{$_[0]}) {
			
			# set offset to copy of array
			$self->[2] = [@{shift()}];
			
		} else {
			
			# error
			croak('\'matf\' offset must be an array reference');
			
		}
		
	}
	
	# return reference
	return($self->[2]);
	
}

# get/set equivalent matrix-based profile primaries
# see appendix F.3 of 'ICC1v43_2010-12.pdf'
# each matrix row contains an XYZ primary
# parameters: ([Math::Matrix_object -or- ref_to_array])
# returns: (Math::Matrix_object)
sub primary {

	# get parameters
	my ($self, $pri) = @_;

	# if primaries parameter is supplied
	if (defined($pri)) {
		
		# if 3x3 Math::Matrix object or array
		if ((UNIVERSAL::isa($pri, 'Math::Matrix') || ref($pri) eq 'ARRAY') && @{$pri} == 3 && @{$pri->[0]} == 3) {
			
			# compute matrix object from primary tags
			$self->[1] = Math::Matrix->new(@{$pri})->transpose->multiply_scalar(32768/65535);
			
		} else {
			
			# error
			croak('invalid primary matrix parameter');
			
		}
		
	} else {
		
		# if 'matf' matrix is defined
		if (defined($self->[1])) {
			
			# compute primary tags from matrix object
			$pri = $self->[1]->multiply_scalar(65535/32768)->transpose();
			
		} else {
			
			# error
			croak('\'matf\' object has no matrix');
			
		}
		
	}

	# return
	return($pri);

}

# fit matf object to data
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
	($#{$in} == $#{$out}) || croak('\'fit\' input and output arrays have different number of rows');

	# fit the matrix
	($info, $ab) = ICC::Support::Lapack::matf_fit($in, $out, $oflag);

	# check result
	carp('fit failed - bad parameter when calling dgels') if ($info < 0);
	carp('fit failed - A matrix not full rank') if ($info > 0);

	# initialize matrix object
	$self->[1] = Math::Matrix->new([]);

	# for each input
	for my $i (0 .. $#{$in->[0]}) {
		
		# for each output
		for my $j (0 .. $#{$out->[0]}) {
			
			# set matrix element (transposing)
			$self->[1][$j][$i] = $ab->[$i][$j];
			
		}
		
	}
	
	# if offset flag
	if ($oflag) {
		
		# set offset
		$self->[2] = [@{$ab->[$#{$in->[0]} + 1]}];
		
	} else {
		
		# no offset
		$self->[2] = [];
		
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
		$int = ICC::Support::Lapack::matf_vec_trans($out, $self->[1], $self->[2]);
		
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
		($info) && print "matf inverse error $info: @{$in}\n";
		
		# for each output value
		for my $i (0 .. $#so) {
			
			# add delta value
			$out->[$so[$i]] += $delta->[$i][0];
			
		}
		
		# compute final transform values
		@{$in} = @{ICC::Support::Lapack::matf_vec_trans($out, $self->[1], $self->[2])};
		
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
		$delta = $mat->solve || print "matf inverse error: @{$in}\n";
		
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

# invert data
# requires the matrix element to be square
# supported input types:
# parameters: (list, [hash])
# parameters: (vector, [hash])
# parameters: (matrix, [hash])
# parameters: (Math::Matrix_object, [hash])
# parameters: (structure, [hash])
# returns: (same_type_as_input)
sub invsqr {

	# set hash value (0 or 1)
	my $h = ref($_[-1]) eq 'HASH' ? 1 : 0;

	# if input a 'Math::Matrix' object
	if (@_ == $h + 2 && UNIVERSAL::isa($_[1], 'Math::Matrix')) {
		
		# call matrix transform
		&_invsqr2;
		
	# if input an array reference
	} elsif (@_ == $h + 2 && ref($_[1]) eq 'ARRAY') {
		
		# if array contains numbers (vector)
		if (! ref($_[1][0]) && @{$_[1]} == grep {Scalar::Util::looks_like_number($_)} @{$_[1]}) {
			
			# call vector transform
			&_invsqr1;
			
		# if array contains vectors (2-D array)
		} elsif (ref($_[1][0]) eq 'ARRAY' && @{$_[1]} == grep {ref($_) eq 'ARRAY' && Scalar::Util::looks_like_number($_->[0])} @{$_[1]}) {
			
			# call matrix transform
			&_invsqr2;
			
		} else {
			
			# call structure transform
			&_invsqr3;
			
		}
		
	# if input a list (of numbers)
	} elsif (@_ == $h + 1 + grep {Scalar::Util::looks_like_number($_)} @_) {
		
		# call list transform
		&_invsqr0;
		
	} else {
		
		# error
		croak('invalid transform input');
		
	}

}

# create matf object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty matf object
	my $self = [
		{},    # header
		[],    # matrix
		[]     # offset
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read matf data from profile
	_readICCmatf($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes matf object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get object reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write matf data to profile
	_writeICCmatf($self, @_);

}

# get tag size (for writing to profile)
# returns: (clut_size)
sub size {

	# get parameter
	my $self = shift();

	# set header size
	my $size = 12;

	# add matrix and offset size
	$size += 4 * @{$self->[1]} * (@{$self->[1][0]} + 1);

	# return size
	return($size);

}

# get number of input channels
# returns: (number)
sub cin {

	# get object reference
	my $self = shift();

	# return
	return(scalar(@{$self->[1][0]}));

}

# get number of output channels
# returns: (number)
sub cout {

	# get object reference
	my $self = shift();

	# return
	return(scalar(@{$self->[1]}));

}

# print object contents to string
# format is an array structure
# parameter: ([format])
# returns: (string)
sub sdump {

	# get parameters
	my ($self, $p) = @_;

	# local variables
	my ($fmt, $s, $rows, $off, $fn);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 'm';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# get matrix rows
	$rows = $#{$self->[1]};

	# get offset size
	$off = $#{$self->[2]};

	# if empty object
	if ($rows < 0 && $off < 0) {
		
		# append string
		$s .= "<empty object>\n";
		
	} else {
		
		# if matrix
		if ($rows >= 0) {
			
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
		
		# if offset
		if ($off >= 0) {
			
			# append string
			$s .= "offset values\n";
			
			# make number format
			$fmt = '  %10.5f' x @{$self->[2]};
			
			# append offset values
			$s .= sprintf("$fmt\n", @{$self->[2]});
			
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
	my ($self, $hash, @out);

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# validate number of input channels
	(@_ == @{$self->[1][0]}) || croak('wrong number input channels');

	# set output to offset values or zeros
	@out = defined($self->[2][0]) ? @{$self->[2]} : (0) x @{$self->[1]};

	# for each output
	for my $i (0 .. $#{$self->[1]}) {
		
		# add matrix value
		$out[$i] += ICC::Shared::dotProduct(\@_, $self->[1][$i]);
		
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
	(@{$in} == @{$self->[1][0]}) || croak('wrong number input channels');

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# call the BLAS dgemv function
		return(ICC::Support::Lapack::matf_vec_trans($in, $self->[1], $self->[2]));
		
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
	my ($info, $out, $offset);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# validate number of input channels
	(@{$in->[0]} == @{$self->[1][0]}) || croak('wrong number input channels');

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output matrix using BLAS dgemm function
		$out = ICC::Support::Lapack::matf_mat_trans($in, $self->[1], $self->[2]);
		
	} else {
		
		# get offset vector (zeros if undefined)
		$offset = defined($self->[2][0]) ? $self->[2] : [(0) x @{$in->[0]}];
		
		# make output array (from offset vector)
		$out = [map{Storable::dclone($offset)} (0 .. $#{$in})];
		
		# for each row
		for my $i (0 .. $#{$in}) {
			
			# for each column
			for my $j (0 .. $#{$self->[1]}) {
				
				# add dot product
				$out->[$i][$j] += ICC::Shared::dotProduct($in->[$i], $self->[1][$j]);
				
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

# invert list
# parameters: (object_reference, list, [hash])
# returns: (list)
sub _invsqr0 {

	# local variables
	my ($self, $hash, @out);

	# get object reference
	$self = shift();

	# get optional hash
	$hash = pop() if (ref($_[-1]) eq 'HASH');

	# validate number of input channels
	(@_ == @{$self->[1][0]}) || croak('wrong number input channels');

	# return simple array
	return(@{_invsqr1($self, [@_])});

}

# invert vector
# parameters: (object_reference, vector, [hash])
# returns: (vector)
sub _invsqr1 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# validate number of input channels
	(@{$in} == @{$self->[1]}) || croak('wrong number input channels');

	# clone the 'matf' matrix
	my $sys = Storable::dclone($self->[1]);

	# for each input channel
	for my $i (0 .. $#{$in}) {
		
		# concatenate input value (minus offset, if any)
		push(@{$sys->[$i]}, defined($self->[2][$i]) ? $in->[$i] - $self->[2][$i] : $in->[$i]);
		
	}

	# return output vector
	return([map {$_->[0]} @{$sys->solve()}]);

}

# invert matrix (Math::Matrix object -or- 2-D array)
# parameters: (object_reference, matrix, [hash])
# returns: (output_matrix)
sub _invsqr2 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($info, $out, $sys);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# validate number of input channels
	(@{$in->[0]} == @{$self->[1]}) || croak('wrong number input channels');

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output matrix using Lapack DGESV function
		($info, $out) = ICC::Support::Lapack::matf_inv($in, $self->[1], $self->[2]);
		
		# check for DGESV error
		($info) && croak("'ICC::Support::Lapack::matf_inv' error: $info");
		
		# return output matrix (Math::Matrix object or 2-D array)
		return(UNIVERSAL::isa($in, 'Math::Matrix') ? bless($out, 'Math::Matrix') : $out);
		
	} else {
		
		# clone the 'matf' matrix
		$sys = Storable::dclone($self->[1]);
		
		# for each input channel
		for my $i (0 .. $#{$in->[0]}) {
			
			# for each data sample
			for my $j (0 .. $#{$in}) {
				
				# concatenate input value (minus offset, if any)
				push(@{$sys->[$i]}, defined($self->[2][$i]) ? $in->[$j][$i] - $self->[2][$i] : $in->[$j][$i]);
				
			}
			
		}
		
		# compute output matrix using 'Math::Matrix' methods
		$out = $sys->solve->transpose();
		
		# return output matrix (Math::Matrix object or 2-D array)
		return(UNIVERSAL::isa($in, 'Math::Matrix') ? $out : [@{$out}]);
		
	}
	
}

# invert structure
# parameters: (object_reference, structure, [hash])
# returns: (structure)
sub _invsqr3 {

	# get parameters
	my ($self, $in, $hash) = @_;

	# transform the array structure
	_crawl($self, \&_invsqr1, $in, my $out = []);

	# return output structure
	return($out);

}

# make new matf object from attribute hash
# hash keys are: ('header', 'matrix', 'offset')
# object elements not specified in the hash are unchanged
# parameters: (ref_to_object, ref_to_attribute_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($value);
	
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
		
		# if a reference to a 2-D array
		if (ref($value) eq 'ARRAY' && @{$value} == grep {ref() eq 'ARRAY'} @{$value}) {
			
			# copy matrix to object
			$self->[1] = bless(Storable::dclone($value), 'Math::Matrix');
			
		# if a Math::Matrix object
		} elsif (UNIVERSAL::isa($value, 'Math::Matrix')) {
			
			# copy matrix to object
			$self->[1] = Storable::dclone($value);
			
		# if a positive integer
		} elsif (Scalar::Util::looks_like_number($value) && $value == int($value) && $value > 0) {
			
			# set matrix to identity matrix
			$self->[1] = Math::Matrix->new_identity($value);
			
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
			
			# copy offset to object
			$self->[2] = [@{$value}];
			
		# if a numeric value
		} elsif (Scalar::Util::looks_like_number($value)) {
			
			# if first 'matrix' row is defined
			if (defined($self->[1])) {
				
				# set offset to constant
				$self->[2] = [($value) x @{$self->[1]}];
				
			} else {
				
				# wrong data type
				croak('unknown \'matrix\' size');
				
			}
			
		} else {
			
			# wrong data type
			croak('wrong \'offset\' data type');
			
		}
		
	}
	
}

# read matf data
# note: assumes file handle is positioned at start of matrix data
# header information must be read separately by the calling function
# setting offset flag enables reading of offset data following matrix data
# number format is  2 (s15Fixed16Number) or 4 (floating point)
# parameters: (ref_to_object, file_handle, input_channels, output_channels, offset_flag, format)
sub _read_matf {

	# get parameters
	my ($self, $fh, $ci, $co, $oflag, $format) = @_;

	# local variables
	my ($buf);

	# if s15Fixed16Number format
	if ($format == 2) {
		
		# for each output channel
		for my $i (0 .. $co - 1) {
			
			# read into buffer
			read($fh, $buf, 4 * $ci);
			
			# unpack buffer and save
			$self->[1][$i] = [ICC::Shared::s15f162v(unpack('N*', $buf))];
			
		}
		
		# if offset data
		if ($oflag) {
			
			# read into buffer
			read($fh, $buf, 4 * $co);
			
			# unpack buffer and save
			$self->[2] = [ICC::Shared::s15f162v(unpack('N*', $buf))];
			
		}
		
	# if floating point format
	} elsif ($format == 4) {
		
		# for each output channel
		for my $i (0 .. $co - 1) {
			
			# read into buffer
			read($fh, $buf, 4 * $ci);
			
			# unpack buffer and save
			$self->[1][$i] = [unpack('f>*', $buf)];
			
		}
		
		# if offset data
		if ($oflag) {
			
			# read into buffer
			read($fh, $buf, 4 * $co);
			
			# unpack buffer and save
			$self->[2] = [unpack('f>*', $buf)];
			
		}
		
	} else {
		
		# error
		croak('unsupported format, must be 2 or 4');
		
	}
	
	# bless matrix array
	bless($self->[1], 'Math::Matrix');
	
}

# read matf tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCmatf {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $ci, $co);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag header
	read($fh, $buf, 12);

	# unpack header
	($ci, $co) = unpack('x8 n2', $buf);

	# set number of input channels
	$self->[0]{'input_channels'} = $ci;

	# set number of output channels
	$self->[0]{'output_channels'} = $co;

	# read matrix w/offset
	_read_matf($self, $fh, $ci, $co, 1, 4);

}

# write matf data
# note: assumes file handle is positioned at start of matf data
# header information must be written separately by the calling function
# setting offset flag enables writing of offset data following matrix data
# if offset data array is undefined or empty, zeros are written
# number format is  2 (s15Fixed16Number) or 4 (floating point)
# parameters: (ref_to_object, file_handle, offset_flag, format)
sub _write_matf {

	# get parameters
	my ($self, $fh, $oflag, $format) = @_;

	# local variables
	my ($buf);

	# if s15Fixed16Number format
	if ($format == 2) {
		
		# for each matrix row
		for my $i (0 .. $#{$self->[1]}) {
			
			# write matrix values as s15Fixed16Numbers
			print $fh pack('N*', ICC::Shared::v2s15f16(@{$self->[1][$i]}));
			
		}
		
		# if offset data
		if ($oflag) {
			
			# write offset values as s15Fixed16Numbers (if offset array is undefined or empty, write zeros)
			print $fh pack('N*', (defined($self->[2]) && @{$self->[2]} > 0) ? ICC::Shared::v2s15f16(@{$self->[2]}) : (0) x @{$self->[1][0]});
			
		}
		
	# if floating point format
	} elsif ($format == 4) {
		
		# for each matrix row
		for my $i (0 .. $#{$self->[1]}) {
			
			# write matrix values as big-endian 32-bit floating point
			print $fh pack('f>*', @{$self->[1][$i]});
			
		}
		
		# if offset data
		if ($oflag) {
			
			# write offset values as big-endian 32-bit floating point (if offset array is undefined or empty, write zeros)
			print $fh pack('f>*', (defined($self->[2]) && @{$self->[2]} > 0) ? @{$self->[2]} : (0) x @{$self->[1][0]});
			
		}
		
	} else {
		
		# error
		croak('unsupported format, must be 2 or 4');
		
	}
	
}

# write matf tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCmatf {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($ci, $co);

	# get number of input channels
	$ci = @{$self->[1][0]};

	# get number of output channels
	$co = @{$self->[1]};
	
	# validate number input channels (1 to 15)
	($ci > 0 && $ci < 16) || croak('unsupported number of input channels');

	# validate number output channels (1 to 15)
	($co > 0 && $co < 16) || croak('unsupported number of output channels');

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write 'matf' header
	print $fh pack('a4 x4 n2', 'matf', $ci, $co);

	# write matrix w/offset
	_write_matf($self, $fh, 1, 4);

}

1;