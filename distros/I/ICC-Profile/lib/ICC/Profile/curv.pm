package ICC::Profile::curv;

use strict;
use Carp;

our $VERSION = 2.11;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# use POSIX math
use POSIX ();

# create new 'curv' tag object
# with no parameters, 'curv' has identity response
# if array has one value, 'curv' has gamma response (256 = gamma 1)
# if array has multiple values, 'curv' is a linear piecewise function (range 0 - 1)
# parameters: ([ref_to_array])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty curv object
	my $self = [
		{},    # object header
		[]     # curve array
	];

	# if parameter supplied
	if (@_) {
		
		# verify array reference
		(ref($_[0]) eq 'ARRAY') || croak('not an array reference');
		
		# copy array
		$self->[1] = [@{shift()}];
		
	}

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);

}

# create inverse 'curv' object
# returns: (ref_to_object)
sub inv {

	# get object
	my $self = shift();

	# local variable
	my ($array);

	# if identity curve
	if (@{$self->array()} == 0) {
		
		# return identity curve
		return(ICC::Profile::curv->new());
		
	# if gamma curve
	} elsif (@{$self->array()} == 1) {
		
		# verify gamma > 0
		($self->array->[0] > 0) || croak('gamma must be > 0');
		
		# return inverse gamma curve
		return(ICC::Profile::curv->new([65536/$self->array->[0]]));
		
	# if LUT curve
	} else {
		
		# for each point
		for my $i (0 .. 4095) {
			
			# compute inverse curve value
			$array->[$i] = $self->inverse($i/4095);
			
		}
		
		# return inverse curve
		return(ICC::Profile::curv->new($array));
		
	}
	
}

# get/set array reference
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
		$self->[1] = shift();
		
	}

	# return array reference
	return($self->[1]);

}

# compute curve function
# domain/range is (0 - 1)
# parameters: (input_value)
# returns: (output_value)
sub transform {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($array, $upper, $ix, $ir);

	# get array reference
	$array = $self->[1];

	# get array upper subscript
	$upper = $#{$array};

	# if array size == 0 (identity)
	if (@{$array} == 0) {
		
		# return input value
		return($in);
		
	# if array size == 1 (gamma function)
	} elsif (@{$array} == 1) {
		
		# if gamma == 1
		if ($array->[0] == 256) {
			
			# return input value
			return($in);
			
		} else {
			
			# return x^gamma
			return($in > 0 ? $in**($array->[0]/256) : 0);
			
		}
		
	} else {
		
		# compute lower bound index
		$ix = POSIX::floor($in * $upper);
		
		# limit lower bound index
		$ix = $ix < 0 ? 0 : ($ix > ($upper - 1) ? $upper - 1 : $ix);
		
		# compute interpolation ratio
		$ir = $in * $upper - $ix;
		
		# return value (linear interpolation)
		return(((1 - $ir) * $array->[$ix] + $ir * $array->[$ix + 1]));
		
	}
	
}

# compute inverse curve function
# domain/range is (0 - 1)
# parameters: (input_value)
# returns: (output_value)
sub inverse {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($array, $upper, $ix, $ir);

	# get array reference
	$array = $self->[1];

	# get array upper subscript
	$upper = $#{$array};

	# if array size == 0 (identity)
	if (@{$array} == 0) {
		
		# return input value
		return($in);
		
	# if array size = 1 (gamma function)
	} elsif (@{$array} == 1) {
		
		# if gamma = 1
		if ($array->[0] == 256) {
			
			# return input value
			return($in);
			
		} else {
			
			# return y^(1/gamma)
			return($in > 0 ? $in**(256/$array->[0]) : 0);
			
		}
		
	} else {
		
		# find array interval containing input value
		$ix = _binsearch($array, $in);
		
		# compute array interval ratio
		$ir = ($in - $array->[$ix])/($array->[$ix + 1] - $array->[$ix]);
		
		# return value
		return(($ix + $ir)/$upper);
		
	}
	
}

# compute curve derivative
# domain is (0 - 1)
# parameters: (input_value)
# returns: (derivative_value)
sub derivative {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($array, $upper, $ix, $ir);

	# get array reference
	$array = $self->[1];

	# get array upper subscript
	$upper = $#{$array};

	# if array size == 0 (identity)
	if (@{$array} == 0) {
		
		# return value
		return(1);
		
	# if array size == 1 (gamma curve)
	} elsif (@{$array} == 1) {
		
		# if gamma == 1
		if ($array->[0] == 256) {
			
			# return 1
			return(1);
			
		} else {
			
			# return gamma * x^(gamma - 1)
			return($in > 0 ? ($array->[0]/256) * $in**($array->[0]/256 - 1) : 0);
			
		}
		
	} else {
		
		# compute lower bound index
		$ix = POSIX::floor($in * $upper);
		
		# limit lower bound index
		$ix = $ix < 0 ? 0 : ($ix > ($upper - 1) ? $upper - 1 : $ix);
		
		# return value
		return(($array->[$ix + 1] - $array->[$ix]) * $upper);
		
	}
	
}

# create curv tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty curv object
	my $self = [
		{},    # object header
		[]     # curve array
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read curv data from profile
	_readICCcurv($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes curv tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write curv data to profile
	_writeICCcurv($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# return size
	return(12 + @{$self->[1]} * 2);

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

# directional derivative
# nominal domain (0 - 1)
# direction: 0 - normal, 1 - inverse
# parameters: (object_reference, direction, input_value)
# returns: (derivative_value)
sub _derivative {

	# get parameters
	my ($self, $dir, $in) = @_;

	# if inverse transform
	if ($dir) {
		
		# compute derivative
		my $d = derivative($self, $in);
		
		# if non-zero
		if ($d) {
			
			# return inverse
			return(1/$d);
			
		} else {
			
			# error
			croak('infinite derivative');
			
		}
		
	} else {
		
		# return derivative
		return(derivative($self, $in));
		
	}
	
}

# directional transform
# nominal domain (0 - 1)
# direction: 0 - normal, 1 - inverse
# parameters: (object_reference, direction, input_value)
# returns: (output_value)
sub _transform {

	# get parameters
	my ($self, $dir, $in) = @_;

	# if inverse transform
	if ($dir) {
		
		# return inverse
		return(inverse($self, $in));
		
	} else {
		
		# return transform
		return(transform($self, $in));
		
	}
	
}

# binary search
# finds array interval containing value
# assumes values are monotonic
# parameters: (ref_to_array, value)
# returns: (lower_index)
sub _binsearch { 

	# get parameters
	my ($xref, $v) = @_;

	# local variables
	my ($k, $klo, $khi);

	# set low and high indices
	$klo = 0;
	$khi = $#{$xref};

	# if values are increasing
	if ($xref->[-1] > $xref->[0]) {
		
		# repeat until interval is found
		while (($khi - $klo) > 1) {
			
			# compute the midpoint
			$k = int(($khi + $klo)/2);
			
			# if midpoint value > value
			if ($xref->[$k] > $v) {
				
				# set high index to midpoint
				$khi = $k;
				
			} else {
				
				# set low index to midpoint
				$klo = $k;
				
			}
			
		}
		
	# if values are decreasing
	} else {
		
		# repeat until interval is found
		while (($khi - $klo) > 1) {
			
			# compute the midpoint
			$k = int(($khi + $klo)/2);
			
			# if midpoint value < value
			if ($xref->[$k] < $v) {
				
				# set high index to midpoint
				$khi = $k;
				
			} else {
				
				# set low index to midpoint
				$klo = $k;
				
			}
			
		}
		
	}

	# return low index
	return ($klo);

}

# read curv tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCcurv {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $cnt);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag type signature and count
	read($fh, $buf, 12);

	# unpack count
	$cnt = unpack('x8 N', $buf);

	# if count == 1 (gamma)
	if ($cnt == 1) {
		
		# read gamma
		read($fh, $buf, 2);
		
		# unpack gamma
		$self->[1] = [unpack('n', $buf)];
		
	# if count > 1
	} elsif ($cnt > 1) {
		
		# read array values
		read($fh, $buf, 2 * $cnt);
		
		# unpack array values
		$self->[1] = [map {$_/65535} unpack('n*', $buf)];
		
	}
	
}

# write curv tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCcurv {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag type signature and count
	print $fh pack('a4 x4 N', 'curv', scalar(@{$self->[1]}));

	# if count == 1 (gamma)
	if (@{$self->[1]} == 1) {
		
		# write gamma
		print $fh pack('n*', $self->[1][0]);
		
	# if count > 1
	} elsif (@{$self->[1]} > 1){
		
		# write array, limiting values and adding 0.5 to round
		print $fh pack('n*', map {$_ < 0 ? 0 : ($_ > 1 ? 65535 : $_ * 65535 + 0.5)} @{$self->[1]});
		
	}
	
}

1;