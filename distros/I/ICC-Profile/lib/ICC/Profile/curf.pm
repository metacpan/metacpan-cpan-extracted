package ICC::Profile::curf;

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

# create new curf tag object
# hash may contain pointers to segments or breakpoints
# segments are an array of 'parf' or 'samf' objects
# hash keys are: ('segment', 'breakpoint')
# parameters: ([ref_to_attribute_hash])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty curf object
	my $self = [
		{},    # object header
		[],    # segment object array
		[]     # breakpoint array
	];

	# if there are parameters
	if (@_) {
		
		# if one parameter, a hash reference
		if (@_ == 1 && ref($_[0]) eq 'HASH') {
			
			# make new curf object from attribute hash
			_new_from_hash($self, shift());
			
		} else {
			
			# error
			croak('\'curf\' parameter must be a hash reference');
			
		}
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create curf tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty curf object
	my $self = [
		{},    # object header
		[],    # segment object array
		[]     # breakpoint array
	];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read curf data from profile
	_readICCcurf($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes curf tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write curf data to profile
	_writeICCcurf($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# set size of header and breakpoints
	my $size = 12 + 4 * @{$self->[2]};

	# for each curve segment
	for my $seg (@{$self->[1]}) {
		
		# add size
		$size += $seg->size();
		
	}

	# return size
	return($size);

}

# compute curve derivative function
# parameters: (input_value)
# returns: (output_value)
sub derivative {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($ix);

	# return transformed value, if just one segment
	return($self->[1][0]->derivative($in)) if ($#{$self->[1]} == 0);

	# initialize index
	$ix = 0;

	# for each breakpoint
	for my $bp (@{$self->[2]}) {
		
		# last if breakpoint >= input value
		last if ($bp >= $in);
		
		# increment index
		$ix++;
		
	}

	# if segment is a 'parf' object
	if (UNIVERSAL::isa($self->[1][$ix], 'ICC::Profile::parf')) {
		
		# return transformed value
		return($self->[1][$ix]->derivative($in));
		
	# if segment is a 'samf' object
	} elsif (UNIVERSAL::isa($self->[1][$ix], 'ICC::Profile::samf')) {
		
		# return transformed value
		return($self->[1][$ix]->derivative($in, $self->[2][$ix - 1], $self->[2][$ix], $self->[1][$ix - 1]));
		
	} else {
		
		# error
		croak('unsupported object class for \'curf\' segment');
		
	}
	
}

# compute curve function
# parameters: (input_value)
# returns: (output_value)
sub transform {

	# get parameters
	my ($self, $in) = @_;

	# local variables
	my ($ix);

	# return transformed value, if just one segment
	return($self->[1][0]->transform($in)) if ($#{$self->[1]} == 0);

	# initialize index
	$ix = 0;

	# for each breakpoint
	for my $bp (@{$self->[2]}) {
		
		# last if breakpoint >= input value
		last if ($bp >= $in);
		
		# increment index
		$ix++;
		
	}

	# if segment is a 'parf' object
	if (UNIVERSAL::isa($self->[1][$ix], 'ICC::Profile::parf')) {
		
		# return transformed value
		return($self->[1][$ix]->transform($in));
		
	# if segment is a 'samf' object
	} elsif (UNIVERSAL::isa($self->[1][$ix], 'ICC::Profile::samf')) {
		
		# return transformed value
		return($self->[1][$ix]->transform($in, $self->[2][$ix - 1], $self->[2][$ix], $self->[1][$ix - 1]));
		
	} else {
		
		# error
		croak('unsupported object class for \'curf\' segment');
		
	}
	
}

# get/set segment array reference
# parameters: ([ref_to_array])
# returns: (ref_to_array)
sub segment {

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

# get/set breakpoint array reference
# parameters: ([ref_to_array])
# returns: (ref_to_array)
sub breakpoint {

	# get object reference
	my $self = shift();

	# if parameter
	if (@_) {
		
		# verify array reference
		(ref($_[0]) eq 'ARRAY') || croak('not an array reference');
		
		# set array reference
		$self->[2] = [@{shift()}];
		
	}

	# return array reference
	return($self->[2]);

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

# make new curf object from attribute hash
# hash may contain pointers to segments, or breakpoints
# hash keys are: ('segment', 'breakpoint')
# object elements not specified in the hash are unchanged
# parameters: (ref_to_object, ref_to_attribute_hash)
sub _new_from_hash {

	# get parameters
	my ($self, $hash) = @_;

	# for each attribute
	for my $attr (keys(%{$hash})) {
		
		# if 'segment'
		if ($attr eq 'segment') {
			
			# if reference to an array of 'parf' or 'samf' objects
			if (ref($hash->{$attr}) eq 'ARRAY' && @{$hash->{$attr}} == grep {UNIVERSAL::isa($_, 'ICC::Profile::parf') || UNIVERSAL::isa($_, 'ICC::Profile::samf')} @{$hash->{$attr}}) {
				
				# set object element
				$self->[1] = [@{$hash->{$attr}}];
				
			} else {
				
				# wrong data type
				croak('\'curf\' segment attribute must be a reference to an array of \'parf\' or \'samf\' objects');
				
			}
			
		# if 'breakpoint'
		} elsif ($attr eq 'breakpoint') {
			
			# if reference to an array of scalars
			if (ref($hash->{$attr}) eq 'ARRAY' && @{$hash->{$attr}} == grep {! ref()} @{$hash->{$attr}}) {
				
				# set object element
				$self->[2] = [@{$hash->{$attr}}];
				
			} else {
				
				# wrong data type
				croak('\'curf\' breakpoint attribute must be a reference to an array of scalars');
				
			}
			
		}
		
	}
	
}

# read curf tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCcurf {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $segs, $mark, $class);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag header
	read($fh, $buf, 12);

	# unpack number of segments
	$segs = unpack('x8 n x2', $buf);

	# if one segment
	if ($segs == 1) {
		
		# mark file offset
		$mark = tell($fh);
		
		# read segment type signature
		read($fh, $buf, 4);
		
		# if type is 'parf'
		if ($buf eq 'parf') {
			
			# create object
			$self->[1][0] = ICC::Profile::parf->new_fh($self, $fh, ['curf', $mark]);
			
		} else {
			
			# error
			croak('wrong segment type in \'curf\' tag');
			
		}
		
	# if more than one segment
	} elsif ($segs > 1) {
		
		# read breakpoint values
		read($fh, $buf, 4 * ($segs - 1));
		
		# unpack breakpoint values
		$self->[2] = [unpack('f>*', $buf)];
		
		# for each segment
		for my $i (0 .. $segs - 1) {
			
			# mark file offset
			$mark = tell($fh);
			
			# read segment type signature
			read($fh, $buf, 4);
			
			# if type is 'parf' or 'samf'
			if ($buf eq 'parf' || $buf eq 'samf') {
				
				# form class specifier
				$class = "ICC::Profile::$buf";
				
				# create specific tag object
				$self->[1][$i] = $class->new_fh($self, $fh, ['curf', $mark]);
				
			} else {
				
				# error
				croak('unsupported segment type in \'curf\' tag');
				
			}
			
		}
		
	} else {
		
		# error
		croak('\'curf\' tag has no segments');
		
	}
	
}

# write curf tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCcurf {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# verify segments
	(@{$self->[1]} > 0) || carp('\'curf\' object must contain at least one segment');

	# verify breakpoints
	(@{$self->[1]} == @{$self->[2]} + 1) || carp('\'curf\' object must contain a breakpoint between each segment');

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag type signature and segment count
	print $fh pack('a4 x4 n x2', 'curf', scalar(@{$self->[1]}));

	# write breakpoints
	print $fh pack('f>*', @{$self->[2]});

	# for each segment
	for my $seg (@{$self->[1]}) {
		
		# write segment data
		$seg->write_fh($self, $fh, ['curf', tell($fh)]);
		
	}
	
}

1;