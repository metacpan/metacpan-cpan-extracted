package ICC::Profile::sf32;

use strict;
use Carp;

our $VERSION = 0.22;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# create new sf32 tag object
# input may be 1-D array, 2-D array, or Math::Matrix object
# parameters: ([ref_to_input])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty sf32 object
	my $self = [
				{},		# object header
				[]		# s15f16 array
			];
	
	# if parameter supplied
	if (@_) {
		
		# if one parameter, a reference to a 1-D array
		if (@_ == 1 && ref($_[0]) eq 'ARRAY' && @{$_[0]} == grep {! ref()} @{$_[0]}) {
			
			# copy array
			$self->[1] = [@{shift()}];
			
		# if one parameter, a reference to a 2-D array or Math::Matrix object
		} elsif (@_ == 1 && (ref($_[0]) eq 'ARRAY' || UNIVERSAL::isa($_[0], 'Math::Matrix')) && @{$_[0]} == grep {ref() eq 'ARRAY'} @{$_[0]}) {
			
			# initialize array
			$self->[1] = [];
			
			# for each row
			for (@{$_[0]}) {
				
				# push row values
				push(@{$self->[1]}, @{$_});
				
			}
			
		} else {
			
			# error
			croak('parameter must an array reference (1-D or 2-D)');
			
		}
		
	}

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);

}

# create sf32 tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty sf32 object
	my $self = [
				{},		# object header
				[]		# s15f16 array
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read sf32 data from profile
	_readICCsf32($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes sf32 tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write sf32 data to profile
	_writeICCsf32($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# return size
	return(8 + @{$self->[1]} * 4);
	
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

# get/set matrix
# access array in matrix format
# get parameters: (matrix_columns)
# set parameters: (matrix_object)
# set parameters: (ref_to_2D_array)
# returns: (matrix_object)
sub matrix {

	# get object reference
	my $self = shift();
	
	# local variables
	my ($size, $rows, $cols, $matrix);
	
	# if parameter
	if (@_) {
		
		# if one parameter, a scalar
		if (@_ == 1 && ! ref($_[0])) {
			
			# get array size
			$size = @{$self->[1]};
			
			# get columns
			$cols = shift();
			
			# verify matrix dimensions
			($size && $cols && ($size % $cols == 0)) || croak('invalid matrix dimensions');
			
			# make new empty matrix object
			$matrix = Math::Matrix->new([]);
			
			# compute rows
			$rows = $size/$cols;
			
			# for each row
			for my $i (0 .. $rows - 1) {
				
				# set matrix row
				$matrix->[$i] = [@{$self->[1]}[$i * $cols .. ($i + 1) * $cols - 1]];
				
			}
			
			# return matrix
			return($matrix);
			
		# if one parameter, a reference to a 2-D array or Math::Matrix object
		} elsif (@_ == 1 && (ref($_[0]) eq 'ARRAY' || UNIVERSAL::isa($_[0], 'Math::Matrix')) && @{$_[0]} == grep {ref() eq 'ARRAY'} @{$_[0]}) {
		
			# initialize array
			$self->[1] = [];
			
			# for each row
			for (@{$_[0]}) {
				
				# push row values
				push(@{$self->[1]}, @{$_});
				
			}
			
			# if an array
			if (ref($_[0]) eq 'ARRAY') {
				
				# return Math::Matrix object
				return (Math::Matrix->new(@{$_[0]}));
				
			} else {
				
				# return copy of parameter (Math::Matrix object)
				return(Storable::dclone($_[0]));
				
			}
		
		} else {
			
			# error
			croak('parameter must be column width or a 2-D array reference');
			
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

# read sf32 tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCsf32 {
	
	# get parameters
	my ($self, $parent, $fh, $tag) = @_;
	
	# local variables
	my ($buf);
	
	# save tag signature
	$self->[0]{'signature'} = $tag->[0];
	
	# seek start of tag
	seek($fh, $tag->[1], 0);
		
	# read entire tag
	read($fh, $buf, $tag->[2]);
	
	# unpack array and convert values
	$self->[1] = [map {($_ & 0x80000000) ? $_/65536 - 65536 : $_/65536} unpack('x8 N*', $buf)];
	
}

# write sf32 tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCsf32 {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag
	print $fh pack('a4 x4 N*', 'sf32', map {$_ * 65536} @{$self->[1]});

}

1;