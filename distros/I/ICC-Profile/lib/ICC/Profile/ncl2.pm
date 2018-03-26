package ICC::Profile::ncl2;

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

# create new ncl2 tag object
# parameters: ()
# parameters: (ref_to_color_table_array)
# parameters: (ref_to_A2B1_tag, [ref_to_array_of_colorant_names])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();

	# create empty ncl2 object
	my $self = [
		{},   # object header
		[]    # colorant array
	];

	# if parameter supplied
	if (@_) {
		
		# if first parameter is an array or matrix
		if (ref($_[0]) eq 'ARRAY' || UNIVERSAL::isa($_[0], 'Math::Matrix')) {
			
			# get array reference
			my $array = shift();
			
			# for each row
			for my $i (0 .. $#{$array}) {
				
				# copy to object
				$self->[1][$i] = [@{$array->[$i]}];
				
			}
			
		} else {
			
			# add color table from A2B1 tag
			_newICCncl2($self, @_);
			
		}
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create ncl2 tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty ncl2 object
	my $self = [
				{},		# object header
				[]		# colorant array
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read ncl2 data from profile
	_readICCncl2($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes ncl2 tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write text data to profile
	_writeICCncl2($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {

	# get parameters
	my ($self) = @_;

	# return size
	return(@{$self->[1]} ? 84 + @{$self->[1]} * (30 + @{$self->[1][0]} * 2) : 84);

}

# get/set named color array
# each row contains name, PCS values, and optional device values
# all value are 16-bit (0 - 65563)
# parameters: ([array_reference])
# returns: (array_reference)
sub array {

	# get object reference
	my $self = shift();

	# if parameters
	if (@_) {
		
		# if one parameter, a single array reference or Math::Matrix object
		if (@_ == 1 && (ref($_[0]) eq 'ARRAY' || UNIVERSAL::isa($_[0], 'Math::Matrix'))) {
			
			# get array reference
			my $array = shift();
			
			# initialize data array
			$self->[1] = [];
			
			# if array is not empty
			if (@{$array}) {
				
				# for each row
				for my $i (0 .. $#{$array}) {
					
					# copy to object
					$self->[1][$i] = [@{$array->[$i]}];
					
				}
				
			}
			
		} else {
			
			# error
			croak('parameter must be an array reference');
			
		}
		
	}

	# return color table reference
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

# new colorant tag from nCLR A2B1 tag
# parameters: (ref_to_object, ref_to_A2B1_tag, [ref_to_array_of_colorant_names])
sub _newICCncl2 {

	# get parameters
	my ($self, $tag, $name) = @_;

	# local variables
	my ($type, $csi, $cso);
	my ($cnt, @in, @out);

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
			
			# if tag type is 'mft2' or colorspace is 'XYZ '
			if ($type eq 'ICC::Profile::mft2' || $cso eq 'XYZ ') {
				
				# transform to PCS (legacy 16-bit Lab or XYZ)
				@{$self->[1][$i]}[1 .. 3] = map {$_ * 65535} $tag->transform(@in);
				
			} else {
				
				# transform to PCS and convert to legacy 16-bit Lab
				@{$self->[1][$i]}[1 .. 3] = map {$_ * 65280} $tag->transform(@in);
				
			}
			
			# push the device values (always 16-bit)
			push(@{$self->[1][$i]}, map {$_ * 65535} @in);
			
		}
		
		# set pcs
		$self->[0]{'pcs'} = $cso;
		
		# set data color space
		$self->[0]{'dcs'} = $csi;
		
		# set flags
		$self->[0]{'vsflag'} = 0;
		
		# set prefix
		$self->[0]{'prefix'} = '';
		
		# set suffix
		$self->[0]{'suffix'} = '';
		
	} else {
		
		# message
		carp('wrong tag type');
		
	}
	
}

# read ncl2 tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCncl2 {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($buf, $cnt, $dvc, $rsz, $fmt);

	# save tag signature
	$self->[0]{'signature'} = $tag->[0];

	# save data color space
	$self->[0]{'dcs'} = $parent->[1][4];

	# save profile connection space ('Lab ' or 'XYZ ')
	$self->[0]{'pcs'} = $parent->[1][5];

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# read tag header
	read($fh, $buf, 84);

	# unpack header
	($self->[0]{'vsflag'}, $cnt, $dvc, $self->[0]{'prefix'}, $self->[0]{'suffix'}) = unpack('x8 N3 Z32 Z32', $buf);

	# adjust device color count to include PCS
	$dvc += 3;

	# set record size
	$rsz = 32 + 2 * $dvc;

	# set unpack format
	$fmt = "Z32n$dvc";

	# for each named color
	for my $i (0 .. $cnt - 1) {
		
		# read record
		read($fh, $buf, $rsz);
		
		# unpack color name, PCS and device values
		$self->[1][$i] = [unpack($fmt, $buf)];
		
	}
	
}

# write ncl2 tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCncl2 {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($vsflag, $prefix, $suffix);
	my ($cnt, $dvc, $fmt);

	# get vsflag, prefix and suffix using defaults if undefined
	$vsflag = defined($self->[0]{'vsflag'}) ? $self->[0]{'vsflag'} : 0;
	$prefix = defined($self->[0]{'prefix'}) ? $self->[0]{'prefix'} : '';
	$suffix = defined($self->[0]{'suffix'}) ? $self->[0]{'suffix'} : '';

	# get count from array size
	$cnt = @{$self->[1]};

	# get device colors from array size
	$dvc = @{$self->[1]} ? @{$self->[1][0]} - 4 : 0;

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write header
	print $fh pack('a4 x4 N3 Z32 Z32', 'ncl2', $vsflag, $cnt, $dvc, $prefix, $suffix);

	# make pack format
	$fmt = 'Z32n' . ($dvc + 3);

	# for each named color
	for my $rec (@{$self->[1]}) {
		
		# write color name, pcs and device values
		print $fh pack($fmt, @{$rec});
		
	}
	
}

1;