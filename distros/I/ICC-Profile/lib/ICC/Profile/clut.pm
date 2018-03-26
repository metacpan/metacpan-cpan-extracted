package ICC::Profile::clut;

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

# create new clut object
# hash may contain pointers to clut, grid size array or user-defined functions
# hash keys are: ('array', 'clut_bytes', 'gsa', 'udf')
# parameters: ([ref_to_attribute_hash])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty clut object
	my $self = [
		{},    # object header
		[],    # clut
		[],    # grid size array
		[],    # user-defined functions
		undef, # clut cache (for Lapack)
		undef, # corner point cache
	];

	# if there are parameters
	if (@_) {
		
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
			
			# make new clut object from attribute hash
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
			$self->[0] = {%{shift()}};
			
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
			
			# set clut to clone of array
			$self->[1] = Storable::dclone($_[0]);
			
			# update caches
			$self->[4] = ICC::Support::Lapack::cache_2D($self->[1]) if (defined($INC{'ICC/Support/Lapack.pm'}));
			undef($self->[5]);
			
		# if one parameter, a Math::Matrix object
		} elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'Math::Matrix')) {
			
			# set clut to object
			$self->[1] = $_[0];
			
			# update caches
			$self->[4] = ICC::Support::Lapack::cache_2D($self->[1]) if (defined($INC{'ICC/Support/Lapack.pm'}));
			undef($self->[5]);
			
		} else {
			
			# error
			croak('clut array must be a 2-D array reference or Math::Matrix object');
			
		}
		
	}

	# return reference
	return($self->[1]);

}

# get/set reference to grid size array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub gsa {

	# get object reference
	my $self = shift();

	# if there are parameters
	if (@_) {
		
		# if one parameter, an array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {! ref()} @{$_[0]}) {
			
			# set gsa to copy of array
			$self->[2] = [@{shift()}];
			
		} else {
			
			# error
			croak('clut gsa must be an array reference');
			
		}
		
	}

	# return reference
	return($self->[2]);

}

# get/set reference to user-defined functions array
# parameters: ([ref_to_new_array])
# returns: (ref_to_array)
sub udf {
	
	# get object reference
	my $self = shift();
	
	# if there are parameters
	if (@_) {
		
		# if one parameter, an array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {ref() eq 'CODE'} @{$_[0]}) {
			
			# set udf to copy of array
			$self->[3] = [@{shift()}];
			
		} else {
			
			# error
			croak('parameter must be an array reference');
			
		}
		
	}
	
	# return reference
	return($self->[3]);
	
}

# get/set reference to clut array element
# array element is an array of output values
# parameters: (index_array, [ref_to_new_array])
# returns: (ref_to_array)
sub clut {

	# get object reference
	my $self = shift();

	# local variables
	my ($lx, $ref, $gsa);

	# get reference to new array (if present)
	$ref = pop() if (ref($_[-1]) eq 'ARRAY');

	# get grid size array
	$gsa = $self->[2];

	# validate indices
	(@_ == @{$gsa}) || croak('wrong number of clut indices');
	(@_ == grep {! ref() && $_ == int($_)} @_) || croak('clut index not an integer');
	(@_ == grep {$_[$_] >= 0 && $_[$_] < $gsa->[$_]} 0 .. $#_) || croak('clut index out of range');

	# initialize clut pointer
	$lx = $_[0];

	# for each remaining index
	for my $i (1 .. $#_) {
		
		# multiply by grid size
		$lx *= $gsa->[$i];
		
		# add index
		$lx += $_[$i];
		
	}

	# if replacement data provided
	if (defined($ref)) {
		
		# update CLUT
		$self->[1][$lx] = [@{$ref}];
		
		# update caches
		$self->[4] = ICC::Support::Lapack::cache_2D($self->[1]) if (defined($INC{'ICC/Support/Lapack.pm'}));
		undef($self->[5]);
		
	}

	# return array reference
	return($self->[1][$lx]);

}

# create clut object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty clut object
	my $self = [
		{},    # object header
		[],    # clut
		[],    # grid size array
		[]     # user-defined functions
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read clut data from profile
	_readICCclut($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes clut object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get object reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write clut data to profile
	_writeICCclut($self, @_);

}

# get tag size (for writing to profile)
# returns: (clut_size)
sub size {

	# get parameter
	my $self = shift();

	# return size
	return(_clut_size($self, 4) + 28);

}

# get number of input channels
# returns: (number)
sub cin {

	# get object reference
	my $self = shift();

	# return
	return(scalar(@{$self->[2]}));

}

# get number of output channels
# returns: (number)
sub cout {

	# get object reference
	my $self = shift();

	# return
	return(scalar(@{$self->[1][0]}));

}

# build clut array from user-defined transform function
# parameters may be set with an optional hash
# keys are: ('clut_bytes', 'gsa', 'udf', 'slice')
# parameters: ([ref_to_attribute_hash])
# returns: (ref_to_object)
sub build {

	# get parameters
	my ($self, $hash) = @_;

	# local variables
	my ($gsa, $ci, $co, @out);
	my ($size, @slice);

	# for each attribute
	for my $attr (keys(%{$hash})) {
		
		# if 'clut_bytes'
		if ($attr eq 'clut_bytes') {
			
			# if a scalar, 1 or 2
			if (! ref($hash->{$attr}) && ($hash->{$attr} == 1 || $hash->{$attr} == 2)) {
				
				# add to header hash
				$self->[0]{'clut_bytes'} = $hash->{$attr};
				
			} else {
				
				# wrong data type
				croak('clut \'clut_bytes\' attribute must be a scalar, 1 or 2');
				
			}
			
		# if 'gsa'
		} elsif ($attr eq 'gsa') {
			
			# if reference to an array of scalars
			if (ref($hash->{$attr}) eq 'ARRAY' && @{$hash->{$attr}} == grep {! ref()} @{$hash->{$attr}}) {
				
				# set object element
				$self->[2] = [@{$hash->{$attr}}];
				
			} else {
				
				# wrong data type
				croak('clut \'gsa\' attribute must be an array reference');
				
			}
			
		# if 'udf'
		} elsif ($attr eq 'udf') {
			
			# if reference to an array of CODE references
			if (ref($hash->{$attr}) eq 'ARRAY' && @{$hash->{$attr}} == grep {ref() eq 'CODE'} @{$hash->{$attr}}) {
				
				# set object element
				$self->[3] = [@{$hash->{$attr}}];
				
			} else {
				
				# wrong data type
				croak('clut \'udf\' attribute must be an array reference');
				
			}
			
		# if 'slice'
		} elsif ($attr eq 'slice') {
			
			# if reference to an array of scalars
			if (ref($hash->{$attr}) eq 'ARRAY' && @{$hash->{$attr}} == grep {! ref()} @{$hash->{$attr}}) {
				
				# set slice array
				@slice = @{$hash->{$attr}};
				
			# if 'log'
			} elsif ($hash->{$attr} eq 'log') {
				
				# if 'log' hash is defined
				if (defined($self->[0]{'log'}) && ref($self->[0]{'log'}) eq 'HASH') {
					
					# set slice to hash keys
					@slice = keys(%{$self->[0]{'log'}});
					
				}
				
			} else {
				
				# wrong data type
				croak('clut \'slice\' attribute must be an array reference or \'log\'');
				
			}
			
		} else {
			
			# invalid attribute
			croak('invalid clut attribute');
			
		}
		
	}

	# get grid size array
	$gsa = $self->[2];

	# get number of input channels
	$self->[0]{'input_channels'} = $ci = @{$gsa};

	# validate user-defined function
	(ref($self->[3][0]) eq 'CODE') || croak('invalid user-defined function');

	# test user-defined function
	@out = &{$self->[3][0]}((0) x $ci);

	# determine number of output channels
	$self->[0]{'output_channels'} = $co = @out;

	# validate parameters
	(@{$gsa} == grep {! ref() && $_ == int($_)} @{$gsa}) || croak('grid size not an integer');
	(0 == grep {$_ < 2} @{$gsa}) || croak('grid size less than 2');
	($ci > 0 && $ci < 16) || croak('invalid number of input channels');
	($co > 0 && $co < 16) || croak('invalid number of output channels');

	# initialize clut entries
	$size = 1;

	# for each input channel
	for (@{$gsa}) {
		
		# multiply by grid size
		$size *= $_;
		
	}

	# set slice to entire clut, if empty
	@slice = (0 .. $size - 1) if (! @slice);

	# for each clut entry
	for my $i (@slice) {
		
		# compute transform value
		$self->[1][$i] = [&{$self->[3][0]}(_lin2ix($gsa, $i))];
		
	}
	
	# update caches
	$self->[4] = ICC::Support::Lapack::cache_2D($self->[1]) if (defined($INC{'ICC/Support/Lapack.pm'}));
	undef($self->[5]);

	# return object reference
	return($self);

}

# transform data
# input range is (0 - 1)
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
# clipped outputs are extrapolated using Jacobian
# parameters: (input_vector, [hash])
# returns: (Jacobian_matrix, [output_vector])
sub jacobian {

	# get parameters
	my ($self, $in, $hash) = @_;

	# local variables
	my ($ext, $out, $jac, $rel, $cp, $jac_bc, $sf);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if user-defined transform and user-defined Jacobian functions
	if (defined($self->[3][0]) && defined($self->[3][1])) {
		
		# if output values wanted
		if (wantarray) {
			
			# return Jacobian and output values
			return(&{$self->[3][1]}(@{$in}), [&{$self->[3][0]}(@{$in})]);
			
		} else {
			
			# return Jacobian only
			return(&{$self->[3][1]}(@{$in}));
			
		}
		
	# if user-defined transform xor user-defined Jacobian functions
	} elsif (defined($self->[3][0]) ^ defined($self->[3][1])) {
		
		# die with message
		croak('transform and Jacobian must both be user-defined functions, or not');
		
	}

	# if unit box extrapolation
	if ($hash->{'ubox'} && grep {$_ < 0.0 || $_ > 1.0} @{$in}) {
		
		# compute intersection with unit box
		($ext, $in) = _intersect($in);
		
	}

	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# if extrapolating
		if (defined($ext)) {
			
			# compute Jacobian matrix using Lapack module
			$jac = ICC::Support::Lapack::clut_jacobian_ext($self->[2], $in, $self->[4]);
			
		} else {
			
			# compute Jacobian matrix using Lapack module
			$jac = ICC::Support::Lapack::clut_jacobian($self->[2], $in, $self->[4]);
			
		}
			
		# bless Jacobian as Math::Matrix object
		bless($jac, 'Math::Matrix');
		
	} else {
		
		# if extrapolating
		if (defined($ext)) {
			
			# compute outer corner points
			$cp = _locate_ext($self);
			
			# compute the barycentric jacobian
			$jac_bc = _barycentric_jacobian($in);
			
			# compute Jacobian matrix
			$jac = bless($cp, 'Math::Matrix') * $jac_bc;
			
		} else {
			
			# compute relative input vector and corner points
			($rel, $cp) = _locate($self, $in);
			
			# compute the barycentric jacobian
			$jac_bc = _barycentric_jacobian($rel);
			
			# compute Jacobian matrix
			$jac = bless($cp, 'Math::Matrix') * $jac_bc;
			
			# for each input channel
			for my $i (0 .. $#{$jac->[0]}) {
				
				# compute scale factor for grid size
				$sf = $self->[2][$i] - 1;
				
				# for each output channel
				for my $j (0 .. $#{$jac}) {
					
					# scale matrix element
					$jac->[$j][$i] *= $sf;
					
				}
				
			}
			
		}
		
	}

	# if output values wanted
	if (wantarray) {
		
		# compute output values
		$out = _trans1($self, $in);
		
		# if extrapolating
		if (defined($ext)) {
			
			# for each output
			for my $i (0 .. $#{$self->[1][0]}) {
				
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
	my ($ext, $out, $rel, $cp, $coef, $jac_bc, $jac);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if user-defined transform function
	if (defined($self->[3][0])) {
		
		# call it and return
		return([&{$self->[3][0]}(@{$in})]);
		
	}

	# if unit box extrapolation
	if ($hash->{'ubox'} && grep {$_ < 0.0 || $_ > 1.0} @{$in}) {
		
		# compute intersection with unit box
		($ext, $in) = _intersect($in);
		
	}
	
	# if ICC::Support::Lapack module is loaded
	if ($lapack) {
		
		# compute output using Lapack module
		$out = ICC::Support::Lapack::clut_vec_trans($self->[2], $in, $self->[4]);
		
		# if extrapolating
		if (defined($ext)) {
			
			# compute Jacobian matrix using Lapack module
			$jac = ICC::Support::Lapack::clut_jacobian_ext($self->[2], $in, $self->[4]);
			
			# for each output
			for my $i (0 .. $#{$self->[1][0]}) {
				
				# add delta value
				$out->[$i] += ICC::Shared::dotProduct($jac->[$i], $ext);
				
			}
			
		}
		
		
	} else {
		
		# compute relative input vector and corner points
		($rel, $cp) = _locate($self, $in);
		
		# compute barycentric coefficients
		$coef = _barycentric($rel);
		
		# for each output value
		for my $i (0 .. $#{$self->[1][0]}) {
			
			# compute output value
			$out->[$i] = ICC::Shared::dotProduct($cp->[$i], $coef);
			
		}
		
		# if extrapolating
		if (defined($ext)) {
			
			# compute outer corner points
			$cp = _locate_ext($self);
			
			# compute the barycentric Jacobian
			$jac_bc = _barycentric_jacobian($in);
			
			# compute Jacobian matrix
			$jac = bless($cp, 'Math::Matrix') * $jac_bc;
			
			# for each output
			for my $i (0 .. $#{$self->[1][0]}) {
				
				# add delta value
				$out->[$i] += ICC::Shared::dotProduct($jac->[$i], $ext);
				
			}
			
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
	my ($out, $ext, $ink, $rel, $cp, $coef, $jac_bc, $jac);

	# check if ICC::Support::Lapack module is loaded
	state $lapack = defined($INC{'ICC/Support/Lapack.pm'});

	# if user-defined transform function
	if (defined($self->[3][0])) {
		
		# for each input vector
		for my $i (0 .. $#{$in}) {
			
			# call udf to compute transformed value
			$out->[$i] = [&{$self->[3][0]}(@{$in->[$i]})];
			
		}
		
	# if ICC::Support::Lapack module is loaded
	} elsif ($lapack) {
		
		# for each input vector
		for my $i (0 .. $#{$in}) {
			
			# if unit box extrapolation
			if ($hash->{'ubox'} && grep {$_ < 0.0 || $_ > 1.0} @{$in->[$i]}) {
				
				# compute intersection with unit box
				($ext, $ink) = _intersect($in->[$i]);
				
			} else {
				
				# no extrapolation, copy input
				($ext, $ink) = (undef, $in->[$i]);
				
			}
			
			# compute output using Lapack module
			$out->[$i] = ICC::Support::Lapack::clut_vec_trans($self->[2], $ink, $self->[4]);
			
			# if extrapolating
			if (defined($ext)) {
				
				# compute Jacobian matrix using Lapack module
				$jac = ICC::Support::Lapack::clut_jacobian_ext($self->[2], $ink, $self->[4]);
				
				# for each output value
				for my $j (0 .. $#{$self->[1][0]}) {
					
					# add delta value
					$out->[$i][$j] += ICC::Shared::dotProduct($jac->[$j], $ext);
					
				}
				
			}
			
		}
		
	} else {
		
		# for each input vector
		for my $i (0 .. $#{$in}) {
			
			# if unit box extrapolation
			if ($hash->{'ubox'} && grep {$_ < 0.0 || $_ > 1.0} @{$in->[$i]}) {
				
				# compute intersection with unit box
				($ext, $ink) = _intersect($in->[$i]);
				
			} else {
				
				# no extrapolation, copy input
				($ext, $ink) = (undef, $in->[$i]);
				
			}
			
			# compute relative input vector and corner points
			($rel, $cp) = _locate($self, $ink);
			
			# compute barycentric coefficients
			$coef = _barycentric($rel);
			
			# for each output value
			for my $j (0 .. $#{$self->[1][0]}) {
				
				# compute output value
				$out->[$i][$j] = ICC::Shared::dotProduct($cp->[$j], $coef);
				
			}
			
			# if extrapolating
			if (defined($ext)) {
				
				# compute outer corner points
				$cp = _locate_ext($self);
				
				# compute the barycentric Jacobian
				$jac_bc = _barycentric_jacobian($ink);
				
				# compute Jacobian matrix
				$jac = bless($cp, 'Math::Matrix') * $jac_bc;
				
				# for each output value
				for my $j (0 .. $#{$self->[1][0]}) {
					
					# add delta value
					$out->[$i][$j] += ICC::Shared::dotProduct($jac->[$j], $ext);
					
				}
				
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

# compute relative input vector and corner points
# parameter: (object_ref, input_vector)
# returns: (relative_input_vector, corner_point_array)
sub _locate {

	# get parameter
	my ($self, $in) = @_;

	# local variables
	my (@rel, @ox, $ux, $key, @ix, $gp, $cp);

	# for each input value
	for my $i (0 .. $#{$in}) {
		
		# split clut span into fractional and integer parts
		($rel[$i], $ox[$i]) = POSIX::modf($in->[$i] * ($self->[2][$i] - 1));
		
		# compute upper grid index
		$ux = $self->[2][$i] - 2;
		
		# if grid index < 0
		if ($ox[$i] < 0) {
			
			# adjust
			$rel[$i] += $ox[$i];
			$ox[$i] = 0;
			
		# if grid index > upper index
		} elsif ($ox[$i] > $ux) {
			
			#adjust
			$rel[$i] += $ox[$i] - $ux;
			$ox[$i] = $ux;
			
		}
		
	}

	# compute hash key
	$key = join(':', @ox);
	
	# if corner points are not cached
	if (! ($cp = $self->[5]{$key})) {
		
		# for each corner point
		for my $i (0 .. 2**@{$in} - 1) {
			
			# copy origin
			@ix = @ox;
			
			# for each input
			for my $j (0 .. $#{$in}) {
				
				# increment index if bit set
				$ix[$j]++ if ($i >> $j & 1);
				
			}
			
			# get clut grid point array
			$gp = $self->[1][_ix2lin($self->[2], @ix)];
			
			# for each output
			for my $j (0 .. $#{$gp}) {
				
				# copy array value
				$cp->[$j][$i] = $gp->[$j];
				
			}
			
		}
		
		# save in cache
		$self->[5]{$key} = $cp;
		
	}

	# return
	return(\@rel, $cp);

}

# compute outer corner points
# parameter: (object_ref)
# returns: (corner_point_array)
sub _locate_ext {

	# get parameter
	my ($self) = @_;

	# local variables
	my ($cp, @ix, $gp);

	# if ext corner points are not cached
	if (! ($cp = $self->[5]{'ext'})) {
		
		# for each corner point
		for my $i (0 .. 2**@{$self->[2]} - 1) {
			
			# for each input
			for my $j (0 .. $#{$self->[2]}) {
				
				# increment index if bit set
				$ix[$j] = ($i >> $j & 1) ? $self->[2][$j] - 1 : 0;
				
			}
			
			# get clut grid point array
			$gp = $self->[1][_ix2lin($self->[2], @ix)];
			
			# for each output
			for my $j (0 .. $#{$gp}) {
				
				# copy array value
				$cp->[$j][$i] = $gp->[$j];
				
			}
			
		}
		
		# save in cache
		$self->[5]{'ext'} = $cp;
		
	}

	# return
	return($cp);

}

# compute barycentric coefficients
# parameter: (input_vector)
# returns: (coefficient_array)
sub _barycentric {

	# get parameter
	my $in = shift();

	# local variables
	my ($inc, $coef);

	# compute complement values
	$inc = [map {1 - $_} @{$in}];

	# initialize coefficient array
	$coef = [(1.0) x 2**@{$in}];

	# for each coefficient
	for my $i (0 .. $#{$coef}) {
		
		# for each device value
		for my $j (0 .. $#{$in}) {
			
			# if $j-th bit set
			if ($i >> $j & 1) {
				
				# multiply by device value
				$coef->[$i] *= $in->[$j];
				
			} else {
				
				# multiply by (1 - device value)
				$coef->[$i] *= $inc->[$j];
				
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
	my $in = shift();

	# local variables
	my ($inc, $rows, $jac);

	# compute complement values
	$inc = [map {1 - $_} @{$in}];

	# compute matrix rows
	$rows = 2**@{$in};

	# for each matrix row
	for my $i (0 .. $rows - 1) {
		
		# initialize row
		$jac->[$i] = [(1.0) x @{$in}];
		
		# for each matrix column
		for my $j (0 .. $#{$in}) {
			
			# for each device value
			for my $k (0 .. $#{$in}) {
				
				# if $k-th bit set
				if ($i >> $k & 1) {
					
					# multiply by device value -or- 1 (skip)
					$jac->[$i][$j] *= $in->[$k] if ($j != $k);
					
				} else {
					
					# multiply by (1 - device value) -or- -1
					$jac->[$i][$j] *= ($j != $k) ? $inc->[$k] : -1;
					
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

# compute clut linear index from index array
# parameters: (ref_to_grid_size_array, index_array)
# returns: (linear_index)
sub _ix2lin {

	# get parameters
	my ($gsa, @ix) = @_;

	# initialize linear_index
	my $lx = $ix[0];

	# for each remaining array value
	for my $i (1 .. $#ix) {
		
		# multiply by grid size
		$lx *= $gsa->[$i];
		
		# add index value
		$lx += $ix[$i];
		
	}

	# return linear index
	return($lx);

}

# compute clut index array from linear index
# parameters: (ref_to_grid_size_array, linear_index)
# returns: (index_array)
sub _lin2ix {

	# get parameters
	my ($gsa, $lx) = @_;

	# local variables
	my ($mod, @ix);

	# for each input channel
	for my $gs (reverse(@{$gsa})) {
		
		# compute modulus
		$mod = $lx % $gs;
		
		# adjust linear index
		$lx = ($lx - $mod)/$gs;
		
		# save input value
		unshift(@ix, $mod/($gs - 1));
		
	}

	# return index array
	return(@ix);

}

# get clut size
# parameter: (clut_bytes)
# returns: (clut_size)
sub _clut_size {

	# get parameter
	my ($self, $bytes) = @_;

	# get size of clut entry
	my $size = $bytes * @{$self->[1][0]};

	# for each grid size value
	for (@{$self->[2]}) {
		
		# multiply by grid size
		$size *= $_;
		
	}

	# return size
	return($size);

}

# make new clut object from attribute hash
# hash may contain pointers to clut, clut size, grid size array, and user-defined functions
# hash keys are: ('array', 'clut_bytes', 'gsa', 'udf')
# object elements not specified in the hash are unchanged
# parameters: (ref_to_object, ref_to_attribute_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# for each attribute
	for my $attr (keys(%{$hash})) {
		
		# if 'array'
		if ($attr eq 'array') {
			
			# if reference to a 2-D array
			if (ref($hash->{$attr}) eq 'ARRAY' && @{$hash->{$attr}} == grep {ref() eq 'ARRAY'} @{$hash->{$attr}}) {
				
				# set clut to clone of array
				$self->[1] = Storable::dclone($hash->{$attr});
				
				# update caches
				$self->[4] = ICC::Support::Lapack::cache_2D($self->[1]) if (defined($INC{'ICC/Support/Lapack.pm'}));
				undef($self->[5]);
				
			# if reference to a Math::Matrix object
			} elsif (UNIVERSAL::isa($hash->{$attr}, 'Math::Matrix')) {
				
				# set clut to object
				$self->[1] = $hash->{$attr};
				
				# update caches
				$self->[4] = ICC::Support::Lapack::cache_2D($self->[1]) if (defined($INC{'ICC/Support/Lapack.pm'}));
				undef($self->[5]);
				
			} else {
				
				# wrong data type
				croak('clut \'array\' attribute must be a 2-D array reference or Math::Matrix object');
				
			}
			
		# if 'clut_bytes'
		} elsif ($attr eq 'clut_bytes') {
			
			# if a scalar, 1 or 2
			if (! ref($hash->{$attr}) && ($hash->{$attr} == 1 || $hash->{$attr} == 2)) {
				
				# add to header hash
				$self->[0]{'clut_bytes'} = $hash->{$attr};
				
			} else {
				
				# wrong data type
				croak('clut \'clut_bytes\' attribute must be a scalar, 1 or 2');
				
			}
			
		# if 'gsa'
		} elsif ($attr eq 'gsa') {
			
			# if reference to a 1-D array (vector)
			if (ref($hash->{$attr}) eq 'ARRAY' && @{$hash->{$attr}} == grep {Scalar::Util::looks_like_number($_)} @{$hash->{$attr}}) {
				
				# set object element
				$self->[2] = [@{$hash->{$attr}}];
				
			} else {
				
				# wrong data type
				croak('clut \'gsa\' attribute must be an array reference');
				
			}
			
		# if 'udf'
		} elsif ($attr eq 'udf') {
			
			# if reference to an array of CODE references
			if (ref($hash->{$attr}) eq 'ARRAY' && @{$hash->{$attr}} == grep {ref() eq 'CODE'} @{$hash->{$attr}}) {
				
				# set object element
				$self->[3] = [@{$hash->{$attr}}];
				
			} else {
				
				# wrong data type
				croak('clut \'udf\' attribute must be an array reference');
				
			}
			
		} else {
			
			# invalid attribute
			croak('invalid clut attribute');
			
		}
		
	}
	
}

# read clut data
# note: assumes file handle is positioned at start of clut data
# header information must be read separately by the calling function
# precision is number of bytes per clut element, 1 (8-bit), 2 (16-bit) or 4 (floating point)
# parameters: (ref_to_object, file_handle, output_channels, ref_to_grid_size_array, precision)
sub _read_clut {

	# get parameters
	my ($self, $fh, $co, $gsa, $bytes) = @_;

	# local variables
	my ($rbs, $size, $buf);

	# set read block size
	$rbs = $bytes * $co;

	# initialize clut entries
	$size = 1;

	# for each input channel
	for (@{$gsa}) {
		
		# multiply by grid size
		$size *= $_;
		
	}
	
	# if 8-bit table
	if ($bytes == 1) {
		
		# for each clut entry
		for my $i (0 .. $size - 1) {
			
			# read into buffer
			read($fh, $buf, $rbs);
			
			# unpack buffer and save
			$self->[1][$i] = [map {$_/255} unpack('C*', $buf)];
			
		}
		
	# if 16-bit table
	} elsif ($bytes == 2) {
		
		# for each clut entry
		for my $i (0 .. $size - 1) {
			
			# read into buffer
			read($fh, $buf, $rbs);
			
			# unpack buffer and save
			$self->[1][$i] = [map {$_/65535} unpack('n*', $buf)];
			
		}
		
	# if floating point table
	} elsif ($bytes == 4) {
		
		# for each clut entry
		for my $i (0 .. $size - 1) {
			
			# read into buffer
			read($fh, $buf, $rbs);
			
			# unpack buffer and save
			$self->[1][$i] = [unpack('f>*', $buf)];
			
		}
		
	} else {
		
		# error
		croak('unsupported data size, must be 1, 2 or 4 bytes');
		
	}

	# cache clut for Lapack functions, if defined
	$self->[4] = ICC::Support::Lapack::cache_2D($self->[1]) if (defined($INC{'ICC/Support/Lapack.pm'}));

}

# read clut tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCclut {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $ci, $co, $gsa);

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

	# read grid size array
	read($fh, $buf, 16);

	# make grid size array
	$gsa = [grep {$_} unpack('C16', $buf)];

	# save grid size array
	$self->[2] = [@{$gsa}];

	# read clut
	_read_clut($self, $fh, $co, $gsa, 4);

}

# write clut data
# note: assumes file handle is positioned at start of clut data
# header information must be written separately by the calling function
# precision is number of bytes per clut element, 1 (8-bit), 2 (16-bit) or 4 (floating point)
# parameters: (ref_to_object, file_handle, ref_to_grid_size_array, precision)
sub _write_clut {

	# get parameters
	my ($self, $fh, $gsa, $bytes) = @_;

	# local variables
	my ($size, $buf);

	# initialize clut size
	$size = 1;

	# for each input channel
	for (@{$gsa}) {
		
		# multiply by grid size
		$size *= $_;
		
	}

	# if 8-bit table
	if ($bytes == 1) {
		
		# for each clut entry
		for my $i (0 .. $size - 1) {
			
			# write clut values, limiting and adding 0.5 to round
			print $fh pack('C*', map {$_ < 0 ? 0 : ($_ > 1 ? 255 : $_ * 255 + 0.5)} @{$self->[1][$i]});
			
		}
		
	# if 16-bit table
	} elsif ($bytes == 2) {
		
		# for each clut entry
		for my $i (0 .. $size - 1) {
			
			# write clut values, limiting and adding 0.5 to round
			print $fh pack('n*', map {$_ < 0 ? 0 : ($_ > 1 ? 65535 : $_ * 65535 + 0.5)} @{$self->[1][$i]});
			
		}
		
	# if floating point table
	} elsif ($bytes == 4) {
		
		# for each clut entry
		for my $i (0 .. $size - 1) {
			
			# write clut values
			print $fh pack('f>*', @{$self->[1][$i]});
			
		}
		
	} else {
		
		# error
		croak('unsupported data size, must be 1, 2 or 4 bytes');
		
	}
	
}

# write clut tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCclut {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($gsa, $ci, $co, @mat);

	# get grid size array
	$gsa = $self->[2];

	# get number of input channels
	$ci = @{$gsa};

	# get number of output channels
	$co = @{$self->[1][0]};

	# validate number input channels (1 to 15)
	($ci > 0 && $ci < 16) || croak('unsupported number of input channels');

	# validate number output channels (1 to 15)
	($co > 0 && $co < 16) || croak('unsupported number of output channels');

	# for each possible input channel
	for my $i (0 .. 15) {
		
		# set grid size
		$mat[$i] = $gsa->[$i] || 0;
		
	}

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write 'clut' header
	print $fh pack('a4 x4 n2 C16', 'clut', $ci, $co, @mat);

	# write clut
	_write_clut($self, $fh, $gsa, 4);

}

1;