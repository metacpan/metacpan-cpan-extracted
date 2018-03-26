package ICC::Profile::clrt;

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

# create new clrt tag object
# parameters: ([ref_to_A2B1_tag, [ref_to_array_of_colorant_names]])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty clrt object
	my $self = [
				{},		# object header
				[]		# colorant array
			];

	# if parameter supplied
	if (@_) {
		
		# new colorant tag from xCLR A2B1 tag
		_newICCclrt($self, @_);
		
	}

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);

}

# create clrt tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty clrt object
	my $self = [
				{},		# object header
				[]		# colorant array
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read clrt data from profile
	_readICCclrt($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes clrt tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write text data to profile
	_writeICCclrt($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# return size
	return(12 + @{$self->[1]} * 38);
	
}

# get colorant table entry reference(s)
# parameters: (channel)
# returns: (ref_to_color_table_entry)
# parameters: (list_of_channels)
# returns: (list_of_refs_to_color_table_entries)
sub channel {

	# get object reference
	my $self = shift();
	
	# if parameters
	if (@_) {
		
		# if list is wanted
		if (wantarray) {
			
			# return list of colorant table references
			return(map {$self->[1][$_]} @_);
			
		# single value wanted
		} else {
			
			# return single colorant table reference
			return($self->[1][$_[0]]);
			
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

# new colorant tag from xCLR A2B1 tag
# parameters: (ref_to_object, ref_to_A2B1_tag, [ref_to_array_of_colorant_names])
sub _newICCclrt {
	
	# get parameters
	my ($self, $tag, $name) = @_;
	
	# local variables
	my ($type, $csi, $cso);
	my ($cnt, $max, @in, @out);
	
	# get tag type
	$type = ref($tag);
	
	# get input colorspace
	$csi = $tag->[0]{'input_cs'};
	
	# get output colorspace
	$cso = $tag->[0]{'output_cs'};
	
	# if allowable tag type
	if (($type eq 'ICC::Profile::mft1' || $type eq 'ICC::Profile::mft2' || $type eq 'ICC::Profile::mAB_') &&
		($csi =~ m|^([2-9A-F])CLR$|) && ($cso eq 'Lab ' || $cso eq 'XYZ ')) {
		
		# get count from match
		$cnt = hex($1);
		
		# get maximum colorant value
		$max = $type eq 'ICC::Profile::mft1' ? 255 : 65535;
		
		# set transform mask
		$tag->[6] = 0x0f;
		
		# for each colorant
		for my $i (0 .. $cnt - 1) {
			
			# for each input
			for my $j (0 .. $cnt - 1) {
				
				# set input
				$in[$j] = $i == $j ? 1 : 0;
				
			}
			
			# if name array supplied
			if (defined($name->[$i])) {
				
				# set the colorant name
				$self->[1][$i][0] = $name->[$i];
				
			} else {
				
				# set the colorant name
				$self->[1][$i][0] = sprintf('colorant_%x', $i + 1);
				
			}
			
			# transform color value
			@{$self->[1][$i]}[1 .. 3] = map {$_ * $max} $tag->transform(@in);
			
		}
		
		# set the PCS ('Lab ' or 'XYZ ')
		$self->[0]{'pcs'} = $cso;
		
		# set the output bit depth
		$self->[0]{'output_bits'} = ($cso eq 'Lab ' && $type eq 'ICC::Profile::mft1') ? 8 : 16;
		
		# set the 16-bit Lab legacy flag
		$self->[0]{'legacy'} =  ($cso eq 'Lab ' && $type eq 'ICC::Profile::mft2') ? 1 : 0;
		
	} else {
		
		# message
		carp('wrong tag type');
		
	}
	
}

# read clrt tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCclrt {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $cnt);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# save profile connection space ('Lab ' or 'XYZ ')
	$self->[0]{'pcs'} = $parent->[1][5];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read signature and color count
	read($fh, $buf, 12);

	# unpack colorant count
	$cnt = unpack('x8 N', $buf);

	# for each colorant
	for my $i (0 .. $cnt - 1) {
		
		# read colorant record
		read($fh, $buf, 38);
		
		# unpack colorant values
		$self->[1][$i] = [unpack('Z32 n3', $buf)];
		
	}
	
}

# write clrt tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCclrt {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write type signature and colorant count
	print $fh pack('a4 x4 N', 'clrt', scalar(@{$self->[1]}));

	# for each colorant record
	for my $rec (@{$self->[1]}) {
		
		# write colorant values
		print $fh pack('Z32 n3', @{$rec});
		
	}
	
}

1;