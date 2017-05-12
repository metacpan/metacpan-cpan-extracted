package File::Binary;

# importage
use strict;
use Carp;
use Config;
use IO::File;
use vars qw(@EXPORT_OK $VERSION $BIG_ENDIAN $LITTLE_ENDIAN $NATIVE_ENDIAN $AUTOLOAD $DEBUG);
use Fcntl qw(:DEFAULT);

$VERSION='1.7';

# for seekable stuff
$DEBUG = 0;

# set up some constants
$BIG_ENDIAN     = 2;
$LITTLE_ENDIAN  = 1;
$NATIVE_ENDIAN  = 0;

# and export them
@EXPORT_OK = qw($BIG_ENDIAN $LITTLE_ENDIAN $NATIVE_ENDIAN guess_endian);


=head1 NAME

File::Binary - Binary file reading module

=head1 SYNOPSIS

    use File::Binary qw($BIG_ENDIAN $LITTLE_ENDIAN $NATIVE_ENDIAN);

    my $fb = File::Binary->new("myfile");
    
    $fb->get_ui8();
    $fb->get_ui16();
    $fb->get_ui32();
    $fb->get_si8();
    $fb->get_si16();
    $fb->get_si32();

    $fb->close();

    $fb->open(">newfile");

    $fb->put_ui8(255);
    $fb->put_ui16(65535);
    $fb->put_ui32(4294967295);
    $fb->put_si8(-127);
    $fb->put_si16(-32767);
    $fb->put_si32(-2147483645);
    
    $fb->close();


    $fb->open(IO::Scalar->new($somedata));
    $fb->set_endian($BIG_ENDIAN); # force endianness

    # do what they say on the tin
    $fb->seek($pos);
    $fb->tell();

    # etc etc


=head1 DESCRIPTION

B<File::Binary> is a Binary file reading module, hence the name, 
and was originally used to write a suite of modules for manipulating 
Macromedia SWF files. 

However it's grown beyond that and now actually, err, works. 
And is generalised. And EVERYTHING! Yay!

It has methods for reading and writing signed and unsigned 8, 16 and 
32 bit integers, at some point in the future I'll figure out a way of 
putting in methods for >32bit integers nicely but until then, patches 
welcome.

It hasn't retained backwards compatability with the old version of this 
module for cleanliness sakes and also because the old interface was 
pretty braindead.

=head1 METHODS

=head2 new

Pass in either a file name or something which isa an IO::Handle.

=cut 

sub new {
    my ($class, $file) = @_;

    my $self = {};
    
    bless $self,  $class;

    $self->open($file);
    $self->set_endian($NATIVE_ENDIAN);


    return $self;
}

=head2 open

Pass in either a file name or something which isa an IO::Handle.

Will try and set binmode for the handle on if possible (i.e
if the object has a C<binmode> method) otherwise you should do
it yourself.

=cut 

sub open {
    my ($self, $file) = @_;
    
    my $fh;
    my $writeable = -1;

    if (ref($file) =~ /^IO::/ && $file->isa('IO::Handle')) {
        $fh = $file;
        $writeable = 2; # read and write mode 
    } else {
        $fh = IO::File->new($file) || die "No such file $file\n";
        if ($file =~ /^>/) {
            $writeable = 1;
        } elsif ($file =~ /^\+>/) {
            $writeable=2;
        }
    }
    $fh->binmode if $fh->can('binmode');    

    $self->{_bitbuf}      = '';
    $self->{_bitpos}      = 0;
    $self->{_fh}          = $fh;
    $self->{_fhpos}       = 0;
    $self->{_flush}       = 1;
    $self->{_writeable}   = $writeable;
    $self->{_is_seekable} = UNIVERSAL::isa($fh,'IO::Seekable')?1:0;
              

    return $self;
}

=head2 seek

Seek to a position.

Return our current position. If our file handle is not 
B<ISA IO::Seekable> it will return 0 and, if 
B<$File::Binary::DEBUG> is set to 1, there will be a warning.

You can optionally pass a whence option in the same way as
the builtin Perl seek() method. It defaults to C<SEEK_SET>.

Returns the current file position.


=cut

sub seek {
    my $self = shift;
    my $seek = shift;
    my $whence = shift || SEEK_SET;
    unless ($self->{_is_seekable}) {
        carp "FH is not seekable" if $DEBUG; 
        return 0;
    }

    $self->{_fh}->seek($seek, $whence) if defined $seek;
    $self->_init_bits();
    return $self->{_fh}->tell();


    
}

=head2 tell

Return our current position. If our file handle is not 
B<ISA IO::Seekable> then it will return 0 and, if
B<$File::Binary::DEBUG> is set to 1, there will be a
warning.

=cut

sub tell {
    my $self = shift;
    unless ($self->{_is_seekable}) {
        carp "FH is not seekable" if $DEBUG;
        return 0;
    }

    return $self->{_fh}->tell();
}



=head2 set_flush

To flush or not to flush. That is the question

=cut

sub set_flush {
     my ($self, $flush) = @_;

    $self->{_flush} = $flush;
}


=head2 set_endian

Set the how the module reads files. The options are

    $BIG_ENDIAN 
    $LITTLE_ENDIAN 
    $NATIVE_ENDIAN


I<NATIVE> will deduce  the endianess of the current system.

=cut

sub set_endian {
    my ($self, $endian) = @_;

    $endian ||= $NATIVE_ENDIAN;

    $endian = guess_endian() if ($endian == $NATIVE_ENDIAN);

    if ($endian == $BIG_ENDIAN) {
        $self->{_ui16} = 'v';
        $self->{_ui32} = 'V';
    } else {
        $self->{_ui16} = 'n';
        $self->{_ui32} = 'N';
    }

    $self->{_endian} = $endian;        

}


sub _init_bits {
    my $self = shift;

    if ($self->{_writeable}) {
        $self->_init_bits_write();
    } else {
        $self->_init_bits_read();
    }
}


sub _init_bits_write {
    my $self = shift;

    my $bits = $self->{'_bitbuf'};

    my $len  = length($bits);

    return if $len<=0;

    $self->{'_bitbuf'} = '';
    $self->{_fh}->write(pack('B8', $bits.('0'x(8-$len))));

}

sub _init_bits_read {
    my $self = shift;  
  
    $self->{_pos}  = 0;
      $self->{_bits} = 0;

}


=head2 get_bytes

Get an arbitary number of bytes from the file.

=cut

sub get_bytes {
    my ($self, $bytes) = @_;
    
    $bytes = int $bytes;

    carp("Must be positive number")                  if ($bytes <1);
    carp("This file has been opened in write mode.") if $self->{_writeable} == 1;

    $self->_init_bits() if $self->{_flush};
      
    $self->{_fh}->read(my $data, $bytes);

    $self->{_fhpos} += $bytes;

      return $data;
}
  

=head2 put_bytes

Write some bytes

=cut

sub put_bytes {
    my ($self, $bytes) = @_;

    
    carp("This file has been opened in read mode.") unless $self->{_writeable};

    ## TODO?    
    #$self->_init_bits;
    $self->{_fh}->write($bytes);
}




# we could use POSIX::ceil here but I ph34r the POSIX lib
sub _round {
    my $num = shift || 0;

    return int ($num + 0.5 * ($num <=> 0 ) );
}





sub _get_num {
    my ($self, $bytes, $template)=@_;

    unpack $template, $self->get_bytes($bytes);
}


sub _put_num {
    my ($self, $num, $template) = @_;


    $self->put_bytes(pack($template, _round($num)));
}



## 8 bit

=head2 get_ui8 get_si8 put_ui8 put_si8

read or write signed or unsigned 8 bit integers

=cut

sub get_ui8 {
    my $self = shift;
    $self->_get_num(1, 'C');
}




sub get_si8 {
    my $self = shift;
    $self->_get_num(1, 'c');
}



sub put_ui8 {
    my ($self,$num) = @_;
    $self->_put_num($num, 'C');
}


sub put_si8 {
    my ($self,$num) = @_;
    $self->_put_num($num, 'c');

}


## 16 bit 

=head2 get_ui16 get_si16 put_ui16 put_si16

read or write signed or unsigned 16 bit integers

=cut

sub get_ui16 {
    my $self = shift;
    $self->_get_num(2, $self->{_ui16});
}


sub get_si16 {
    my $self = shift;
        
    my $num = $self->get_ui16();
    $num -= (1<<16) if $num>=(1<<15);

    return $num;
}



sub put_ui16 {
    my ($self,$num) = @_;
  
    $self->_put_num($num, $self->{_ui16});
}

*put_si16 = \&put_ui16;



## 32 bit

=head2 get_ui32 get_s32 put_ui32 put_si32

read or write signed or unsigned 32 bit integers

=cut



sub get_ui32 {
     my $self = shift;
     return $self->_get_num(4, $self->{_ui32});
}


sub get_si32 {
    my $self = shift;

    my $num = $self->get_ui32();
    $num -= (2**32) if ($num>=(2**31));
    return $num;
}


sub put_ui32 {
    my ($self, $num) = @_;

    $self->_put_num($num, $self->{_ui32});
}

*put_si32 = \&put_ui32;




=head2 guess_endian 

Guess the endianness of this system. Returns either I<$LITTLE_ENDIAN> 
or I<$BIG_ENDIAN>

=cut

sub guess_endian {


    #my $svalue = int rand (2**16)-1;
    #my $lvalue = int rand (2**32)-1;

    #my $sp = pack("S", $svalue);
    #my $lp = pack("L", $lvalue);


    #if (unpack("V", $lp) == $lvalue && unpack("v", $sp) == $svalue) {
    #    return $LITTLE_ENDIAN;
    #} elsif (unpack("N", $lp) == $lvalue && unpack("n", $sp) == $svalue) {
    #    return $BIG_ENDIAN;
    #} else {
    #    carp "Couldn't determine whether this machine is big-endian or little-endian\n";
    #}

    my $bo = $Config{'byteorder'};

    if (1234 == $bo or 12345678 == $bo) {
        return $LITTLE_ENDIAN;
    } elsif (4321 == $bo or 87654321 == $bo) {
        return $BIG_ENDIAN;
    } else {
        carp "Unsupported architecture (probably a Cray or weird order)\n";
    }


}


=head2 close
 
Close the file up. The I<File::Binary> object will then be useless 
until you open up another file;

=cut

sub close {
    my $self = shift;
    $self->{_fh}->close();
    $self = {};
}



=pod

=head1 BUGS

Can't do numbers greater than 32 bits.

Can't extract Floating Point or Fixed Point numbers.

Can't extract null terminated strings.

Needs tests for seeking and telling.

=head1 COPYING

(c)opyright 2002, Simon Wistow

Distributed under the same terms as Perl itself.

This software is under no warranty and will probably ruin your life, kill your friends, burn your house and bring about the apocalypse


=head1 AUTHOR

Copyright 2003, Simon Wistow <simon@thegestalt.org>


=cut


1;
