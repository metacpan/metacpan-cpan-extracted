package ICC::Profile::mluc;

use strict;
use Carp;

our $VERSION = 0.12;

# revised 2015-05-17
#
# Copyright © 2004-2018 by William B. Birkett

# add development directory
use lib 'lib';

# inherit from Shared
use parent qw(ICC::Shared);

# support modules
use Encode; # Unicode module

# create new mluc tag object
# use 'text' method to add additional entries
# parameters: ()
# parameters: (language_code, country_code, text)
# returns: (ref_to_object)
sub new {

	# get object class
	my $class = shift();
	
	# create empty mluc object
	my $self = [
				{},		# object header
				12,		# name record size
				[]		# array of name records
			];
	
	# if three parameters
	if (@_ == 3) {
		
		# verify country and language codes
		(length($_[0]) == 2 && length($_[1]) == 2) || croak('country or language code wrong length');
		
		# add name record
		$self->[2][0] = [$_[0], $_[1], 0, 0, $_[2]];
		
	}

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# create mluc tag object from ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
# returns: (ref_to_object)
sub new_fh {

	# get object class
	my $class = shift();

	# create empty mluc object
	my $self = [
				{},		# object header
				0,		# name record size
				[]		# array of name records
			];

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# read mluc data from profile
	_readICCmluc($self, @_);

	# bless object
	bless($self, $class);

	# return object reference
	return($self);

}

# writes mluc tag object to ICC profile
# parameters: (ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub write_fh {

	# get tag reference
	my $self = shift();

	# verify 3 parameters
	(@_ == 3) || croak('wrong number of parameters');

	# write mluc data to profile
	_writeICCmluc($self, @_);

}

# get tag size (for writing to profile)
# returns: (tag_size)
sub size {
	
	# get parameters
	my ($self) = @_;
	
	# local variables
	my ($text);
	
	# if count > 0
	if (@{$self->[2]}) {
		
		# initialize text size
		$text = 0;
		
		# for each name record
		for my $rec (@{$self->[2]}) {
			
			# add text string size
			$text += length($rec->[4]);
			
		}
		
		# return size (after Unicode encoding)
		return(16 + @{$self->[2]} * 12 + $text * 2);
		
	} else {
		
		# return size
		return(12);
		
	}
	
}

# get/set Unicode mluc string
# updates text if language/country found
# otherwise, adds new table entry
# parameters: (language_code, country_code, [text])
# returns: (mluc_string)
sub text {

	# get parameters
	my $self = shift();
	
	# local variables
	my (@match);
	
	# if two parameters (get)
	if (@_ == 2) {
		
		# return if name record count = 0
		return if (@{$self->[2]} == 0);
		
		# match country and language codes
		@match = grep {$_->[1] eq $_[1] && $_->[0] eq $_[0]} @{$self->[2]};
		
		# match country code
		@match = grep {$_->[1] eq $_[1]} @{$self->[2]} if (@match == 0);

		# match language code
		@match = grep {$_->[0] eq $_[0]} @{$self->[2]} if (@match == 0);
		
		# use first name record
		@match = ($self->[2][0]) if (@match == 0);
		
		# return name record string
		return($match[0][4]);
		
	# if three parameters (set)
	} elsif (@_ == 3) {
		
		# match country and language codes
		@match = grep {($_->[1] eq $_[1]) && ($_->[0] eq $_[0])} @{$self->[2]};
		
		# if match found
		if (@match) {
			
			# set name record text
			$match[0][4] = $_[2];
			
		} else {
			
			# verify country and language codes
			(length($_[0]) == 2 && length($_[1]) == 2) || croak('country or language code wrong length');
			
			# add new name record
			push(@{$self->[2]}, [$_[0], $_[1], 0, 0, $_[2]]);
			
		}
		
		# return name record string
		return($_[2]);
		
	} else {
		
		# warning message
		carp('wrong number of parameters');
		
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

# read mluc tag from ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _readICCmluc {
	
	# get parameters
	my ($self, $parent, $fh, $tag) = @_;
	
	# local variables
	my ($buf, $cnt);
	
	# save tag signature
	$self->[0]{'signature'} = $tag->[0];
	
	# seek start of tag
	seek($fh, $tag->[1], 0);
		
	# read type sig and count
	read($fh, $buf, 12);
	
	# unpack name record count
	$cnt = unpack('x8 N', $buf);
		
	# return if count = 0
	return if ($cnt == 0);
	
	# read name record size
	read($fh, $buf, 4);
	
	# unpack name record size
	$self->[1] = unpack('N', $buf);
	
	# for each name record
	for my $i (0 .. $cnt - 1) {
		
		# read name record
		read($fh, $buf, $self->[1]);
		
		# unpack language/country codes, length and offset
		$self->[2][$i] = [unpack('a2 a2 N N', $buf)];
		
	}
	
	# for each name record
	for my $rec (@{$self->[2]}) {
		
		# seek text string
		seek($fh, $tag->[1] + $rec->[3], 0);
		
		# read text string
		read($fh, $buf, $rec->[2]);
		
		# save decoded Unicode data
		$rec->[4] = decode('UTF-16BE', $buf);
		
	}
	
}

# write mluc tag to ICC profile
# parameters: (ref_to_object, ref_to_parent_object, file_handle, ref_to_tag_table_entry)
sub _writeICCmluc {

	# get parameters
	my ($self, $parent, $fh, $tag) = @_;

	# local variables
	my ($cnt, $offset);

	# get name record count
	$cnt = @{$self->[2]};

	# seek start of tag
	seek($fh, $tag->[1], 0);

	# write type sig and count
	print $fh pack('a4 x4 N', 'mluc', $cnt);

	# return if count = 0
	return if ($cnt == 0);

	# write name record size
	print $fh pack('N', $self->[1]);

	# compute initial text string offset
	$offset = 16 + $cnt * 12;

	# for each name record
	for my $rec (@{$self->[2]}) {
		
		# write language/country codes, length and offset
		print $fh pack('a2 a2 N N', @{$rec}[0 .. 1], length($rec->[4]) * 2, $offset);
		
		# update offset
		$offset += length($rec->[4]) * 2;
		
	}
	
	# for each name record
	for my $rec (@{$self->[2]}) {
		
		# write the Unicode string
		print $fh encode('UTF-16BE', $rec->[4]);
		
	}
	
}

1;