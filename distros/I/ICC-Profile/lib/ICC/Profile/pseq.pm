package ICC::Profile::pseq;

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

# create new pseq tag object
# parameters: ([array_of_profile_objects])
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty pseq object
	my $self = [
				{},		# object header
				[],		# array of profile description structures
			];

	# if parameter(s) supplied
	if (@_) {
		
		# make new pseq tag
		_newICCpseq($self, @_);
		
	}

	# bless object
	bless($self, $class);
	
	# return object reference
	return($self);

}

# create pseq tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty pseq object
	my $self = [
				{},		# object header
				[]		# array of profile description structures
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read pseq data from profile
	_readICCpseq($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes pseq tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write pseq data to profile
	_writeICCpseq($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# local variables
	my ($size);
	
	# set base size
	$size = 12;
	
	# for each profile description structure
	for my $pds (@{$self->[1]}) {
		
		# add size of profile description structure
		$size += 20 + $pds->[5]->size + $pds->[6]->size;
		
		# add padding if mluc tag (version 4)
		$size += (-$pds->[5]->size % 4) if (UNIVERSAL::isa($pds->[5], 'ICC::Profile::mluc'));
		
		# add padding if mluc tag (version 4)
		$size += (-$pds->[6]->size % 4) if (UNIVERSAL::isa($pds->[6], 'ICC::Profile::mluc'));
		
	}
	
	# return size
	return($size);
	
}

# get pds (profile description structure) reference(s)
# parameters: (index)
# returns: (ref_to_pds)
# parameters: (list_of_indices)
# returns: (list_of_refs_to_pds)
sub pds {

	# get object reference
	my $self = shift();
	
	# if parameters
	if (@_) {
		
		# if list is wanted
		if (wantarray) {
			
			# return list of pds references
			return(map {$self->[1][$_]} @_);
			
		# single value wanted
		} else {
			
			# return single pds reference
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

# make new pseq tag from array of profile objects
# parameters: (ref_to_object, array_of_profile_objects)
sub _newICCpseq {
	
	# get object reference
	my $self = shift();
	
	# local variables
	my ($vmaj, @pds);
	
	# verify array of profile objects
	(! grep {ref() ne 'ICC::Profile'} @_) || croak('not a profile object');
	
	# for each profile
	for my $profile (@_) {
		
		# get profile major version
		$vmaj = substr($profile->profile_header->[2], 0, 2);
		
		# copy profile header info
		@pds[0 .. 3] = @{$profile->profile_header}[15 .. 18];
		
		# if profile technology tag defined
		if (defined($profile->tag('tech'))) {
			
			# copy technology signature
			$pds[4] = $profile->tag('tech')->text;
			
		} else {
			
			# set to nulls
			$pds[4] = "\x00" x 4;
			
		}
		
		# if profile device manufacturer tag defined
		if (defined($profile->tag('dmnd'))) {
			
			# copy profile device manufacturer tag
			$pds[5] = $profile->tag('dmnd');
			
		} elsif ($vmaj == 2) {
			
			# make empty 'desc' tag
			$pds[5] = ICC::Profile::desc->new();
			
		} else {
			
			# make empty 'mluc' tag
			$pds[5] = ICC::Profile::mluc->new();
			
		}
		
		# if profile device model tag defined
		if (defined($profile->tag('dmdd'))) {
			
			# copy profile device manufacturer tag
			$pds[6] = $profile->tag('dmdd');
			
		} elsif ($vmaj == 2) {
			
			# make empty 'desc' tag
			$pds[6] = ICC::Profile::desc->new();
			
		} else {
			
			# make empty 'mluc' tag
			$pds[6] = ICC::Profile::mluc->new();
			
		}
		
		# add structure to tag
		push(@{$self->[1]}, [@pds]);
		
	}
	
}

# read pseq tag from ICC profile
# note: mluc tag sizes and padding are ambiguous, see "PSD_TechNote.pdf"
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCpseq {
	
	# get parameters
	my ($self, $parent, $fh, $tag) = @_;
	
	# local variables
	my ($buf, $cnt, $sig, $tab);
	my ($mark, $eot, $eos);
	
	# save tag signature
	$self->[0]{'signature'} = $tag->[0];
	
	# seek start of tag
	seek($fh, $tag->[1], 0);
		
	# read count
	read($fh, $buf, 12);
	
	# unpack count
	$cnt = unpack('x8 N', $buf);
	
	# for each profile description structure
	for my $i (0 .. $cnt - 1) {
		
		# if index > 0
		if ($i > 0) {
			
			# set file position to end of pervious tag
			seek($fh, $eot, 0);

			# read ahead 100 bytes
			read($fh, $buf, 100);
			
			# match allowed tag type signatures
			($buf =~ m/(desc|mluc|\x3f\x00)/g) || croak('invalid profile description structure');
			
			# seek start of next profile description structure
			seek($fh, $eot + pos($buf) - 20 - length($1), 0);
			
		}
		
		# read structure signatures and attributes
		read($fh, $buf, 20);
		
		# unpack structure signatures and attributes
		@{$self->[1][$i]}[0 .. 4] = unpack('a4 a4 N2 a4', $buf);
		
		# mark file position
		$mark = tell($fh);
		
		# get tag type signature ('desc' or 'mluc')
		read($fh, $sig, 4);
		
		# if 'desc' type
		if ($sig eq 'desc') {
			
			# parse manufacturer description object
			$self->[1][$i][5] = ICC::Profile::desc->new_fh($self, $fh, ['pseq', $mark, 0, 0]);
			
			# set end of tag
			$eot = $mark + $self->[1][$i][5]->size;
			
		# if 'mluc' type
		} elsif ($sig eq 'mluc') {
			
			# parse manufacturer description object
			$self->[1][$i][5] = ICC::Profile::mluc->new_fh($self, $fh, ['pseq', $mark, 0, 0]);
			
			# set end of tag
			$eot = $mark + 12;
			
			# if name record count > 0
			if (@{$self->[1][$i][5][2]}) {
				
				# for each name record
				for my $rec (@{$self->[1][$i][5][2]}) {
					
					# compute end of string (eos)
					$eos = $mark + $rec->[2] + $rec->[3];
					
					# set eot to greater value
					$eot = $eot > $eos ? $eot : $eos;
					
				}
				
			}
		
		# if Monaco non-standard notation
		} elsif (substr($sig, 0, 2) eq "\x3f\x00") {
			
			# create an empty 'desc' tag object
			$self->[1][$i][5] = ICC::Profile::desc->new();
			
			# set end of tag
			$eot = $mark + 2;
			
		} else {
			
			# error
			croak('invalid profile description structure');
			
		}
		
		# set file position to end of tag
		seek($fh, $eot, 0);
		
		# read ahead 100 bytes
		read($fh, $buf, 100);
		
		# match allowed tag type signatures
		($buf =~ m/(desc|mluc|\x3f\x00)/g) || croak('invalid profile description structure');
		
		# mark start of next tag
		$mark = $eot + pos($buf) - length($1);
		
		# if 'desc' type
		if ($1 eq 'desc') {
			
			# parse model description object
			$self->[1][$i][6] = ICC::Profile::desc->new_fh($self, $fh, ['pseq', $mark, 0, 0]);
			
			# set end of tag
			$eot = $mark + $self->[1][$i][5]->size;
			
		# if 'mluc' type
		} elsif ($1 eq 'mluc') {
			
			# parse model description object
			$self->[1][$i][6] = ICC::Profile::mluc->new_fh($self, $fh, ['pseq', $mark, 0, 0]);
			
			# set end of tag
			$eot = $mark + 12;
			
			# if name record count > 0
			if (@{$self->[1][$i][5][2]}) {
				
				# for each name record
				for my $rec (@{$self->[1][$i][5][2]}) {
					
					# compute end of string (eos)
					$eos = $mark + $rec->[2] + $rec->[3];
					
					# set eot to greater value
					$eot = $eot > $eos ? $eot : $eos;
					
				}
				
			}
		
		# if Monaco non-standard notation
		} else {
			
			# create an empty 'desc' tag object
			$self->[1][$i][6] = ICC::Profile::desc->new();
			
			# set end of tag
			$eot = $mark + 2;
			
		}
		
	}
	
}

# write pseq tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCpseq {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write tag type and pds count
	print $fh pack('a4 x4 N', 'pseq', scalar(@{$self->[1]}));

	# for each profile description structure
	for my $pds (@{$self->[1]}) {
		
		# write structure signatures and attributes
		print $fh pack('a4 a4 N2 a4', @{$pds}[0 .. 4]);
		
		# write manufacturer description object
		$pds->[5]->write_fh($parent, $fh, ['pseq', tell($fh), 0, 0]);
		
		# add padding if mluc tag (version 4)
		seek($fh, (-tell($fh) % 4), 1) if (UNIVERSAL::isa($pds->[5], 'ICC::Profile::mluc'));
		
		# write model description object
		$pds->[6]->write_fh($parent, $fh, ['pseq', tell($fh), 0, 0]);
		
		# add padding if mluc tag (version 4)
		seek($fh, (-tell($fh) % 4), 1) if (UNIVERSAL::isa($pds->[6], 'ICC::Profile::mluc'));
		
	}
	
}

1;