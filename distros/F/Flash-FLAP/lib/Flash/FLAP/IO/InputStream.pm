package Flash::FLAP::IO::InputStream;
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)


=head1 NAME

    Flash::FLAP::IO::InputStream

=head1 DESCRIPTION    

    InputStream package built to handle getting the binary data from the raw input stream.

=head1 CHANGES    

=head2 Sat Mar 13 16:39:29 EST 2004

=item Changed calls to ord() in readByte() and concatenation readDouble() 
to prevent the appearance of the "uninitialized" warning.

=head2 Sun May 11 16:41:52 EDT 2003

=item Rewrote readInt to get rid of the "uninitialized" warning when reading bytes of value 0.

=cut

use strict;

#InputStream constructor
#arguments	$rd	raw data stream
sub new
{
    my ($proto,  $rd )=@_;
    my $self={};
    bless $self, $proto;
    $self->{current_byte}=0;
    # store the stream in this object
    my @array =  split //, $rd;
    $self->{raw_data} = \@array;
    # grab the total length of this stream
    $self->{content_length} = length($self->{raw_data});
    return $self;
}


# returns a single byte value.
sub readByte
{
    my ($self)=@_;
    # return the next byte
	my $nextByte = $self->{raw_data}->[$self->{current_byte}];
	my $result;
	$result = ord($nextByte) if $nextByte;
    $self->{current_byte} += 1;
    return $result;
}

# returns the value of 2 bytes
sub readInt
{
    my ($self)=@_;
    # read the next 2 bytes, shift and add
    
	my $thisByte = $self->{raw_data}->[$self->{current_byte}];
	my $nextByte = $self->{raw_data}->[$self->{current_byte}+1];

	my $thisNum = $thisByte ? ord($thisByte) : 0;
	my $nextNum = $nextByte ? ord($nextByte) : 0;

    my $result = (($thisNum) << 8) | $nextNum;

    $self->{current_byte} += 2;
    return $result;
}

# returns the value of 4 bytes
sub readLong
{
    my ($self)=@_;
    my $byte1 = $self->{current_byte};
    my $byte2 = $self->{current_byte}+1;
    my $byte3 = $self->{current_byte}+2;
    my $byte4 = $self->{current_byte}+3;
    # read the next 4 bytes, shift and add
    my $result = ((ord($self->{raw_data}->[$byte1]) << 24) | 
                    (ord($self->{raw_data}->[$byte2]) << 16) |
                    (ord($self->{raw_data}->[$byte3]) << 8) |
                        ord($self->{raw_data}->[$byte4]));
    $self->{current_byte} = $self->{current_byte} + 4;
    return $result;
}

# returns the value of 8 bytes
sub readDouble
{
    my ($self)=@_;
    # container to store the reversed bytes
    my $invertedBytes = "";
    # create a loop with a backwards index
    for(my $i = 7 ; $i >= 0 ; $i--)
    {
            # grab the bytes in reverse order from the backwards index
			my $nextByte = $self->{raw_data}->[$self->{current_byte}+$i];
			$invertedBytes .= $nextByte if $nextByte;
    }
    # move the seek head forward 8 bytes
    $self->{current_byte} += 8;
    # unpack the bytes
    my @zz = unpack("d", $invertedBytes);
    # return the number from the associative array
    return $zz[0];
}


# returns a UTF string
sub readUTF
{
    my ($self) = @_;
    # get the length of the string (1st 2 bytes)
    my $length = $self->readInt();
    # grab the string
    my @slice = @{$self->{raw_data}}[$self->{current_byte}.. $self->{current_byte}+$length-1];
    my $val = join "", @slice;
    # move the seek head to the end of the string
    $self->{current_byte} += $length;
    # return the string
    return $val;
}

# returns a UTF string with a LONG representing the length
sub readLongUTF
{
    my ($self) = @_;
    # get the length of the string (1st 4 bytes)
    my $length = $self->readLong();
    # grab the string
    my @slice = @{$self->{raw_data}}[$self->{current_byte} .. $self->{current_byte}+$length-1];
    my $val = join "", @slice;
    # move the seek head to the end of the string
    $self->{current_byte} += $length;
    # return the string
    return $val;
}

1;	
