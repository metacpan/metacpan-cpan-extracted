#=Copyright Infomation
#==========================================================
#Module Name       : File::BufferedInput
#Program Author   : Dr. Ahmed Amin Elsheshtawy, Ph.D. Physics, E.E.
#Home Page           : http://www.mewsoft.com
#Contact Email      : support@mewsoft.com
#Copyrights © 2014 Mewsoft. All rights reserved.
#==========================================================
package File::BufferedInput;

use Carp;
use strict;
use warnings;

our $VERSION = '1.03';
#==========================================================
sub new {
my ($class, %args) = @_;
    
	my $self = bless {}, $class;
	
	$self->{buffer} = $args{buffer};
	$self->{buffer} ||= 204800; # 20MB
	$self->{utf8} = $args{utf8};
	$self->{file} = $args{file};

	if ($self->{file}) {
		$self->file($self->{file});
	}

    return $self;
}
#=========================================================#
sub file {
my ($self, $file) = @_;

	$self->close();

	if ($self->opened($file)) {
		$self->{fh} = $file;
	}
	else {
		open ($self->{fh}, ($self->{utf8})? "<:encoding(UTF-8)" : "<", $file) or croak "Error opening file $file: $!";
	}

	$self->reset();
}
#=========================================================#
sub reset {
my ($self) = $_[0];
	$self->{current_line} = 0;
	$self->{line_count} = 0;
	$self->{total_count} = 0;
	$self->{eof} = 0;
	$self->{block_remaining} = "";
}
#=========================================================#
sub rewind {
my ($self) = $_[0];
	seek $self->{fh}, 0, 0;
	$self->reset();
}
#=========================================================#
sub eof {
my ($self) = $_[0];
	$self->{eof};
}
#=========================================================#
sub DESTROY {
my ($self) = $_[0];
	$self->close();
}
#=========================================================#
sub close {
my ($self) = $_[0];
	$self->{fh} || return;
	close $self->{fh};
}
#=========================================================#
sub opened {
my ($self) = $_[0];
    defined fileno($_[1]);
}
#=========================================================#
sub line {
my ($self) = $_[0];
	
	return undef if $self->{eof};

	if ($self->{current_line} == $self->{line_count}) {
		$self->read_block();
	}

	return ($self->{lines}->[$self->{current_line}++]);
}
#=========================================================#
sub read_block {
my ($self) = $_[0];
my ($buffer, $chunk, $match);

	if (read($self->{fh}, $buffer, $self->{buffer})) {
		
		# win, dos eol: \r\n =\015\012	, unix eol: \n = \012, Mac eol: \r =\015; \cM=\n, \cJ=\r,  /\x0D\x0A/, /\x0A/
		#split /(?:\x{0d}?\x{0a}|\x{0d})/
		
		$self->{end_pos} = rindex($buffer, "\n");
		
		# if current block does not have newline, join another blocks until one found
		while ($self->{end_pos} == -1 && read($self->{fh}, $chunk, $self->{buffer})) {
			$buffer .= $chunk;
			$self->{end_pos} = rindex($buffer, "\n");
		}

		#if (length(decode_utf8($str))

		if (length($buffer) >= $self->{buffer}) {
			$match = substr($buffer, 0, $self->{end_pos});
			$match = $self->{block_remaining} . $match ;
			$self->{block_remaining} = substr($buffer, $self->{end_pos}+1, length($buffer) - $self->{end_pos});
		} else {
			# last block in file
			$match = $buffer;
			$match = $self->{block_remaining} . $buffer;
			$self->{block_remaining} = "";
		}
		
		@{$self->{lines}} = split(/\n/, $match, -1);
		
		$self->{current_line} = 0;
		$self->{line_count} = @{$self->{lines}};
		$self->{total_count} += $self->{line_count};
	}
	else {
		# finished
		$self->{eof} = 1;
		$self->{current_line} = 0;
		$self->{line_count} = 0;
		@{$self->{lines}} = ();
	}
}
#==========================================================
1;

=head1 NAME

File::BufferedInput - Large and giant text file performance buffered reader.

=head1 SYNOPSIS

	use File::BufferedInput;

	# create new object with default options, buffer size 20MB and ANSI text file
	# file argument can be file name or file handle
	my $fileobj = File::BufferedInput->new(file=>$filename);
	
	# or create new object with custom options, set buffer size 50MB and UTF-8 text file
	my $fileobj = File::BufferedInput->new(file=>$filename, buffer=>50_000_000, utf8=>1);

	# or create new object then set the file name/handle
	my $fileobj = File::BufferedInput->new();
	$fileobj->file($filename_or_handle);

	# now loop through all the text file lines straight forward
	
	my $counter = 0;
	# loop through the file lines sequentially
	while (!$fileobj->eof()) {
		 $line=$fileobj->line();
		$counter++;
		# print "$counter)- $line\n";
	}

	# start again from the begaining of the file
	#$fileobj->rewind()

	$fileobj->close(); # close the file and frees the memory used for the block
	print "$counter lines found\n";
	
	
=head1 DESCRIPTION

This module solves the problem with reading large and huge text files in Perl. It is designed to read only block by block as needed.
It does not load the whole file into memory, it only reads one block at a time and once the last sequential line reached, it reads the
next block from the file and frees the previous block from memory, so at all times only one block of the file is kept in menory.

For example if you are reading a 2GB file, once you start reading lines from the file, the module reads the first block from the
file on disk, while you loop through the lines, when you reach the line at the end of the read block, the module delete this block
from memory and read the next block from the file on disk and parses it to lines and so on.

=head1 SEE ALSO

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  <support@mewsoft.com>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ahmed Amin Elsheshtawy support@mewsoft.com
L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
