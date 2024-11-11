package Image::Xbm ;    # Documented at the __END__

use strict ;

use vars qw( $VERSION @ISA ) ;
$VERSION = '1.11' ;

use Image::Base ;

@ISA = qw( Image::Base ) ;

use Carp qw( carp croak ) ;
use Symbol () ;


# Private class data 

my $DEF_SIZE = 8192 ;
my $UNSET    =   -1 ;
my $MASK     =    7 ;
my $ROWS     =   12 ;

# If you inherit don't clobber these fields!
my @FIELD = qw( -file -width -height -hotx -hoty -bits 
                -setch -unsetch -sethotch -unsethotch ) ;

my @MASK  = ( 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80 ) ;


### Private methods
#
# _class_get    class   object
# _class_set    class   object
# _get                  object inherited
# _set                  object inherited

{
    my %Ch = ( -setch    => '#', -unsetch    => '-', 
               -sethotch => 'H', -unsethotch => 'h' ) ;
        

    sub _class_get { # Class and object method
        my $self  = shift ;
        my $class = ref( $self ) || $self ;

        $Ch{shift()} ;
    }


    sub _class_set { # Class and object method
        my $self  = shift ;
        my $class = ref( $self ) || $self ;

        my $field = shift ;
        my $val   = shift ;

        croak "_class_set() `$field' has no value" unless defined $val ;

        $Ch{$field} = $val ;
     }
}


sub DESTROY {
    ; # Save's time
}


### Public methods

sub new_from_string { # Class and object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;

    my @line ;
    
    if( @_ > 1 ) {
        chomp( @line = @_ ) ;
    }
    else {
        @line = split /\n/, $_[0] ;
    }

    my( $setch, $sethotch, $unsethotch ) = 
        $class->get( '-setch', '-sethotch', '-unsethotch' ) ;

    my $width ;
    my $y = 0 ;
    
    $self = $class->new( '-width' => $DEF_SIZE, '-height' => $DEF_SIZE ) ;

    foreach my $line ( @line ) {
        next if $line =~ /^\s*$/ ;
        unless( defined $width ) {
            $width = length $line ;
            $self->_set( '-width' => $width ) ;
        }
        for( my $x = 0 ; $x < $width ; $x++ ) {
            my $c = substr( $line, $x, 1 ) ;
            $self->xybit( $x, $y, $c eq $setch ? 1 : $c eq $sethotch ? 1 : 0 ) ;
            $self->set( '-hotx' => $x, '-hoty' => $y ) 
            if $c eq $sethotch or $c eq $unsethotch ;
        }
        $y++ ;
    }

    $self->_set( '-height' => $y ) ;

    $self ;
}


sub new { # Class and object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $obj   = ref $self ? $self : undef ; 
    my %arg   = @_ ;

    # Defaults
    $self = {
            '-hotx' => $UNSET, 
            '-hoty' => $UNSET,
            '-bits' => '',
        } ;

    bless $self, $class ;

    # If $obj->new copy original object's data
    if( defined $obj ) {
        foreach my $field ( @FIELD ) {
            $self->_set( $field, $obj->get( $field ) ) ;
        }
    }

    # Any options specified override
    foreach my $field ( @FIELD ) {
        $self->_set( $field, $arg{$field} ) if defined $arg{$field} ;
    }

    my $file = $self->get( '-file' ) ;
    if (defined $file and not $self->{-bits}) {
        $self->load if ref $file or -r $file;
    }

    croak "new() `$file' not found or unreadable" 
    if defined $file and not defined $self->get( '-width' ) ;


    foreach my $field ( qw( -width -height ) ) {
        croak "new() $field must be set" unless defined $self->get( $field ) ;
    }

    $self ;
}


sub new_from_serialised { # Class and object method
    my $self       = shift ;
    my $class      = ref( $self ) || $self ;
    my $serialised = shift ;

    $self = $class->new( '-width' => $DEF_SIZE, '-height' => $DEF_SIZE ) ;

    my( $flen, $blen, $width, $height, $hotx, $hoty, $data ) =
        unpack "n N n n n n A*", $serialised ;
    
    my( $file, $bits ) = unpack "A$flen A$blen", $data ;

    $self->_set( '-file'   => $file ) ;
    $self->_set( '-width'  => $width ) ;
    $self->_set( '-height' => $height ) ;
    $self->_set( '-hotx'   => $hotx > $width  ? $UNSET : $hotx ) ;
    $self->_set( '-hoty'   => $hoty > $height ? $UNSET : $hoty ) ;
    $self->_set( '-bits'   => $bits ) ;

    $self ;
}


sub serialise { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my( $file, $bits ) = $self->get( -file, -bits ) ;
    my $flen = length( $file ) ;
    my $blen = length( $bits ) ;

    pack "n N n n n n A$flen A$blen", 
        $flen, $blen, 
        $self->get( -width ), $self->get( -height ), 
        $self->get( -hotx ),  $self->get( -hoty ),
        $file, $bits ;
}


sub get { # Object method (and class method for class attributes)
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
  
    my @result ;

    while( @_ ) {
        my $field = shift ;

        if( $field =~ /^-(?:un)?set(?:hot)?ch$/o ) {
            push @result, $class->_class_get( $field ) ;
        }
        else {
            push @result, $self->_get( $field ) ;
        }
    }

    wantarray ? @result : shift @result ;
}


sub set { # Object method (and class method for class attributes)
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    
    while( @_ ) {
        my $field = shift ;
        my $val   = shift ;

        carp "set() -field has no value" unless defined $val ;
        carp "set() $field is read-only"  
        if $field eq '-bits' or $field eq '-width' or $field eq '-height' ;
        carp "set() -hotx `$val' is out of range" 
        if $field eq '-hotx' and ( $val < $UNSET or $val >= $self->get( '-width' ) ) ;
        carp "set() -hoty `$val' is out of range" 
        if $field eq '-hoty' and ( $val < $UNSET or $val >= $self->get( '-height' ) ) ;

        if( $field =~ /^-(?:un)?set(?:hot)?ch$/o ) {
            $class->_class_set( $field, $val ) ;
        }
        else {
            $self->_set( $field, $val ) ;
        }
    }
}


sub xybit { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my( $x, $y, $val ) = @_ ; 

    # No range checking
    my $offset = ( $y * $self->get( '-width' ) ) + $x ;

    if( defined $val ) {
        CORE::vec( $self->{'-bits'}, $offset, 1 ) = $val ; 
    }
    else {
        CORE::vec( $self->{'-bits'}, $offset, 1 ) ; 
    }
}


sub xy { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my( $x, $y, $val ) = @_ ; 

    # No range checking
    my $offset = ( $y * $self->get( '-width' ) ) + $x ;

    if( defined $val ) {
        $val = 1 if ( $val =~ /^\d+$/ and $val >= 1 ) or 
                    ( lc $val eq 'black' )            or
                    ( $val =~ /^#(\d+)$/ and hex $1 ) ;
        CORE::vec( $self->{'-bits'}, $offset, 1 ) = $val ; 
    }
    else {
        CORE::vec( $self->{'-bits'}, $offset, 1 ) ? 'black' : 'white' ; 
    }
}


sub vec { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my( $offset, $val ) = @_ ; 

    # No range checking
    if( defined $val ) {
        CORE::vec( $self->{'-bits'}, $offset, 1 ) = $val ; 
    }
    else {
        CORE::vec( $self->{'-bits'}, $offset, 1 ) ; 
    }
}


sub is_equal { # Object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $obj   = shift ;

    croak "is_equal() can only compare $class objects" 
    unless ref $obj and $obj->isa( __PACKAGE__ ) ;

    # We ignore -file, -hotx and -hoty when we consider equality.
    return 0 if $self->get( '-width' )  != $obj->get( '-width' )  or 
                $self->get( '-height' ) != $obj->get( '-height' ) or
                $self->get( '-bits' )   ne $obj->get( '-bits' ) ;

    1 ;
}


sub as_string { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my $hotch = shift || 0 ;

    my( $setch,    $unsetch, 
        $sethotch, $unsethotch, 
        $hotx,     $hoty, 
        $bits, 
        $width,    $height ) =
            $self->get( 
                '-setch',    '-unsetch', 
                '-sethotch', '-unsethotch', 
                '-hotx',     '-hoty', 
                '-bits', 
                '-width',    '-height' ) ;

    my $bitindex = 0 ;
    my $string   = '' ;

    for( my $y = 0 ; $y < $height ; $y++ ) {
        for( my $x = 0 ; $x < $width ; $x++ ) {
            if( $hotch and $x == $hotx and $y == $hoty ) {
                $string .= CORE::vec( $bits, $bitindex, 1 ) ? 
                                $sethotch : $unsethotch ;
            }
            else {
                $string .= CORE::vec( $bits, $bitindex, 1 ) ? 
                                $setch : $unsetch ;
            }
            $bitindex++ ;
        }
        $string .= "\n" ;
    }

    $string ;
}


sub as_binstring { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    unpack "b*", $self->get( '-bits' ) ;
}


# The algorithm is based on the one used in Thomas Boutell's GD library.
sub load { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my $file  = shift() || $self->get( '-file' ) ;

    croak "load() no file specified" unless $file ;

    $self->set( '-file', $file ) ;

    my( @val, $width, $height, $hotx, $hoty ) ;
    local $_ ;
    my $fh = Symbol::gensym ;

    if( not ref $file ) {
        open $fh, $file or croak "load() failed to open `$file': $!" ;
    }
    elsif( ref($file) eq 'SCALAR' ) {
        require IO::String;
        $fh = IO::String->new( $$file );
    }
    else {
        seek($file, 0, 0) or croak "load() can't rewind handle for `$file': $!";
        $fh = $file;
    }

    while( <$fh> ) {
        $width  = $1, next if /#define.*width\s+(\d+)/o ; 
        $height = $1, next if /#define.*height\s+(\d+)/o ; 
        $hotx   = $1, next if /#define.*_x_hot\s+(\d+)/o ; 
        $hoty   = $1, next if /#define.*_y_hot\s+(\d+)/o ; 
        push @val, map { hex } /0[xX]([A-Fa-f\d][A-Fa-f\d]?)\b/g ; 
    }
    croak "load() failed to find dimension(s) in `$file'" 
    unless defined $width and defined $height ;

    close $fh or croak "load() failed to close `$file': $!" ;

    $self->_set( '-width',  $width ) ;
    $self->_set( '-height', $height ) ;
    $self->set( '-hotx',    defined $hotx ? $hotx : $UNSET ) ; 
    $self->set( '-hoty',    defined $hoty ? $hoty : $UNSET ) ;

    my( $x, $y ) = ( 0, 0 ) ;
    my $bitindex = 0 ;
    my $bits     = '' ;
    BYTE:
    for( my $i = 0 ; ; $i++ ) {
        BIT:
        for( my $bit = 1 ; $bit <= 128 ; $bit <<= 1 ) {
            CORE::vec( $bits, $bitindex++, 1 ) = ( $val[$i] & $bit ) ? 1 : 0 ;
            $x++ ;
            if( $x == $width ) {
                $x = 0 ;
                $y++ ;
                last BYTE if $y == $height ;
                last BIT ;
            }
        }
    }

    $self->_set( '-bits', $bits ) ;
}


# The algorithm is based on the X Consortium's bmtoa program.
sub save { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my $file   = shift() || $self->get( '-file' ) ;

    croak "save() no file specified" unless $file ;

    $self->set( '-file', $file ) ;

    my( $width, $height, $hotx, $hoty ) = 
        $self->get( '-width', '-height', '-hotx', '-hoty' ) ;

    my $MASK1  = $MASK + 1 ;
    my $ROWSn1 = $ROWS - 1 ;

    my $fh = Symbol::gensym ;
    open $fh, ">$file" or croak "save() failed to open `$file': $!" ;

    $file =~ s,^.*/,,o ;            
    $file =~ s/\.xbm$//o ;         
    $file =~ tr/_A-Za-z0-9/_/c ;
    
    print $fh "#define ${file}_width $width\n#define ${file}_height $height\n" ;
    print $fh "#define ${file}_x_hot $hotx\n#define ${file}_y_hot $hoty\n" 
    if $hotx > $UNSET and $hoty > $UNSET ; 
    print $fh "static unsigned char ${file}_bits[] = {\n" ;

    my $padded = ( $width & $MASK ) != 0 ;
    my @char ;
    my $char = 0 ;
    for( my $y = 0 ; $y < $height ; $y++ ) {
        for( my $x = 0 ; $x < $width ; $x++ ) {
            my $mask = $x & $MASK ;
            $char[$char] = 0 unless defined $char[$char] ;
            $char[$char] |= $MASK[$mask] if $self->xybit( $x, $y ) ; 
            $char++ if $mask == $MASK ;
        }
        $char++ if $padded ;
    }

    my $i = 0 ;
    my $bytes_per_char = ( $width + $MASK ) / $MASK1 ;
    foreach $char ( @char ) {
        printf $fh " 0x%02x", $char ;
        print  $fh "," unless $i == $#char ;
        print  $fh "\n" if $i % $ROWS == $ROWSn1 ;
        $i++ ;
    }
    print $fh " } ;\n";

    close $fh or croak "save() failed to close `$file': $!" ;
}


1 ;


__END__

=head1 NAME

Image::Xbm - Load, create, manipulate and save xbm image files.

=head1 SYNOPSIS

    use Image::Xbm ;

    my $j = Image::Xbm->new( -file, 'balArrow.xbm' ) ;

    my $i = Image::Xbm->new( -width => 10, -height => 16 ) ;

    my $h = $i->new ; # Copy of $i

    my $p = Image::Xbm->new_from_string( "###\n#-#\n###" ) ;

    my $q = $p->new_from_string( "H##", "#-#", "###" ) ;

    my $s = $q->serialse ; # Compresses a little too.
    my $t = Image::Xbm->new_from_serialsed( $s ) ;

    $i->xybit( 5, 8, 1 ) ;           # Set a bit
    print '1' if $i->xybit( 9, 3 ) ; # Get a bit
    print $i->xy( 4, 5 ) ;           # Will print black or white

    $i->vec( 24, 0 ) ;            # Set a bit using a vector offset
    print '1' if $i->vec( 24 ) ;  # Get a bit using a vector offset

    print $i->get( -width ) ;     # Get and set object and class attributes
    $i->set( -height, 15 ) ;

    $i->load( 'test.xbm' ) ;
    $i->save ;

    print "equal\n" if $i->is_equal( $j ) ; 

    print $j->as_string ;

    #####-
    ###---
    ###---
    #--#--
    #---#-
    -----#

    print $j->as_binstring ;

    1111101110001110001001001000100000010000

View an xbm file from the command line:

    % perl -MImage::Xbm -e'print Image::Xbm->new(-file,shift)->as_string' file

Create an xbm file from the command line:

    % perl -MImage::Xbm -e'Image::Xbm->new_from_string("###\n#-#\n-#-")->save("test.xbm")'

=head1 DESCRIPTION

This class module provides basic load, manipulate and save functionality for
the xbm file format. It inherits from C<Image::Base> which provides additional
manipulation functionality, e.g. C<new_from_image()>. See the C<Image::Base>
pod for information on adding your own functionality to all the C<Image::Base>
derived classes.

=head2 new()

    my $i = Image::Xbm->new( -file => 'test.xbm' ) ;
    my $j = Image::Xbm->new( -width => 12, -height => 18 ) ;
    my $k = $i->new ;

We can create a new xbm image by reading in a file, or by creating an image
from scratch (all the bits are unset by default), or by copying an image
object that we created earlier.

If we set C<-file> then all the other arguments are ignored (since they're
taken from the file). If we don't specify a file, C<-width> and C<-height> are
mandatory.

=over

=item C<-file>

The name of the file to read when creating the image. May contain a full path.
This is also the default name used for C<load>ing and C<save>ing, though it
can be overridden when you load or save.

=item C<-width>

The width of the image; taken from the file or set when the object is created;
read-only.

=item C<-height>

The height of the image; taken from the file or set when the object is created;
read-only.

=item C<-hotx>

The x-coord of the image's hotspot; taken from the file or set when the object
is created. Set to -1 if there is no hotspot.

=item C<-hoty>

The y-coord of the image's hotspot; taken from the file or set when the object
is created. Set to -1 if there is no hotspot.

=item C<-bits>

The bit vector that stores the image; read-only.

=back

=head2 new_from_string()

    my $p = Image::Xbm->new_from_string( "###\n#-#\n###" ) ;
    my $q = $p->new_from_string( "H##", "#-#", "###" ) ;
    my $r = $p->new_from_string( $p->as_string ) ;

Create a new bitmap from a string or from an array or list of strings. If you
want to use different characters you can:

    Image::Xbm->set( -setch => 'X', -unsetch => ' ' ) ;
    my $s = $p->new_from_string( "XXX", "X X", "XhX" ) ;

You can also specify a hotspot by making one of the characters a 'H' (set bit
hotspot) or 'h' (unset bit hotspot) -- you can use different characters by
setting C<-sethotch> and C<-unsethotch> respectively.

=head2 new_from_serialised()

    my $i = Image::Xbm->new_from_serialised( $s ) ;

Creates an image from a string created with the C<serialse()> method. Since
such strings are a little more compressed than xbm files or Image::Xbm objects
they might be useful if storing a lot of bitmaps, or for transferring bitmaps
over comms links.

=head2 serialise()

    my $s = $i->serialise ;

Creates a string version of the image which can be completed recreated using
the C<new_from_serialised> method.

=head2 get()
    
    my $width = $i->get( -width ) ;
    my( $hotx, $hoty ) = $i->get( -hotx, -hoty ) ;

Get any of the object's attributes. Multiple attributes may be requested in a
single call.

See C<xy> and C<vec> to get/set bits of the image itself.

=head2 set()

    $i->set( -hotx => 120, -hoty => 32 ) ;

Set any of the object's attributes. Multiple attributes may be set in a single
call. Except for C<-setch> and C<-unsetch> all attributes are object
attributes; some attributes are read-only.

See C<xy> and C<vec> to get/set bits of the image itself.

=head2 class attributes

    Image::Xbm->set( -setch => 'X' ) ;
    $i->set( -setch => '@', -unsetch => '*' ) ;

=over

=item C<-setch>

The character to print set bits as when using C<as_string>, default is '#'.
This is a class attribute accessible from the class or an object via C<get>
and C<set>.

=item C<-unsetch>

The character to print set bits as when using C<as_string>, default is '-'.
This is a class attribute accessible from the class or an object via C<get>
and C<set>.

=item C<-sethotch>

The character to print set bits as when using C<as_string>, default is 'H'.
This is a class attribute accessible from the class or an object via C<get>
and C<set>.

=item C<-unsethotch>

The character to print set bits as when using C<as_string>, default is 'h'.
This is a class attribute accessible from the class or an object via C<get>
and C<set>.

=back

=head2 xybit()

    $i->xy( 4, 11, 1 ) ;      # Set the bit at point 4,11
    my $v = $i->xy( 9, 17 ) ; # Get the bit at point 9,17

Get/set bits using x, y coordinates; coordinates start at 0.

=head2 xy()

    $i->xy( 4, 11, 'black' ) ;  # Set the bit from a colour at point 4,11
    my $v = $i->xy( 9, 17 ) ;   # Get the bit as a colour at point 9,17

Get/set bits using colours using x, y coordinates; coordinates start at 0.

If set with a colour of 'black' or a numeric value > 0 or a string not
matching /^#0+$/ then the bit will be set, otherwise it will be cleared.

If you get a colour you will always get 'black' or 'white'.

=head2 vec()

    $i->vec( 43, 0 ) ;      # Unset the bit at offset 43
    my $v = $i->vec( 87 ) ; # Get the bit at offset 87

Get/set bits using vector offsets; offsets start at 0.

=head2 load()

    $i->load ;
    $i->load( 'test.xbm' ) ;

Load the image whose name is given, or if none is given load the image whose
name is in the C<-file> attribute.

=head2 save()

    $i->save ;
    $i->save( 'test.xbm' ) ;

Save the image using the name given, or if none is given save the image using
the name in the C<-file> attribute. The image is saved in xbm format, e.g.

    #define test_width 6
    #define test_height 6
    static unsigned char test_bits[] = {
     0x1f, 0x07, 0x07, 0x09, 0x11, 0x20 } ;

=head2 is_equal()

    print "equal\n" if $i->is_equal( $j ) ;

Returns true (1) if the images are equal, false (0) otherwise. Note that
hotspots and filenames are ignored, so we compare width, height and the actual
bits only.

=head2 as_string()

    print $i->as_string ;

Returns the image as a string, e.g.

    #####-
    ###---
    ###---
    #--#--
    #---#-
    -----#

The characters used may be changed by C<set>ting the C<-setch> and C<-unsetch>
characters. If you give C<as_string> a parameter it will print out the hotspot
if present using C<-sethotch> or C<-unsethotch> as appropriate, e.g.

    print $n->as_string( 1 ) ;

    H##
    #-#
    ###

=head2 as_binstring()

    print $i->as_binstring ;

Returns the image as a string of 0's and 1's, e.g.

    1111101110001110001001001000100000010000

=head1 CHANGES

2024/11/10

Allow filehandles in new()


2016/02/23 (Slaven Rezic)

Make sure macro/variable names are always sane.

More strict parsing of bits.


2000/11/09

Added Jerrad Pierce's patch to allow load() to accept filehandles or strings;
will document in next release.


2000/05/05

Added new_from_serialised() and serialise() methods.


2000/05/04

Made xy() compatible with Image::Base, use xybit() for the earlier
functionality.


2000/05/01

Improved speed of vec(), xy() and as_string().

Tried use integer to improve speed but according to Benchmark it made the code
slower so I dropped it; interestingly perl 5.6.0 was around 25% slower than
perl 5.004 with and without use integer.


2000/04/30 

Created. 


=head1 AUTHOR

Mark Summerfield. I can be contacted as <summer@perlpress.com> -
please include the word 'xbm' in the subject line.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 2000. All Rights Reserved.

This module may be used/distributed/modified under the LGPL. 

=cut

