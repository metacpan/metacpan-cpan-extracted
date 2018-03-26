package ICC::Profile::samf;

use strict;
use Carp;

our $VERSION = 0.11;

# revised 2016-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# use POSIX math
use POSIX ();

# create new samf tag object
# parameters: ([ref_to_array])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty samf object
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

# create samf tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty samf object
	my $self = [
		{},    # object header
		[]     # curve array
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read samf data from profile
	_readICCsamf($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes samf tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write samf data to profile
	_writeICCsamf($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# return size
	return(12 + 4 * @{$self->[1]});

}

# compute curve derivative function
# parameters: (input_value, lower_breakpoint, upper_breakpoint, preceeding_segment_object)
# returns: (output_value)
sub derivative {

	# get parameters
	my ($self, $in, $xbp0, $xbp1, $pseg) = @_;

	# local variables
	my ($xpos, $ix, $ir, $low);

	# compute x-position (0 - number of curve entries)
	$xpos = ($#{$self->[1]} + 1) * ($in - $xbp0)/($xbp1 - $xbp0);

	# compute lower array index
	$ix = POSIX::floor($xpos);

	# limit lower array index
	$ix = $ix < 0 ? 0 : $ix > $#{$self->[1]} ? $#{$self->[1]} : $ix;

	# compute interpolation ratio
	$ir = $xpos - $ix;

	# if lower breakpoint used
	if ($ix == 0) {
		
		# if preceeding segment a 'parf' object
		if (UNIVERSAL::isa($pseg, 'ICC::Profile::parf')) {
			
			# compute lower curve entry value
			$low = $pseg->transform($xbp0);
			
		# if preceeding segment a 'samf' object
		} elsif (UNIVERSAL::isa($pseg, 'ICC::Profile::samf')) {
			
			# get lower curve entry value
			$low = $pseg->[1][-1];
			
		}
		
	} else {
		
		# get lower curve entry value
		$low = $self->[1][$ix - 1];
		
	}

	# return derivative value
	return(($#{$self->[1]} + 1) * ($self->[1][$ix] - $low)/($xbp1 - $xbp0));

}

# compute curve function
# parameters: (input_value, lower_breakpoint, upper_breakpoint, preceeding_segment_object)
# returns: (output_value)
sub transform {

	# get parameters
	my ($self, $in, $xbp0, $xbp1, $pseg) = @_;

	# local variables
	my ($xpos, $ix, $ir, $low);

	# compute x-position (0 - number of curve entries)
	$xpos = ($#{$self->[1]} + 1) * ($in - $xbp0)/($xbp1 - $xbp0);

	# compute lower array index
	$ix = POSIX::floor($xpos);

	# limit lower array index
	$ix = $ix < 0 ? 0 : $ix > $#{$self->[1]} ? $#{$self->[1]} : $ix;

	# compute interpolation ratio
	$ir = $xpos - $ix;

	# if lower breakpoint used
	if ($ix == 0) {
		
		# if preceeding segment a 'parf' object
		if (UNIVERSAL::isa($pseg, 'ICC::Profile::parf')) {
			
			# compute lower curve entry value
			$low = $pseg->transform($xbp0);
			
		# if preceeding segment a 'samf' object
		} elsif (UNIVERSAL::isa($pseg, 'ICC::Profile::samf')) {
			
			# get lower curve entry value
			$low = $pseg->[1][-1];
			
		}
		
	} else {
		
		# get lower curve entry value
		$low = $self->[1][$ix - 1];
		
	}

	# return interpolated value
	return($low + $ir * ($self->[1][$ix] - $low));

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

# read samf tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCsamf {

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

	# if count > 0
	if ($cnt > 0) {
		
		# read array values
		read($fh, $buf, $cnt * 4);
		
		# unpack the values
		$self->[1] = [unpack('f>*', $buf)];
		
	} else {
		
		# error
		croak('\'samf\' tag has zero count');
		
	}
	
}

# write samf tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCsamf {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag type signature and count
	print $fh pack('a4 x4 N', 'samf', scalar(@{$self->[1]}));

	# if count > 0
	if (@{$self->[1]} > 0) {
		
		# write array
		print $fh pack('f>*', @{$self->[1]});
		
	} else {
		
		# error
		croak('\'samf\' object has zero count');
		
	}
	
}

1;