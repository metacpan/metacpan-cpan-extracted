package File::RoundRobin;

use 5.006;
use strict;
use warnings;

=head1 NAME

File::RoundRobin - Round Robin text files

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

local $|=1;

=head1 SYNOPSIS

This module implements a Round-Robin text file.

The text file will not grow beyond the size we specify.

The benefit of using this module is that you can log a certain amount of
information without having to care about filling your hard drive or setting up a
log-rotate mechanism.

Example :

	use File::RoundRobin;

	my $rrfile = File::RoundRobin->new(
                                    path => '/tmp/sample.txt',
                                    size => '100M',
                                    mode => 'new',
                       			  );

	$rrfile->print("foo bar");
	
	or
    
	my $rrfile = File::RoundRobin->new(path => '/tmp/sample.txt', mode => 'read');

	while (my $line = $rrfile->readline() ) {
		print $line;
	}
	


When you write into the Round-Robin file, if it filled the maximum allowed space it 
will write over the old data, while always preserving the most recent data.

=head1 TIE INTERFACE

This module implements the TIEHANDLE interface and the objects an be used as normal 
file handles.

=over 4

=item 1. Write example :

	local *FH;
	tie *FH, 'File::RoundRobin', path => 'test.txt',size => '10M';

	my $fh = *FH;

	...
	print $fh "foo bar";

	...
	close($fh);
	
=item 2. Read example :

	local *FH;
	tie *FH, 'File::RoundRobin', path => 'test.txt',mode => 'read';

	$fh = *FH;

	while ( my $line = readline($fh) ) {
		print $line;
	}
	
	close($fh);
	
=back
	
=head1 UTILITIES

=head2 rrcat 

The package comes with a simple utility B<rrcat> that let's you create and read RoundRobin files from command line 

Usage : 
To print the content of a file :
	$ rrcat <filename> 

To write into a file (reads from stdin):
	$ rrcat <size> <filename>

Size can be specified in any of the forms accepted by File::RoundRobin (see C<new> method)

=head2 rrtail

The package comes with a simple utility B<rrtail> that let's you tail RoundRobin files from command line

Usage : 
To a file you can run :

Print the last 10 lines
	
    $ rrtail <filename>

Print the last 100 lines :
    
    $ rrtail -n 100 <filename>

Print the content as it's written :    

    $ rrtail -f <filename>    
    

=head1 SUBROUTINES/METHODS

=head2 new

Returns a new File::RoundRobin object.

Files can be opened in three ways: I<new file>, I<read>, I<append>

=head3 write

In I<new file> mode any existing data will be lost and the file will be overwritten
Arguments :

=over 4 

=item * path = path where to create the file

=item * size = the maximum size the file is allowed to grow to. Example : 100K or 100Kb, 10M or 10Mb, 1G or 1Gb

=back

Example : 

	my $rrfile = File::RoundRobin->new(
                                    path => '/tmp/sample.txt',
                                    size => '100M',
                       			  );

=head3 read

Arguments :

=over 4

=item * path = path where to create the file

=item * mode = must be C<read>

=back

Example :

	my $rrfile = File::RoundRobin->new(path => '/tmp/sample.txt', mode => 'read');

=head3 append

In I<append> mode all existing data will preserved and we can continue writing the file from where we left off

Arguments :

=over 4

=item * path = path where to create the file

=item * mode = must be C<append>

=back

Example :

	my $rrfile = File::RoundRobin->new(path => '/tmp/sample.txt', mode => 'append');

=cut

sub new {
    my $class = shift;
    
    my %params = (
                mode => 'new',
                @_
    );
    
    $params{size} = convert_size($params{size});
    
    die "You must specify the file size" if ($params{mode} eq "new" && ! defined $params{size});
    
    my ($fh,$size,$start_point,$headers_size,$read_only) = open_file(%params);
        
    my $self = {
                _fh_ => $fh,
                _data_length_ => $size,
				_file_length_ => $size + $headers_size,
				_write_start_point_ => $start_point,
				_read_start_point_ => $start_point,
				_headers_size_ => $headers_size,
				_read_only_ => $read_only,
				_autoflush_ => $params{autoflush} || 1,
    };
    
    bless $self, $class;
    
    return $self;
}


=head2 read

Reads the $length craracters form the file beginning with $offset and returns the result

Usage : 

	#reads the next 10 characted from the file
	my $buffer = $rrfile->read(10); 
	or 
	#reads the first 10 characters starting with character 90 after the current position
	my $buffer = $rrfile->read(10,90); 

Arguments :

=over 4 

=item * I<length> = how many bytes to read

=item * I<offset> = offset from which to start reading

=back
	
=cut
sub read {
	my $self = shift;
	my $length = shift || 1;
	my $offset = shift || 0;
	
	if ($self->{_write_start_point_} == $self->{_read_start_point_}) {
		if ($self->{_read_started_}) {
			return undef;
		}
		else {
			$self->{_read_started_} = 1;
		}
	}

	my $to_eof =  ($self->{_write_start_point_} > $self->{_read_start_point_}) ? 
						$self->{_write_start_point_} - $self->{_read_start_point_} :
						($self->{_write_start_point_} - $self->{_headers_size_}) + ($self->{_file_length_} - $self->{_read_start_point_});
							
	$length = $to_eof > $length ? $length : $to_eof;
    
	return undef unless $length;

	$self->jump($offset) if ($offset);
	
	my ($buffer1,$buffer2);
    
	my $bytes = CORE::sysread($self->{_fh_},$buffer1,$length);
	$self->{_read_start_point_} += $bytes;
	CORE::sysseek($self->{_fh_},$self->{_read_start_point_},0);
    	
	if ($bytes < $length) {
        $length -= $bytes;
        if ($self->{_write_start_point_} - $self->{_headers_size_} < $length) {
            $length = $self->{_write_start_point_} - $self->{_headers_size_};
        }
		CORE::sysseek($self->{_fh_},$self->{_headers_size_},0);
		$bytes = CORE::sysread($self->{_fh_},$buffer2,$length);
		$self->{_read_start_point_} = $self->{_headers_size_} + $bytes;
		CORE::sysseek($self->{_fh_},$self->{_read_start_point_},0);
	}

	return $buffer2 ? $buffer1 . $buffer2 : $buffer1;
}

=head2 write

Writes the given text into the file

Usage :

	$rrfile->write("foo bar");
	
Arguments :

=over 4

=item * I<buffer> = the actual content we want to write

=item * I<length> = the length of the content we want to write (defaults to C<length($buffer)>)

=item * I<offset> = offset from which to start writing

=back

=cut
sub write {
	my $self = shift;
	my $buffer = shift;
	my $length = shift || length($buffer);
	my $offset = shift || 0;
	
	die "File is read only!" if $self->{_read_only_};
	
    select($self->{_fh_});
    
	$self->jump($offset) if $offset;
	
	$self->{_write_start_point_} = $self->{_read_start_point_};
	
	my $fh = $self->{_fh_};
	
	my $start_pos = 0;
	while  ($self->{_write_start_point_} + $length > $self->{_file_length_}) {
		my $bytes_to_write = $self->{_file_length_} - $self->{_write_start_point_};
		CORE::syswrite($fh,substr($buffer,$start_pos,$bytes_to_write));
		$start_pos += $bytes_to_write;
		$length -= $bytes_to_write;
		$self->{_write_start_point_} = $self->{_headers_size_};
		CORE::sysseek($fh,$self->{_write_start_point_},0);
	}
	
	CORE::syswrite($fh,substr($buffer,$start_pos,$length));
	$self->{_write_start_point_} += $length;
	$self->{_read_start_point_} = $self->{_write_start_point_};
    
    $self->update_headers() unless $self->{_autoflush_} == 0;
    
	return ($self->{_write_start_point_} == CORE::tell($fh)) ? 1 : 0;
}


=head2 print

Writes the given text into the file

Usage :

	$rrfile->print("foo bar");
	
Arguments :

=over 4

=item * I<buffer> = the actual content we want to write    

=back

=cut
*print = \&write;


=head2 close

Close the Round-Robin file

Usage :

	$rrfile->close();

=cut
sub close {
	my $self = shift;
	
	my $fh = $self->{_fh_};
	
	return if $self->{_closed_};
	
	if (! $self->{_read_only_}) {
        $self->update_headers();
	}
	
	$self->{_closed_} = 1;
	
	return CORE::close($fh);
}


=head2 eof

Return true if you reached the end of file, false otherwise

Usage :

	my $bool = $rrfile->eof();

=cut
sub eof {
	my $self = shift;
	
	return 1 if ($self->{_write_start_point_} == $self->{_read_start_point_} && defined $self->{_read_started_} );

	return 0;
}


=head2 autoflush 

Turns on/off the autoflush feature

Usage :
	my $autoflush = $rrfile->autoflush();
	
	or 
	
	$rrfile->autoflush(1); #enables autoflush
	$rrfile->autoflush(0); #disables autoflush
	
=cut
sub autoflush {
	my $self = shift;
	
	if ( scalar(@_) ) {
		$self->{_autoflush_} = $_[0];
	}
	
	return $self->{_autoflush_};
}


=head1 Private methods

Don't call this methods manually, or you might get unexpected results!


=head2 open_file

Has two modes :

=over 4

=item 1. In append mode it opens an existing file

=item 2. In new mode it creates a new file

=back

=cut
sub open_file {
    my %params = @_;
    
    die "You myst specifi the name of the file!" unless $params{path};
    die "Path is a directory!" if -d $params{path};
    
    my ($fh,$size,$start_point,$headers_size,$read_only);
    if ($params{mode} eq "new") {
        die "You must specify the size of the file!" unless defined $params{size};
        $size = $params{size};
        open($fh,"+>",$params{path}) || die "Cannot open file $params{path}";
		CORE::binmode($fh,":unix");
		#version number
		CORE::syswrite($fh,"1"."\x00");
		#file size
        CORE::syswrite($fh,$params{size} ."\x00");
		#where is the start of the file
        $start_point = length($params{size}) * 2 + 2 + 2;
        CORE::syswrite($fh,("0" x (length($params{size}) - length($start_point) )) . $start_point ."\x00");
		$headers_size = length($params{size}) * 2 + 2 + 2;
		$read_only = 0;
    }
	else {
		if ($params{mode} eq "append") {
			open($fh,"+<",$params{path}) || die "Cannot open file $params{path}";
			CORE::binmode($fh,":unix");
			CORE::sysseek($fh,0,0);	
			$read_only = 0;
		}
		elsif ($params{mode} eq "read") {
			open($fh,"<",$params{path}) || die "Cannot open file $params{path}";
			CORE::binmode($fh,":unix");
			$read_only = 1;
		}
		else {
			die "Invalid open mode! Use one of new,read,append!";
		}
			
		local $/ = "\x00";
		
		my $version = <$fh>;
		
		$size = <$fh>;
		$start_point = <$fh>;
		
		$headers_size = length($version) + length($size) + length($start_point);
		
		$size =~ s/\x00//g;
		$start_point =~ s/\x00//g;
		
		CORE::sysseek($fh,$start_point + 0,0);	
	}
    
    return ($fh,$size + 0,$start_point + 0,$headers_size + 0,$read_only);
}


=head2 update_headers

Update the start point in the headers section after a write command

=cut
sub update_headers {
    my $self = shift;
    
    my $fh = $self->{_fh_};
    
    CORE::sysseek($fh,0, 0);
    
    my $headers = '';
    #version
    $headers .= "1\x00";
	#file size
    $headers .= $self->{_data_length_} ."\x00";
    #start pos
    $headers .= ("0" x (length($self->{_data_length_}) - length($self->{_write_start_point_}) )) . $self->{_write_start_point_} ."\x00";
    
    CORE::syswrite($fh,$headers);
    
    #go back to the previous position
    CORE::sysseek($fh,$self->{_write_start_point_}, 0);
}


=head2 refresh

Re-reads the headers from the file. Useful for tail

=cut
sub refresh {
    my $self = shift;
    
    my $fh = $self->{_fh_};
	
    my $pos = $self->tell();
    
    CORE::sysseek($fh,0,0);
    
    local $/ = "\x00";
    
    #skip the first part of the header
    my $version = <$fh>;
    my $size = <$fh>;
    
    my $start_point =  <$fh>;
    
    my $headers_size = length($version) + length($size) + length($start_point);
    
    $size =~ s/\x00//g;
    $start_point =~ s/\x00//g;
    
    $self->{_headers_size_} = $headers_size;
    $self->{_read_start_point_} = $start_point + 0;
    $self->{_data_length_} = $size + 0;
    $self->{_file_length_} = $size + $headers_size;
		
	CORE::sysseek($fh,$start_point,0);	
}

=head2 sync_markers

Sets the write market to the same position as the read marker

=cut
sub sync_markers {
    my $self = shift;
    
    $self->{_write_start_point_} = $self->{_read_start_point_};
    $self->{_read_started_} = 0;
}


=head2 jump

Advance the read start position pointer by $offset bytes

=cut
sub jump {
	my $self = shift;
	my $offset = shift || 0;
	
	if ($offset) {
		if ($offset + $self->{_read_start_point_} > $self->{_file_length_}) {
			$self->{_read_start_point_} = $self->{_headers_size_} + (($offset + $self->{_read_start_point_}) % $self->{_file_length_} )	
		}
		else {
			$self->{_start_point_} += $offset;
		}		
	}
	
	CORE::sysseek($self->{_fh_},$self->{_read_start_point_},0);
}


=head2 seek 

Move the read/write start position to the given position

Arguments :

=over 4

=item * I<position> = The position to which we want to move to offset

=item * I<whence> = From where should we start counting the position :

=back

=over 8

=item * 0 = from the beginning of the file

=item * 1 = from the current position 

=item * 2 = from the end of the file (I<position> must be negative)

=back

Usage :

	$rrfile->seek(10,0);

=cut
sub seek {
	my $self = $_[0];
	my $position = $_[1];
	my $whence = $_[2] || 0;
	
	#$position = $position % $self->{_data_length_};
	
	if ($whence == 0) {
		my $start_pos = $self->{_write_start_point_};
		if ($self->{_write_start_point_} + $position > $self->{_file_length_}) {
			$position -= $self->{_file_length_} - $self->{_write_start_point_};
			$start_pos = $self->{_headers_size_};
		}
		if ( CORE::sysseek($self->{_fh_},$start_pos + $position,0) ) {
			$self->{_read_start_point_} = $start_pos + $position;
			return 1;
		}
	}
	elsif ($whence == 1) {
		my $start_pos = $self->{_read_start_point_};
		if ($self->{_read_start_point_} + $position > $self->{_file_length_}) {
			$position -= $self->{_file_length_} - $self->{_read_start_point_};
			$start_pos = $self->{_headers_size_};
		}
		if ( CORE::sysseek($self->{_fh_},$start_pos + $position,1) ) {
			$self->{_read_start_point_} = $start_pos + $position;
			return 1;
		}
	}
	elsif ($whence == 2 ) {
		if ($position > 0) {
			warn "Attempt to seek beyond the end of file!";
			return 0;
		}
		
		my $start_pos = $self->{_write_start_point_};
		if ($self->{_write_start_point_} + $position < $self->{_headers_size_}) {
            $position = -$position;
			$position -= $self->{_write_start_point_} - $self->{_headers_size_};
			$start_pos = $self->{_file_length_};
		}
		
        #don't go in cicles
        if ($self->{_read_start_point_} < $self->{_write_start_point_} &&  
            $self->{_read_start_point_} + $position >= $self->{_write_start_point_}){
                return 0;
        }
        
		if ( CORE::sysseek($self->{_fh_},$start_pos,0) ) {
			if ( CORE::sysseek($self->{_fh_},$position,1) ) {
				$self->{_read_start_point_} = $start_pos + $position;
				return 1;
			}
		}
	}
	else {
		die "Unknown seek mode!";
	}
	
	return 0;
}

=head2 tell

Return the difference between the current read position and the last write position

Example :

	my $pos = $rrfile->tell();

=cut
sub tell {
	my $self = shift;
	
	my $offset;
	
	if ($self->{_read_start_point_} >= $self->{_write_start_point_}) {
		$offset = $self->{_read_start_point_} - $self->{_write_start_point_};
	}
	else {
		$offset = ($self->{_file_length_} - $self->{_write_start_point_}) + 
				  ($self->{_read_start_point_} - $self->{_headers_size_});
	}
	return $offset % $self->{_data_length_};
}

=head2 convert_size

Converts the size from a human readable form into bytes

Example of acceptable formats :

=over 4

=item * 1000

=item * 120K  or 120Kb

=item * 15M  or 15Mb

=item * 1G  or 1Gb

=back

=cut
sub convert_size {
    my $size = shift;
    
    return undef unless defined $size;
    
    return $size if $size =~ /^\d+$/;
    
    my %sizes = (
                'K' => 10**3,
                'M' => 10**6,
                'G' => 10**9,
                );
    
    if ($size =~ /^(\d+(?:\.\d+)?)(K|M|G)b?$/i ) {
        return $1 * $sizes{uc($2)};
    }
    else {
        die "Broke size format. See pod for accepted formats";
    }

}


=head1 TIE INTERFACE IMPLEMENTATION

This module implements the TIEHANDLE interface and the objects an be used as normal 
file handles. 

See SYNOPSYS for more details on this

=cut

sub TIEHANDLE {
	my $class = shift;
	return $class->new(@_);
}

sub READ {
	my ($self,$buffer,$length,$offet) = @_;
	
	my $content = $self->read($length,$offet);
	$_[1] = $content;
	return length($content || '');
}

sub READLINE {
	my $self = shift;
	
	my $buffer;
	while (my $char = $self->read(1)) {
		$buffer .= $char;
		last if ($char =~ /[\n\r]/);
	}
	
	return $buffer;
}

sub GETC {
	my $self = shift;
	
	return $self->read(1,0);
}

sub WRITE {
	my ($self,$buffer,$length,$offet) = @_;
	
	return $self->write($buffer,$length,$offet);
}

sub PRINT {
	my ($self,@data) = @_;
	
	return $self->write($_) foreach @data;
}

sub PRINTF {
	my ($self,$format,@data) = @_;
	
	return $self->write(sprintf($format,@data));
}

# binmode does nothing, this is a text file
sub BINMODE {
	my $self = shift;
	CORE::binmode($self->{_fh_},@_);
}

sub EOF {
	my $self = shift;
	
	return $self->eof();
}

sub FILENO {
	my $self = shift;
	
	return CORE::fileno($self->{_fh_});
}

sub SEEK {
	my ($self,$position,$whence) = @_;
	
	return $self->seek($position,$whence);
}    

sub TELL {
	my $self = shift;
	
	return $self->tell();
}

sub OPEN {
	my ($self, $mode, @params) = @_;

	die "You cannot use the tie interface to open a file, use File::RoundRobin->new() instead!";
}

sub CLOSE {
	my $self = shift;
	
	$self->close();
}


# Does nothing
sub UNTIE {
	my $self = shift;
	return 0
}

DESTROY {
    my $self = shift;
    
    $self->close();
}

=head1 AUTHOR

Gligan Calin Horea, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-roundrobin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-RoundRobin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::RoundRobin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-RoundRobin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-RoundRobin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-RoundRobin>

=item * Search CPAN

L<http://search.cpan.org/dist/File-RoundRobin/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Gligan Calin Horea.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of File::RoundRobin
