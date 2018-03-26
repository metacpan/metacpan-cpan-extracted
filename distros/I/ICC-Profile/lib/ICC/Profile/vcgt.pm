package ICC::Profile::vcgt;

use strict;
use Carp;

our $VERSION = 0.12;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# create new vcgt tag object
# parameters: ()
# parameters: (ref_to_array_of_curv_objects)
# parameters: (ref_to_3x3_parameter_array)
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty vcgt object
	my $self = [
		{},   # object header
		[[]]  # array
	];

	# if parameter supplied
	if (@_) {
		
		# if one parameter, a reference to an array of 'curv' objects
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {UNIVERSAL::isa($_, 'ICC::Profile::curv')} @{$_[0]}) {
			
			# verify one or three objects
			(@{$_[0]} == 1 || @{$_[0]} == 3) || croak('array must contain one or three \'curv\' objects');
			
			# copy array
			$self->[1] = [@{shift()}];
			
		# if one parameter, a reference to a 2-D array
		} elsif (@_ == 1 && (ref($_[0]) eq 'ARRAY') && @{$_[0]} == grep {ref() eq 'ARRAY'} @{$_[0]}) {
			
			# verify 3x3 scalar array
			(3 == @{$_[0]} && 3 == @{$_[0][0]} && 3 == grep {! ref()} @{$_[0][0]}) || croak('array must contain 3x3 scalar array');
			
			# copy array
			$self->[1] = Storable::dclone(shift());
			
		} else {
			
			# error
			croak('invalid parameter(s) for new \'vcgt\' object');
			
		}
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create vcgt tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	my $self = [
		{},   # object header
		[[]]  # array
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read vcgt data from profile
	_readICCvcgt($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes vcgt tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write vcgt data to profile
	_writeICCvcgt($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# local variables
	my ($channels, $count, $size);

	# if table
	if (UNIVERSAL::isa($self->[1][0], 'ICC::Profile::curv') && @{$self->[1][0]->array()} > 1) {
		
		# get channels
		$channels = @{$self->[1]};
		
		# get entryCount
		$count = @{$self->[1][0]->array()};
		
		# get entrySize
		$size = defined($self->[0]{'entrySize'}) ? $self->[0]{'entrySize'} : 2;
		
		# return size
		return(18 + $channels * $count * $size);
		
	# if function
	} else {
		
		# return size
		return(48);
		
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
# parameters: (array_input_values -or- ref_to_input_array)
# returns: (array_output_values -or- ref_to_output-array)
sub transform {
	
	# get object reference
	my ($self) = shift();
	
	# if one input parameter, an array reference
	if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
		
		# transform the array structure
		_crawl($self, 0, $_[0], my $out = []);
		
		# return output reference
		return($out);
		
	# if one input parameter, a Math::Matrix object
	} elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'Math::Matrix')) {
		
		# transform the array structure
		_crawl($self, 0, $_[0], my $out = bless([], 'Math::Matrix'));
		
		# return output reference
		return($out);
		
	} else {
		
		# if caller expects array
		if (wantarray) {
			
			# return array
			return(_transform($self, 0, @_));
			
		} else {
			
			# transform array
			my @out = _transform($self, 0, @_);
			
			# return scalar
			return($out[0]);
			
		}
		
	}

}

# compute inverse curve function
# parameters: (array_input_values -or- ref_to_input_array)
# returns: (array_output_values -or- ref_to_output-array)
sub inverse {
	
	# get object reference
	my ($self) = shift();
	
	# if one input parameter, an array reference
	if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
		
		# transform the array structure
		_crawl($self, 1, $_[0], my $out = []);
		
		# return output reference
		return($out);
		
	# if one input parameter, a Math::Matrix object
	} elsif (@_ == 1 && UNIVERSAL::isa($_[0], 'Math::Matrix')) {
		
		# transform the array structure
		_crawl($self, 1, $_[0], my $out = bless([], 'Math::Matrix'));
		
		# return output reference
		return($out);
		
	} else {
		
		# if caller expects array
		if (wantarray) {
			
			# return array
			return(_transform($self, 1, @_));
			
		} else {
			
			# transform array
			my @out = _transform($self, 1, @_);
			
			# return scalar
			return($out[0]);
			
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

# recursive transform
# array structure is traversed until scalar arrays are found and transformed
# parameters: (object_reference, direction, input_array_reference, output_array_reference)
sub _crawl {
	
	# get parameters
	my ($self, $dir, $in, $out) = @_;
	
	# if input is a vector (reference to a scalar array)
	if (@{$in} == grep {! ref()} @{$in}) {
		
		# transform input vector and copy to output
		@{$out} = _transform($self, $dir, @{$in});
		
	} else {
		
		# for each input element
		for my $i (0 .. $#{$in}) {
			
			# if an array reference
			if (ref($in->[$i]) eq 'ARRAY') {
				
				# transform next level
				_crawl($self, $dir, $in->[$i], $out->[$i] = []);
				
			} else {
				
				# error
				croak('invalid transform input');
				
			}
			
		}
		
	}
	
}

# transform input value array (vector)
# direction: 0 - normal, 1 - inverse
# parameters: (object_reference, direction, input_value_array)
# returns: (output_value_array)
sub _transform {

	# get parameters
	my ($self, $dir, @in) = @_;

	# local variables
	my (@out);

	# verify inputs are all scalars
	(@in == grep {! ref()} @in) || croak('invalid transform input');

	# verify number of inputs equals number of channels
	(@in == @{$self->[1]}) || croak('wrong number of input values');

	# for each channel
	for my $i (0 .. $#{$self->[1]}) {
		
		# if 'curv' object
		if (UNIVERSAL::isa($self->[1][$i], 'ICC::Profile::curv')) {
			
			# transform using 'curv' method
			$out[$i] = $self->[1][$i]->_transform($dir, $in[$i]);
			
		} else {
			
			# if normal direction
			if ($dir == 0) {
				
				# forward transform using formula (out = min + (max - min) * input^gamma)
				$out[$i] = $self->[1][$i][1] + ($self->[1][$i][2] - $self->[1][$i][1]) * $in[$i]**$self->[1][$i][0];
				
			} else {
				
				# reverse transform using formula (out = ((input - min)/(max - min))^(1/gamma))
				$out[$i] = (($in[$i] - $self->[1][$i][1])/($self->[1][$i][2] - $self->[1][$i][1]))**(1/$self->[1][$i][0]);
				
			}
			
		}
		
	}

	# return output array
	return(@out);

}

# read vcgt tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCvcgt {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($tagType, $buf, $channels, $count, $size, @table);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read first 12 bytes
	read($fh, $buf, 12);

	# unpack tagType (0 = cmVideoCardGammaTableType, 1 = cmVideoCardGammaFormulaType)
	$tagType = unpack('x8 N', $buf);

	# if table
	if ($tagType == 0) {
		
		# read 6 bytes
		read($fh, $buf, 6);
		
		# unpack channels, entryCount, entrySize
		($channels, $count, $size) = unpack('n3', $buf);
		
		# save entrySize in header hash
		$self->[0]{'entrySize'} = $size;
		
		# for each channel (gray or RGB)
		for my $i (0 .. $channels - 1) {
			
			# read table data
			read($fh, $buf, $count * $size);
			
			# if 8-bit
			if ($size == 1) {
				
				# unpack table
				@table = unpack('C*', $buf);
				
				# save as 'curv' object
				$self->[1][$i] = ICC::Profile::curv->new([map {$_/255} @table]);
				
			# else 16-bit
			} else {
				
				# unpack table
				@table = unpack('n*', $buf);
				
				# save as 'curv' object
				$self->[1][$i] = ICC::Profile::curv->new([map {$_/65535} @table]);
				
			}
			
		}
		
	# if formula
	} elsif ($tagType == 1) {
		
		# for each RGB
		for my $i (0 .. 2) {
			
			# read 12 bytes
			read($fh, $buf, 12);
			
			# unpack gamma, min, max (s15Fixed16Number values)
			$self->[1][$i] = [ICC::Shared::s15f162v(unpack('N3', $buf))];
			
		}
		
	} else {
		
		# error
		croak('invalid \'vcgt\' tagType');
		
	}
	
}

# write vcgt tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCvcgt {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($tagType, $channels, $count, $size, @table, $gamma);

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# determine tagType (0 = cmVideoCardGammaTableType, 1 = cmVideoCardGammaFormulaType)
	$tagType = (UNIVERSAL::isa($self->[1][0], 'ICC::Profile::curv') && @{$self->[1][0]->array()} > 1) ? 0 : 1;

	# write signature and tagType
	print $fh pack('a4 x4 N', 'vcgt', $tagType);

	# if table
	if ($tagType == 0) {
		
		# get channels
		$channels = @{$self->[1]};
		
		# get entryCount
		$count = @{$self->[1][0]->array()};
		
		# if entrySize is 8-bit
		$size = (defined($self->[0]{'entrySize'}) && $self->[0]{'entrySize'} == 1) ? 1 : 2;
		
		# write channels, entryCount, entrySize
		print $fh pack('n3', $channels, $count, $size);
		
		# for each channel (gray or RGB)
		for my $i (0 .. $channels - 1) {
			
			# if 8-bit
			if ($size == 1) {
				
				# write table limiting values, converting to 8-bit, adding 0.5 to round
				print $fh pack('C*', map {$_ < 0 ? 0 : ($_ > 1 ? 255 : $_ * 255 + 0.5)} @{$self->[1][$i]->array()});
				
			# else 16-bit
			} else {
				
				# write table limiting values, converting to 16-bit, adding 0.5 to round
				print $fh pack('n*', map {$_ < 0 ? 0 : ($_ > 1 ? 65535 : $_ * 65535 + 0.5)} @{$self->[1][$i]->array()});
				
			}
			
		}
		
	# if formula
	} else {
		
		# if gamma type 'curv' objects
		if (UNIVERSAL::isa($self->[1][0], 'ICC::Profile::curv')) {
			
			# for each RGB
			for my $i (0 .. 2) {
				
				# get 'curv' object index (could be just one 'curv')
				my $j = defined($self->[1][$i]) ? $i : 0;
				
				# get gamma (use 1.0 if undefined)
				$gamma = defined($self->[1][$j]->array->[0]) ? $self->[1][$j]->array->[0] : 1;
				
				# write gamma, min, max (s15Fixed16Number values)
				print $fh pack('N3', ICC::Shared::v2s15f16($gamma, 0, 1));
				
			}
			
		# if numeric array
		} else {
			
			# for each RGB
			for my $i (0 .. 2) {
				
				# write gamma, min, max (s15Fixed16Number values)
				print $fh pack('N3', ICC::Shared::v2s15f16(@{$self->[1][$i]}));
				
			}
			
		}
		
	}
	
}

1;