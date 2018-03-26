package ICC::Profile::mpet;

use strict;
use Carp;

our $VERSION = 0.51;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# use POSIX math
use POSIX ();

# create new mpet object
# array contains processing element objects
# objects must have '_transform' and 'jacobian' methods
# parameters: ([array_ref])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty mpet object
	my $self = [
		{},     # object header
		[],     # processing elements
		0x00    # transform mask
	];

	# if there are parameters
	if (@_) {
		
		# if one parameter, an array reference
		if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
			
			# make new mpet tag
			_new_from_array($self, @_);
			
		} else {
			
			# error
			croak('parameter must be an array reference');
			
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
		
		# for each processing element
		for my $i (0 .. $#{$_[0]}) {
			
			# verify object has processing methods
			($_[0][$i]->can('_transform') && $_[0][$i]->can('jacobian')) || croak('processing element lacks \'transform\' or \'jacobian\' method');
			
			# add processing element
			$self->[1][$i] = $_[0][$i];
			
		}
		
	}

	# return array reference
	return($self->[1]);

}

# get/set transform mask
# bits ... 3-2-1-0 correpsond to ... PE3-PE2-PE1-PE0
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

# create mpet tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty mpet object
	my $self = [
		{},     # object header
		[],     # processing elements
		0x00    # transform mask
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read mpet data from profile
	_readICCmpet($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes mpet tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write mpet data to profile
	_writeICCmpet($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# local variables
	my ($size);

	# set header size
	$size = 16 + 8 * @{$self->[1]};

	# for each processing element
	for my $pel (@{$self->[1]}) {
		
		# add size
		$size += $pel->size();
		
		# adjust to 4-byte boundary
		$size += -$size % 4;
		
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
	return($self->[1][0]->cin());

}

# get number of output channels
# returns: (number)
sub cout {

	# get object reference
	my $self = shift();

	# return
	return($self->[1][-1]->cout());

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

	# set delta limit ('mpet' tags use floating point PCS, so L*a*b* values need greater limit)
	$dlim = $hash->{'inv_dlim'} || ($self->[0]{'input_cs'} eq 'Lab ') ? 50.0 : 0.5;

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

	# for each processing element
	for my $i (0 .. $#{$self->[1]}) {
		
		# if processing element defined, and transform mask bit set
		if (defined($self->[1][$i]) && $self->[2] & 0x01 << $i) {
			
			# transform data
			$data = $self->[1][$i]->_trans1($data, $hash);
			
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
	my ($ci, $co);

	# for each processing element
	for my $i (0 .. $#{$self->[1]}) {
		
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
				($self->[1][$i]->cin() == $co) || croak('\'mpet\' processing element has wrong number of channels');
				
			}
			
		}
		
		# if element has 'cout' method
		if ($self->[1][$i]->can('cout')) {
			
			# set number of output channels
			$co = $self->[1][$i]->cout();
			
		}
		
	}

	# return
	return($ci, $co);

}

# make new mpet tag from array
# array contains processing element objects
# objects must have '_trans1', '_trans2', and 'jacobian' methods
# parameters: (ref_to_object, ref_to_array)
sub _new_from_array {

	# get parameters
	my ($self, $array) = @_;

	# for each processing element
	for my $i (0 .. $#{$array}) {
		
		# verify object has required processing methods
		($array->[$i]->can('_trans1')) || croak('processing element lacks \'_trans1\'method');
		($array->[$i]->can('_trans2')) || croak('processing element lacks \'_trans2\'method');
		($array->[$i]->can('jacobian')) || croak('processing element lacks\'jacobian\' method');
		
		# add processing element
		$self->[1][$i] = $array->[$i];
		
	}

	# check object structure
	_check($self);

}

# read mpet tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCmpet {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, @mft, $table, $tag2, $type, $class, %hash);

	# set tag signature
	$self->[0]{'signature'} = $tag->[0];

	# if 'D2Bx' tag
	if ($tag->[0] =~ m|^D2B[0-2]$|) {
		
		# set input colorspace
		$self->[0]{'input_cs'} = $parent->[1][4];
		
		# set output colorspace
		$self->[0]{'output_cs'} = $parent->[1][5];
		
	# if 'B2Dx' tag
	} elsif ($tag->[0] =~ m|^B2D[0-2]$|) {
		
		# set input colorspace
		$self->[0]{'input_cs'} = $parent->[1][5];
		
		# set output colorspace
		$self->[0]{'output_cs'} = $parent->[1][4];
		
	}

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag header
	read($fh, $buf, 16);

	# unpack header
	@mft = unpack('a4 x4 n2 N', $buf);

	# verify tag signature
	($mft[0] eq 'mpet') or croak('wrong tag type');

	# for each processing element
	for my $i (0 .. $mft[3] - 1) {
		
		# read positionNumber
		read($fh, $buf, 8);
		
		# unpack to processing element tag table
		$table->[$i] = ['mpet', unpack('N2', $buf)];
		
	}

	# clear transform mask
	$self->[2] = 0;

	# for each processing element
	for my $i (0 .. $mft[3] - 1) {
		
		# get tag table entry
		$tag2 = $table->[$i];
		
		# make offset absolute
		$tag2->[1] += $tag->[1];
		
		# if a duplicate tag
		if (exists($hash{$tag2->[1]})) {
			
			# use original tag
			$self->[1][$i] = $hash{$tag2->[1]};
			
		} else {
			
			# seek to start of tag
			seek($fh, $tag2->[1], 0);
			
			# read tag type signature
			read($fh, $type, 4);
			
			# convert non-word characters to underscores
			$type =~ s|\W|_|g;
			
			# form class specifier
			$class = "ICC::Profile::$type";
			
			# if 'class->new_fh' method exists
			if ($class->can('new_fh')) {
				
				# create specific tag object
				$self->[1][$i] = $class->new_fh($self, $fh, $tag2);
				
			} else {
				
				# create generic tag object
				$self->[1][$i] = ICC::Profile::Generic->new_fh($self, $fh, $tag2);
				
				# print warning
				print "processing element $type opened as generic\n";
				
			}
			
			# save tag in hash
			$hash{$tag2->[1]} = $self->[1][$i];
			
		}
		
		# set mask bit
		$self->[2] |= 0x01 << $i;
		
	}

}

# write mpet tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCmpet {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($ci, $co, $n, $offset, $size, @pept, %hash);

	# check object structure
	($ci, $co) = _check($self);

	# set number of processing elements
	$n = @{$self->[1]};

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write 'mpet' header
	print $fh pack('a4 x4 n2 N', 'mpet', $ci, $co, $n);

	# set tag offset
	$offset = 16 + 8 * $n;

	# for each processing element
	for my $i (0 .. $#{$self->[1]}) {
		
		# verify processing element allowed in 'mpet' tag
		(ref($self->[1][$i]) =~ m/^ICC::Profile::(cvst|matf|clut|Generic)$/) || croak('processing element not allowed in \'mpet\' tag');
		
		# if tag not in hash
		if (! exists($hash{$self->[1][$i]})) {
			
			# get size
			$size = $self->[1][$i]->size();
			
			# set table entry and add to hash
			$pept[$i] = $hash{$self->[1][$i]} = [$offset, $size];
			
			# update offset
			$offset += $size;
			
			# adjust to 4-byte boundary
			$offset += -$offset % 4;
			
		} else {
			
			# set table entry
			$pept[$i] = $hash{$self->[1][$i]};
			
		}
		
		# write processing element position entry
		print $fh pack('N2', @{$pept[$i]});
		
	}

	# initialize hash
	%hash = ();

	# for each processing element
	for my $i (0 .. $#{$self->[1]}) {
		
		# if tag not in hash
		if (! exists($hash{$self->[1][$i]})) {
			
			# make offset absolute
			$pept[$i][0] += $tag->[1];
			
			# write tag
			$self->[1][$i]->write_fh($self, $fh, ['mpet', $pept[$i][0], $pept[$i][1]]);
			
			# add key to hash
			$hash{$self->[1][$i]}++;
			
		}
		
	}
	
}

1;