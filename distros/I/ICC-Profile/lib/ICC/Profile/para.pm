package ICC::Profile::para;

use strict;
use Carp;

our $VERSION = 0.41;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# parameter count by function type
our @Np = (1, 3, 4, 5, 7);

# create new 'para' tag object
# parameters: ([ref_to_array])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty para object
	my $self = [
				{},		# object header
				[]		# parameter array
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

# create inverse 'para' object
# returns: (ref_to_object)
sub inv {

	# get object
	my $self = shift();

	# get parameter array
	my @p = @{$self->[1]};

	# validate parameters
	($p[1]) || croak('invalid gamma value');
	($p[2]) || croak('invalid a value') if ($p[0] > 0);
	($p[4]) || croak('invalid c value') if ($p[0] > 2);

	# if type 0
	if ($p[0] == 0) {
		
		# return inverse curve [0, γ]
		return(ICC::Profile::para->new([0, 1/$p[1]]));
		
	# if type 1
	} elsif ($p[0] == 1) {
		
		# return inverse curve [2, γ, a, b, c]
		return(ICC::Profile::para->new([2, 1/$p[1], 1/$p[2]**$p[1], 0, -$p[3]/$p[2]]));
		
	# if type 2
	} elsif ($p[0] == 2) {
		
		# return inverse curve [2, γ, a, b, c]
		return(ICC::Profile::para->new([2, 1/$p[1], 1/$p[2]**$p[1], -$p[4]/$p[2]**$p[1], -$p[3]/$p[2]]));
		
	# if type 3
	} elsif ($p[0] == 3) {
		
		# return inverse curve [4, γ, a, b, c, d, e, f]
		return(ICC::Profile::para->new([4, 1/$p[1], 1/$p[2]**$p[1], 0, 1/$p[4], $p[4] * $p[5], -$p[3]/$p[2], 0]));
		
	# if type 4
	} elsif ($p[0] == 4) {
		
		# return inverse curve [4, γ, a, b, c, d, e, f]
		return(ICC::Profile::para->new([4, 1/$p[1], 1/$p[2]**$p[1], -$p[6]/$p[2]**$p[1], 1/$p[4], $p[4] * $p[5] + $p[7], -$p[3]/$p[2], -$p[7]/$p[4]]));
		
	} else {
		
		# error
		croak('invalid \'para\' object');
		
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
		
		# verify function type (integer, 0 - 4)
		($type == int($type) && $type >= 0 && $type <= 4) || croak('invalid function type');
		
		# verify number of parameters
		($#{$array} == $Np[$type]) || croak('wrong number of parameters');
		
		# set array reference
		$self->[1] = $array;
		
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
	my ($a, $type);

	# get parameter array
	$a = $self->[1];

	# get function type
	$type = $a->[0];

	# function type 0
	if ($type == 0) {
		
		# if gamma = 1
		if ($a->[1] == 1) {
			
			# return x
			return($in);
			
		} else {
			
			# if input > 0
			if ($in > 0) {
				
				# return x**g
				return($in ** $a->[1]);
				
			} else {
				
				# return 0
				return(0);
				
			}
			
		}
		
	# function type 1
	} elsif ($type == 1) {
		
		# if input ≥ -b/a
		if ($in >= - $a->[3]/$a->[2]) {
			
			# return (ax + b)**g
			return(($a->[2] * $in + $a->[3]) ** $a->[1]);
			
		} else {
			
			# return 0
			return(0);
			
		}
		
	# function type 2
	} elsif ($type == 2) {
		
		# if input ≥ -b/a
		if ($in >= - $a->[3]/$a->[2]) {
			
			# return (ax + b)**g + c
			return(($a->[2] * $in + $a->[3]) ** $a->[1] + $a->[4]);
			
		} else {
			
			# return c
			return($a->[4]);
			
		}
		
	# function type 3
	} elsif ($type == 3) {
		
		# if input ≥ d
		if ($in >= $a->[5]) {
			
			# return (ax + b)**g
			return(($a->[2] * $in + $a->[3]) ** $a->[1]);
			
		} else {
			
			# return cx
			return($a->[4] * $in);
			
		}
		
	# function type 4
	} elsif ($type == 4) {
		
		# if input ≥ d
		if ($in >= $a->[5]) {
			
			# return (ax + b)**g + e
			return(($a->[2] * $in + $a->[3]) ** $a->[1] + $a->[6]);
			
		} else {
			
			# return (cx + f)
			return($a->[4] * $in + $a->[7]);
			
		}
		
	} else {
		
		# error
		croak('invalid parametric function type');
		
	}
	
}

# compute curve inverse
# domain/range is (0 - 1)
# parameters: (input_value)
# returns: (output_value)
sub inverse {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($a, $type);

	# get parameter array reference
	$a = $self->[1];

	# get function type
	$type = $a->[0];

	# function type 0
	if ($type == 0) {
		
		# if gamma = 1
		if ($a->[1] == 1) {
			
			# return y
			return($in);
			
		} else {
			
			# if input > 0
			if ($in > 0) {
				
				# return y**(1/g)
				return($in ** (1/$a->[1]));
				
			} else {
				
				# return 0
				return(0);
				
			}
			
		}
		
	# function type 1
	} elsif ($type == 1) {
		
		# if input ≥ 0
		if ($in >= 0) {
			
			# return (y**(1/g) - b)/a
			return(($in ** (1/$a->[1]) - $a->[3])/$a->[2]);
			
		} else {
			
			# return -b/a
			return(- $a->[3]/$a->[2]);
			
		}
		
	# function type 2
	} elsif ($type == 2) {
		
		# if input ≥ c
		if ($in >= $a->[4]) {
			
			# return ((y - c)**(1/g) - b)/a
			return((($in - $a->[4]) ** (1/$a->[1]) - $a->[3])/$a->[2]);
			
		} else {
			
			# return -b/a
			return(- $a->[3]/$a->[2]);
			
		}
		
	# function type 3
	} elsif ($type == 3) {
		
		# if input ≥ cd
		if ($in >= ($a->[4] * $a->[5])) {
			
			# return (y**(1/g) - b)/a
			return(($in ** (1/$a->[1]) - $a->[3])/$a->[2]);
			
		} else {
			
			# return y/c
			return($in/$a->[4]);
			
		}
		
	# function type 4
	} elsif ($type == 4) {
		
		# if input ≥ cd + f
		if ($in >= ($a->[4] * $a->[5] + $a->[7])) {
			
			# return ((y - e)**(1/g) - b)/a
			return((($in - $a->[6]) ** (1/$a->[1]) - $a->[3])/$a->[2]);
			
		} else {
			
			# return (y - f)/c
			return(($in - $a->[7])/$a->[4]);
			
		}
		
	} else {
		
		# error
		croak('invalid parametric function type');
		
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
	my ($a, $type);

	# get parameter array
	$a = $self->[1];

	# get function type
	$type = $a->[0];

	# function type 0
	if ($type == 0) {
		
		# if gamma = 1
		if ($a->[1] == 1) {
			
			# return 1
			return(1);
			
		} else {
			
			# if input > 0
			if ($in > 0) {
				
				# return derivative
				return($a->[1] * $in ** ($a->[1] - 1));
				
			} else {
				
				# return 0
				return(0);
				
			}
			
		}
		
	# function type 1
	} elsif ($type == 1) {
		
		# if input ≥ -b/a
		if ($in >= - $a->[3]/$a->[2]) {
			
			# return ga(ax + b)**(g - 1)
			return($a->[1] * $a->[2] * ($a->[2] * $in + $a->[3]) ** ($a->[1] - 1));
			
		} else {
			
			# return 0
			return(0);
			
		}
		
	# function type 2
	} elsif ($type == 2) {
		
		# if input ≥ -b/a
		if ($in >= - $a->[3]/$a->[2]) {
			
			# return ga(ax + b)**(g - 1)
			return($a->[1] * $a->[2] * ($a->[2] * $in + $a->[3]) ** ($a->[1] - 1));
			
		} else {
			
			# return 0
			return(0);
			
		}
		
	# function type 3
	} elsif ($type == 3) {
		
		# if input ≥ d
		if ($in >= $a->[5]) {
			
			# return ga(ax + b)**(g - 1)
			return($a->[1] * $a->[2] * ($a->[2] * $in + $a->[3]) ** ($a->[1] - 1));
			
		} else {
			
			# return c
			return($a->[4]);
			
		}
		
	# function type 4
	} elsif ($type == 4) {
		
		# if input ≥ d
		if ($in >= $a->[5]) {
			
			# return ga(ax + b)**(g - 1)
			return($a->[1] * $a->[2] * ($a->[2] * $in + $a->[3]) ** ($a->[1] - 1));
			
		} else {
			
			# return c
			return($a->[4]);
			
		}
		
	} else {
		
		# error
		croak('invalid parametric function type');
		
	}
	
}

# create para tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty para object
	my $self = [
				{},		# object header
				[]		# parameter array
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read para data from profile
	_readICCpara($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes para tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write para data to profile
	_writeICCpara($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# return size
	return(12 + $Np[$self->[1][0]] * 4);
	
}

# make table for 'curv' objects
# assumes curve domain/range is (0 - 1)
# parameters: (number_of_table_entries, [direction])
# returns: (ref_to_table_array)
sub table {

	# get parameters
	my ($self, $n, $dir) = @_;

	# local variables
	my ($up, $table);

	# validate number of table entries
	($n == int($n) && $n >= 2) || carp('invalid number of table entries');

	# array upper index
	$up = $n - 1;

	# for each table entry
	for my $i (0 .. $up) {
		
		# compute table value
		$table->[$i] = _transform($self, $dir, $i/$up);
		
	}

	# return table reference
	return($table);

}

# make 'curv' object
# assumes curve domain/range is (0 - 1)
# parameters: (number_of_table_entries, [direction])
# returns: (ref_to_curv_object)
sub curv {

	# return 'curv' object reference
	return(ICC::Profile::curv->new(table(@_)));

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
		
		# if function type 0
		if ($type == 0) {
			
			# append parameter string
			$s .= sprintf("  function type %d, gamma %.3f\n", @{$self->[1]});
			
		# if function type 1
		} elsif ($type == 1) {
			
			# append parameter string
			$s .= sprintf("  function type %d, gamma %.3f, a %.3f, b %.3f\n", @{$self->[1]});
			
		# if function type 2
		} elsif ($type == 2) {
			
			# append parameter string
			$s .= sprintf("  function type %d, gamma %.3f, a %.3f, b %.3f, c %.3f\n", @{$self->[1]});
			
		# if function type 3
		} elsif ($type == 3) {
			
			# append parameter string
			$s .= sprintf("  function type %d, gamma %.3f, a %.3f, b %.3f, c %.3f, d %.3f\n", @{$self->[1]});
			
		# if function type 4
		} elsif ($type == 4) {
			
			# append parameter string
			$s .= sprintf("  function type %d, gamma %.3f, a %.3f, b %.3f, c %.3f, d %.3f, e %.3f, f %.3f\n", @{$self->[1]});
			
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

# directional parametric partial derivatives
# nominal domain (0 - 1)
# direction: 0 - normal, 1 - inverse
# parameters: (object_reference, direction, input_value)
# returns: (partial_derivative_array)
sub _parametric {
	
	# get parameters
	my ($self, $dir, $in) = @_;
	
	# local variables
	my ($array, $type);
	my ($axb, $dyda, $dydb);
	
	# get parameter array reference
	$array = $self->[1];
	
	# get function type
	$type = $array->[0];
	
	# function type 0
	if ($type == 0) {
		
		# if inverse
		if ($dir) {
			
			# return ∂X/∂γ
			return();
			
		} else {
			
			# return ∂Y/∂γ
			return($in**$array->[1] * log($in));
			
		}
		
	# function type 1
	} elsif ($type == 1) {
		
		# if inverse
		if ($dir) {
			
			# return ∂X/∂γ, ∂X/∂a, ∂X/∂b
			return();
			
		} else {
			
			# compute (aX + b) value
			$axb = $array->[2] * $in + $array->[3];
			
			# if X >= -b/a
			if ($axb >= 0) {
				
				# compute ∂Y/∂b
				$dydb = $array->[1] * $axb**($array->[1] - 1);
				
				# compute ∂Y/∂a
				$dyda = $dydb * $in;
				
				# return ∂Y/∂γ, ∂Y/∂a, ∂Y/∂b
				return($axb**$array->[1] * log($axb), $dyda, $dydb);
				
			} else {
				
				# return ∂Y/∂γ, ∂Y/∂a, ∂Y/∂b
				return(0, 0, 0);
				
			}
			
		}
		
	# function type 2
	} elsif ($type == 2) {
		
		# if inverse
		if ($dir) {
			
			# return ∂X/∂γ, ∂X/∂a, ∂X/∂b, ∂X/∂c
			return();
			
		} else {
			
			# compute (aX + b) value
			$axb = $array->[2] * $in + $array->[3];
			
			# if X >= -b/a
			if ($axb >= 0) {
				
				# compute ∂Y/∂b
				$dydb = $array->[1] * $axb**($array->[1] - 1);
				
				# compute ∂Y/∂a
				$dyda = $dydb * $in;
				
				# return ∂Y/∂γ, ∂Y/∂a, ∂Y/∂b, ∂Y/∂c
				return($axb**$array->[1] * log($axb), $dyda, $dydb, 1);
				
			} else {
				
				# return ∂Y/∂γ, ∂Y/∂a, ∂Y/∂b, ∂Y/∂c
				return(0, 0, 0, 1);
				
			}
			
		}
		
	# function type 3
	} elsif ($type == 3) {
		
		# if inverse
		if ($dir) {
			
			# return ∂X/∂γ, ∂X/∂a, ∂X/∂b, ∂X/∂c
			return();
			
		} else {
			
			# if X >= d
			if ($in >= $array->[5]) {
				
				# compute (aX + b) value
				$axb = $array->[2] * $in + $array->[3];
				
				# compute ∂Y/∂b
				$dydb = $array->[1] * $axb**($array->[1] - 1);
				
				# compute ∂Y/∂a
				$dyda = $dydb * $in;
				
				# return ∂Y/∂γ, ∂Y/∂a, ∂Y/∂b, ∂Y/∂c
				return($axb**$array->[1] * log($axb), $dyda, $dydb, 0);
				
			} else {
				
				# return ∂Y/∂γ, ∂Y/∂a, ∂Y/∂b, ∂Y/∂c
				return(0, 0, 0, $in);
				
			}
			
		}
		
	# function type 4
	} elsif ($type == 4) {
		
		# if inverse
		if ($dir) {
			
			# return ∂X/∂γ, ∂X/∂a, ∂X/∂b, ∂X/∂c, ∂X/∂e, ∂X/∂f
			return();
			
		} else {
			
			# if X >= d
			if ($in >= $array->[5]) {
				
				# compute (aX + b) value
				$axb = $array->[2] * $in + $array->[3];
				
				# compute ∂Y/∂b
				$dydb = $array->[1] * $axb**($array->[1] - 1);
				
				# compute ∂Y/∂a
				$dyda = $dydb * $in;
				
				# return ∂Y/∂γ, ∂Y/∂a, ∂Y/∂b, ∂Y/∂c, ∂Y/∂e, ∂Y/∂f
				return($axb**$array->[1] * log($axb), $dyda, $dydb, 0, 1, 0);
				
			} else {
				
				# return ∂Y/∂γ, ∂Y/∂a, ∂Y/∂b, ∂Y/∂c, ∂Y/∂e, ∂Y/∂f
				return(0, 0, 0, $in, 0, 1);
				
			}
			
		}
		
	} else {
		
		# error
		croak('invalid parametric function type');
		
	}
	
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

# read para tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCpara {

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
	defined($cnt = $Np[$fun]) || croak('invalid function type when reading \'para\' tag');

	# read parameter values
	read($fh, $buf, $cnt * 4);

	# unpack the values
	$self->[1] = [$fun, map {($_ & 0x80000000) ? $_/65536 - 65536 : $_/65536} unpack("N$cnt", $buf)];

}

# write para tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCpara {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# verify object structure
	($self->[1][0] == int($self->[1][0]) && defined($Np[$self->[1][0]]) && $Np[$self->[1][0]] == $#{$self->[1]}) || croak('invalid function data when writing \'para\' tag');

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag
	print $fh pack('a4 x4 n x2 N*', 'para', $self->[1][0], map {$_ * 65536} @{$self->[1]}[1 .. $#{$self->[1]}]);

}

1;