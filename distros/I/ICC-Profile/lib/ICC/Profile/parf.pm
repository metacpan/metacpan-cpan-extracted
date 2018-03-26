package ICC::Profile::parf;

use strict;
use Carp;

our $VERSION = 0.2;

# revised 2016-10-22
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# parameter count by function type
our @Np = (4, 5, 5, 3, 4, 4);

# create new parf tag object
# parameters: ([ref_to_array])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty parf object
	my $self = [
		{},    # object header
		[]     # parameter array
	];

	# if parameter supplied
	if (@_) {
		
		# verify array reference
		(ref($_[0]) eq 'ARRAY') || croak('not an array reference');
		
		# verify function type
		($_[0][0] == int($_[0][0]) && defined($Np[$_[0][0]])) || croak('invalid function type');
		
		# verify number of parameters
		($#{$_[0]} == $Np[$_[0][0]]) || croak('wrong number of parameters');
		
		# copy array
		$self->[1] = [@{shift()}];
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create parf tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty parf object
	my $self = [
		{},    # object header
		[]     # parameter array
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read parf data from profile
	_readICCparf($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes parf tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write parf data to profile
	_writeICCparf($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# return size
	return(12 + 4 * $Np[$self->[1][0]]);

}

# compute curve function
# parameters: (input_value)
# returns: (output_value)
sub transform {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($a, $type, $pow);

	# get parameter array
	$a = $self->[1];

	# get function type
	$type = $a->[0];

	# function type 0
	if ($type == 0) {
		
		# return value Y = (aX + b)**γ + c
		return(($a->[2] * $in + $a->[3])**$a->[1] + $a->[4]);
		
	# function type 1
	} elsif ($type == 1) {
		
		# return value Y = a log10(bX**γ + c) + d
		return($a->[2] * POSIX::log10($a->[3] * $in**$a->[1] + $a->[4]) + $a->[5]);
		
	# function type 2
	} elsif ($type == 2) {
		
		# return value Y = ab**(cX+d) + e
		return($a->[1] * $a->[2]**($a->[3] * $in + $a->[4]) + $a->[5]);
		
	# function type 3
	} elsif ($type == 3) {
		
		# return value Y = (aX + b)/(cX + 1)
		return(($a->[1] * $in + $a->[2])/($a->[3] * $in + 1));
		
	# function type 4
	} elsif ($type == 4) {
		
		# return value Y = (aX + b)/(cX**γ + 1)**(1/γ)
		return(($a->[2] * $in + $a->[3])/($a->[4] * $in**$a->[1] + 1)**(1/$a->[1]));
		
	# function type 5
	} elsif ($type == 5) {
		
		# compute X**γ
		$pow = $in**$a->[1];
		
		# return value Y = (aX**γ + b)/(cX**γ + 1)
		return(($a->[2] * $pow + $a->[3])/($a->[4] * $pow + 1));
		
	} else {
		
		# error
		croak('invalid parametric function type');
		
	}
	
}

# compute curve inverse
# parameters: (input_value)
# returns: (output_value)
sub inverse {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($a, $type);

	# get parameter array
	$a = $self->[1];

	# get function type
	$type = $a->[0];

	# function type 0
	if ($type == 0) {
		
		# return value X = ((Y - c)**(1/γ) - b)/a
		return((($in - $a->[4])**(1/$a->[1]) - $a->[3])/$a->[2]);
		
	# function type 1
	} elsif ($type == 1) {
		
		# return value X = ((10**(Y/a - d/a) - c)/b)**(1/γ)
		return(((10**($in/$a->[2] - $a->[5]/$a->[2]) - $a->[4])/$a->[3])**(1/$a->[1]));
		
	# function type 2
	} elsif ($type == 2) {
		
		# return value X = (log((Y - e)/a)/log(b) - d)/c
		return((log(($in - $a->[5])/$a->[1])/log($a->[2]) - $a->[4])/$a->[3]);
		
	# function type 3
	} elsif ($type == 3) {
		
		# return value X = (b - Y)/(cY - a)
		return(($a->[2] - $in)/($a->[3] * $in - $a->[1]));
		
	# function type 4
	} elsif ($type == 4) {
		
		# error
		croak('inverse of function type 4 requires numerical solution');
		
	# function type 5
	} elsif ($type == 5) {
		
		# return value X = ((b - Y)/(cY - a))**(1/γ)
		return((($a->[3] - $in)/($a->[4] * $in - $a->[2]))**(1/$a->[1]));
		
	} else {
		
		# error
		croak('invalid parametric function type');
		
	}
	
}

# compute curve derivative
# parameters: (input_value)
# returns: (derivative_value)
sub derivative {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($a, $type, $den);

	# get parameter array
	$a = $self->[1];

	# get function type
	$type = $a->[0];

	# function type 0
	if ($type == 0) {
		
		# return dY/dX = aγ(aX + b)**(γ - 1)
		return($a->[1] == 1 ? $a->[2] : $a->[2] * $a->[1] * ($a->[2] * $in + $a->[3])**($a->[1] - 1));
		
	# function type 1
	} elsif ($type == 1) {
		
		# compute denominator = ln(10) (bX**γ + c)
		$den = ICC::Shared::ln10 * ($a->[3] * $in**$a->[1] + $a->[4]);
		
		# return dY/dX = abγX**(γ - 1)/(ln(10) (bX**γ + c))
		return($den == 0 ? 'inf' : $a->[2] * $a->[3] * $a->[1] * $in**($a->[1] - 1)/$den);
		
	# function type 2
	} elsif ($type == 2) {
			
			# return dY/dX = ac ln(b) b**(cX+d)
			return($a->[1] * $a->[3] * log($a->[2]) * $a->[2]**($a->[3] * $in + $a->[4]));
			
	# function type 3
	} elsif ($type == 3) {
		
		# compute denominator = (cX + 1)**2
		$den = ($a->[3] * $in + 1)**2;
		
		# return value Y = (a - bc)/(cX + 1)**2
		return($den == 0 ? 'inf' : ($a->[1] - $a->[2] * $a->[3])/$den);
		
	# function type 4
	} elsif ($type == 4) {
		
		# compute denominator = (cX**γ + 1)
		$den = ($a->[4] * $in**$a->[1] + 1);
		
		# return value Y = (a - (aX + b) cX**(γ - 1)/((cX**γ + 1)))/(cX**γ + 1)**(1/γ)
		return($den == 0 ? 'inf' : ($a->[2] - ($a->[2] * $in + $a->[3]) * $a->[4] * $in**($a->[1] - 1)/$den)/$den**(1/$a->[1]));
		
	# function type 5
	} elsif ($type == 5) {
		
		# compute denominator = (cX**γ + 1)**2
		$den = ($a->[4] * $in**$a->[1] + 1)**2;
		
		# return value Y = γX**(γ - 1)(a - bc)/(cX**γ + 1)**2
		return($den == 0 ? 'inf' : $a->[1] * $in**($a->[1] - 1) * ($a->[2] - $a->[3] * $a->[4])/$den);
		
	} else {
		
		# error
		croak('invalid parametric function type');
		
	}
	
}

# get/set array reference
# parameters: ([ref_to_array])
# returns: (ref_to_array)
sub array {

	# get object reference
	my $self = shift();
	
	# local variables
	my ($array, $type);
	
	# if parameter
	if (@_) {
		
		# get array reference
		$array = shift();
		
		# verify array reference
		(ref($array) eq 'ARRAY') || croak('not an array reference');
		
		# get function type
		$type = $array->[0];
		
		# verify function type (integer, 0 - 5)
		($type == int($type) && $type >= 0 && $type <= 5) || croak('invalid function type');
		
		# verify number of parameters
		($#{$array} == $Np[$type]) || croak('wrong number of parameters');
		
		# set array reference
		$self->[1] = $array;
		
	}
	
	# return array reference
	return($self->[1]);

}

# print object contents to string
# format is an array structure
# parameter: ([format])
# returns: (string)
sub sdump {

	# get parameters
	my ($self, $p) = @_;

	# local variables
	my ($s, $fmt, $type);

	# resolve parameter to an array reference
	$p = defined($p) ? ref($p) eq 'ARRAY' ? $p : [$p] : [];

	# get format string
	$fmt = defined($p->[0]) && ! ref($p->[0]) ? $p->[0] : 'undef';

	# set string to object ID
	$s = sprintf("'%s' object, (0x%x)\n", ref($self), $self);

	# if object has parameters
	if (defined($type = $self->[1][0])) {
		
		# if function type 0, 4, 5
		if ($type == 0 || $type == 4 || $type == 5) {
			
			# append parameter string
			$s .= sprintf("  function type %d, gamma %.3f, a %.3f, b %.3f, c %.3f\n", @{$self->[1]});
			
		# if function type 1
		} elsif ($type == 1) {
			
			# append parameter string
			$s .= sprintf("  function type %d, gamma %.3f, a %.3f, b %.3f, c %.3f, d %.3f\n", @{$self->[1]});
			
		# if function type 2
		} elsif ($type == 2) {
			
			# append parameter string
			$s .= sprintf("  function type %d, gamma %.3f, a %.3f, b %.3f, c %.3f, d %.3f, e %.3f\n", @{$self->[1]});
			
		# if function type 3
		} elsif ($type == 3) {
			
			# append parameter string
			$s .= sprintf("  function type %d, a %.3f, b %.3f, c %.3f\n", @{$self->[1]});
			
		} else {
			
			# append error string
			$s .= "  invalid function type\n";
			
		}
		
	} else {
	
		# append string
		$s .= "  <empty object>\n";
	
	}

	# return
	return($s);

}

# read parf tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCparf {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $fun, $cnt);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag type signature and function type
	read($fh, $buf, 12);

	# unpack function type
	$fun = unpack('x8 n x2', $buf);

	# get parameter count and verify
	defined($cnt = $Np[$fun]) || croak('invalid function type when reading \'parf\' tag');

	# read parameter values
	read($fh, $buf, $cnt * 4);

	# unpack the values
	$self->[1] = [$fun, unpack('f>*', $buf)];

}

# write parf tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCparf {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# verify object structure
	($self->[1][0] == int($self->[1][0]) && $self->[1][0] >= 0 && $self->[1][0] <= 2 && $Np[$self->[1][0]] == $#{$self->[1]}) || croak('invalid function data when writing \'parf\' tag');

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag
	print $fh pack('a4 x4 n x2 f>*', 'parf', @{$self->[1]});

}

1;
