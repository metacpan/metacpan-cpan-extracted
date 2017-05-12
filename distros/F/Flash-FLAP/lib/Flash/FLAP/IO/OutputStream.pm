package Flash::FLAP::IO::OutputStream;
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)

=head1 NAME

    Flash::FLAP::IO::OutputStream

=head1 DESCRIPTION    

    Class used to convert the perl stuff into binary    

=cut

use strict;

# constructor
sub new
{
    my ($proto)=@_;
    # the buffer
    my $self = {};
    bless $self, $proto;
    $self->{outBuffer} = "";
    return $self;
}
# write a single byte
sub writeByte
{
    my ($self, $b)=@_;
    # use pack with the c flag
    $self->{outBuffer} .= pack("c", $b);
}	
# write 2 bytes
sub writeInt
{
    my ($self, $n) = @_;
    # use pack with the n flag
    $self->{outBuffer} .= pack("n", $n);
}
# write 4 bytes
sub writeLong
{
    my ($self, $l)=@_;
    # use pack with the N flag
    $self->{outBuffer} .= pack("N", $l);
}
# write a string
sub writeUTF
{
    my ($self, $s)=@_;
    # write the string length - max 65536
    $self->writeInt(length($s));
    # write the string chars
    $self->{outBuffer} .= $s;
}
#write a long string
sub writeLongUTF
{
    my ($self, $s)=@_;
    # write the string length - max 65536
    $self->writeLong(length($s));
    # write the string chars
    $self->{outBuffer} .= $s;
}
# write a double
sub writeDouble
{
    my ($self, $d)=@_;
    # pack the bytes
    my $b = pack("d", $d);
    my @b = split //, $b;
    # atleast on *nix the bytes have to be reversed
    # maybe not on windows, in php there in not flag to
    # force whether the bytes are little or big endian
    # for a double
    my $r = "";
    # reverse the bytes
    for(my $byte = 7 ; $byte >= 0 ; $byte--)
    {
        $r .= $b[$byte];
    }
    # add the bytes to the output
    $self->{outBuffer} .= $r;	
}
# send the output buffer
sub flush
{
    my ($self) = @_;
    # flush typically empties the buffer
    # but this is not a persistent pipe so it's not needed really here
    # plus it's useful to be able to flush to a file and to the client simultaneously
    # with out have to create another method just to peek at the buffer contents.
    return $self->{outBuffer};
}

1;
