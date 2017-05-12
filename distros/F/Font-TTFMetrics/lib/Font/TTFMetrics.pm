# $Id: TTFMetrics.pm,v 1.4 2003/06/09 13:03:04 malay Exp $
# Perl module for Font::TTFMetrics
# Author: Malay < curiouser@ccmb.res.in >
# Copyright (c) 2003 by Malay. All rights reserved.
# You may distribute this module under the same terms as perl itself

=head1 NAME

Font::TTFMetrics - A parser for the TTF file.

=head1 SYNOPSIS

  use Font::TTFMetrics;

  my $metrics = Font::TTFMetrics->new("somefont.ttf");
  my $ascent = $metrics->get_ascent();
 

=head1 DESCRIPTION

C<Font::TTFMetrics> encapsulates the font metrics of a true type font
file. A true type font file contains several tables which need to be
parsed before any useful information could be gathered about the
font. There is the excellent module for parsing TTF font in CPAN by
Martin Hosken, C<Font::TTF>. But in my opinion the use of C<Font::TTF>
requires intimate knowledge of TTF font format. This module was
written to support the use of TTF in C<Pastel> 2D graphics library in
Perl. Three factors prompted me to write this module: first, I
required a fast module to access TTF file. Second, all the access
required was read-only. Last, I wanted a user friendly, higher level
API to access TTF file.

Each font file actually contains several informations the most
important information is how a particular character will display on
screen. The shape of a character (glyph) is determined by a series of
points. The points are generally lines or points on curved path. For
details see the TTF specification. Remember, the points actually
determines the outline of the curve.TTF file stores the glyph shape in
the "glyf" table of the font. The first glyph described in this table
will be always a particular glyph, called "missing-glyph" which is
shown in case the font file doesnot contains the glyph that a software
wants.

Each character in computer is actually a number. You can find what
number corresponds to the character, you can call C<ord()> on the
character. This value is called the ordinal value of the character. If
you just use common english typically the number of any character
falls between 32-126, commonly called as ASCII. If you use some more
extra character not commonly found in key-board like "degree" then
your character code will fall between 0-255, commonly called LATIN-1
character set. Unicode is a way to use charaters with ordinal values
beyond 255. The good thing about it is that the UTF8 encoding in perl
works silently in the backdrop and you can intermix characters with
any ordinal value. This ofcourse does not mean that you will be able
to use character with any ordinal values for display. The font file
must contains the corresponding glyph.

The way to extract the glyph for a character is done by looking into
"cmap" table of the font. This table contains the character ordinal
number and a correspoding index. This index is used to look into the
"glyf" table to extract the shape of the character. Thar means if you
just substitute another index for a particular ordinal number you can
actually display a different character, a mechanism known as "glyph
substitution". As you can guess there is one more way to display a
particular character instead of what if should display in a more font
specific manner. If you just add a particular offset to a glyph
ordinal value and provide the index for this added value in the "cmap"
table, you can generate a completely different glyph. This mechanism
works for a particular type of fonts supplied by Microsoft called
symbol fonts. Example of these are symbol.ttf and wingding. Both these
fonts does not supply any glyphs corresponding to LATIN-1 character
sets but with ordinal values in the range of 61472-61695. But notice
if you fire up your word-processor and change the font to symbol and
type any character on the key board you get a display. For example, if
you type A (ordinal value 65) what you get is greek capital
alpha. This works this way: as soon as the word-processor find that
you are using a symbol font (you can call C<is_symbol()> method to
find that) it just adds 61440 to any character you type and then
queries the "cmap" table for the glyph.

One more important aspect of using a TTF file is to find the width of
a string. The easiest way to find this to query "htmx" table, which
contains advanced width of each character, add up all the advance
widths of the individual characters in the string and then go look
into "kern" table, which contains the kerning value for pair of glyphs
add deduct these values from the total width. You need to deduct also
the left-side bearing of the first character and the right-side
bearing of the last character from the total width.

User of this module should keep in mind that all the values
returned from this modules are in font-units and should be converted
to pixel unit by:

  fIUnits * pointsize * resolution /(72 * units_per_em)

An example from the true type specification at
L<http://www.microsoft.com/typography/otspec/TTCH01.htm>:

A font-feature of 550 units when used with 18 pt on screen (typically
72 dpi resolution) will be

  550 * 18 * 72 / ( 72 * 2048 ) = 4.83 pixels long.

Note that the C<units_per_em> value is 2048 which is typical for a TTF
file. This value can be obtained by calling C<get_units_per_em()> call.

This module also takes full advantage of the unicode support of
Perl. Any strings that you pass to any function call in this module
can have unicode built into into it. That means a string like:

 "Something \x{70ff}" is perfectly valid.



=cut

package Font::TTFMetrics;

$Font::TTFMetrics::VERSION = 0.1;

use IO::File;
use Carp;
use strict;

my @glyph_name_index = ();
my @post_glyph_name  = ();
my @mac_glyph_name   = ();

=head1 CONSTRUCTOR

=head2 new()

Creates and returns a C<Font::TTFMetrics> object.

 Usage   : my $metrics = Font::TTFMetrics->new($file); 
 Args    : $file - TTF filename.
 Returns : A Font::TTFMetrics object.

=cut

sub new {
    my $arg   = shift;
    my $class = ref($arg) || $arg;
    my $self  = {};

    bless $self, $class;
    $self->_init(@_);

    return $self;

}

sub _init {

    my ( $self, @args ) = @_;

    unless (@args) {
        croak "Supply filename in Font::TTFMetrics::new()\n";
    }

    my ($file) = $self->_rearrange( ["FILE"], @args );

    $self->{_fh}           = undef;
    $self->{family}        = undef;
    $self->{glyphs}        = [];
    $self->{tables}        = {};
    $self->{platform}      = 3;
    $self->{encoding}      = 1;
    $self->{subfamily}     = undef;
    $self->{glyph_index}   = [];
    $self->{advance_width} = [];
    $self->{lsb}           = [];

    #   $self->{number_of_glyphs} = undef;

    $self->set_file_handle($file);
    $self->make_directory_entry();
    $self->is_symbol();
    $self->make_ps_name_table();
    $self->make_glyph_index();

    #print STDERR "After glyph index\n";
    #$self->make_advance_width();
    $self->process_kern_table();
}

#sub create_from_file {
#    my ( $self, @args ) = @_;
#    my $mod = Pastel::Font::TTF->new();
#    my ( $path, $file ) = $mod->_rearrange( [ "PATH", "FILE" ], @args );
#    my $fh;

#    if ( defined($path) || defined($file) ) {

#        if ( defined($path) ) {
#            $mod->set_file_handle($path);

#            #return $mod;
#        }
#        if ( defined($file) ) {
#            $mod->set_file_handle($file);

#            #return $mod;
#        }

#    }
#    else {
#        croak "Supply filename in Pastel::Font::TTF::create_from_file()\n";
#    }
#    $mod->make_directory_entry();
#    $mod->is_symbol();

#    # print STDERR "before glyph call\n";
#    #$mod->make_glyph_index();
#    $mod->make_ps_name_table();

#    return $mod;
#}

=head1 METHODS

=head2 is_symbol()

Returns true if the font is a Symbol font from Microsoft. Remember
that Wingding is also a symbol font.

 Usage   : $metrics->is_symbol();
 Args    : Nothing.
 Returns : True if the font is a Symbol font, false otherwise.

=cut

sub is_symbol {
    my $self = shift;
    if ( defined( $self->{is_symbol} ) ) {
        return $self->{is_symbol};
    }
    my $fh  = $self->get_file_handle();
    my $buf = "";
    my $add = $self->get_table_address("name");
    seek( $fh, $add, 0 );
    read( $fh, $buf, 6 );
    my ( $num, $offset ) = unpack( "x2nn", $buf );

    # loop through the name table whether there is an entry of
    # encoding 0 of platform ID 3. If there is one the font must be a
    # symbol font. I could not find a better way to do this.

    for ( my $i = 0 ; $i < $num ; $i++ ) {
        read( $fh, $buf, 12 );
        my ( $id, $encoding, $language, $name_id, $length, $string_offset ) =
          unpack( "n6", $buf );
        if ( $id == $self->{platform} && $encoding == 0 ) {
            $self->{is_symbol} = 1;
            $self->{encoding}  = 0;
            return $self->{is_symbol};
        }
    }
    $self->{is_symbol} = 0;

    return $self->{is_symbol};
}

sub make_directory_entry {
    my $self = shift;
    my $fh   = $self->get_file_handle();
    my $buf  = "";

    eval { read( $fh, $buf, 12 ) };
    if ($@) {
        croak "Read error in Pastel::Font::TTF::make_directory_entry\n";
    }

    my ( $version, $number ) = unpack( "Nn", $buf );

    #print "Version = $version, Number of tables = $number\n";
    # print "\nTABLE\tOFFSET\tLENGTH\n";

    for ( my $i = 0 ; $i < $number ; $i++ ) {

        #print "Inside for\n";
        read( $fh, $buf, 16 );
        my ( $table, $offset, $length ) = unpack( "a4x4NN", $buf );
        $self->{table}->{$table} = $offset;

        #print "$table\t$offset\t$length\n";
    }

    #print $self->{table}->{'OS/2'};
}

sub get_table_address {
    my $self       = shift;
    my $table_name = shift;

    if ( defined( $self->{table}->{$table_name} ) ) {
        return $self->{table}->{$table_name};
    }
    else {

        #       croak
        #          "Undefined table address in Font::TTFMetrics::get_table_address()\n";
        return 0;
    }
}

=head2 char_width()

Returns the advance width of a single character, in font units.

 Usage   : $font->char_width('a');
 Args    : A single perl character. Can be even a unicode.
 Returns : A scalar value. The width of the character in font units.

=cut

sub char_width {
    my ( $self, $char ) = @_;
    my $ord = ord($char);
    if ( $self->is_symbol() ) {
        $ord = $ord + 61440;
    }
    my $index = $self->get_glyph_index($ord);
    return $self->get_advance_width($index);

}

=head2 string_width()

Given a string the function returns the width of the string in font
units. The function at present only calculates the advanced width of
the each character and deducts the calculated kerning from the whole
length. If some one has any better idea then let me know.

 Usage   : $font->string_width("Some string");
 Args    : A perl string. Can be embedded unicode.
 Returns : A scalar indicating the width of the whole string in font units.

=cut

sub string_width{
  my ($self,$string) = @_;
  my @s = split(//, $string);
  
  my $kern = 0;
  my $width = 0;

  for (my $i = 0; $i <@s; $i++) {
      my $ord = ord($s[$i]);
      if ($self->is_symbol()) {
	  $ord = $ord + 61440;
      }
      my $index = $self->get_glyph_index($ord);
      $width = $width + $self->get_advance_width($index);
      if ($i < @s -1) {
	 my $ord_plus_one = ord($s[$i + 1]);
	 if ($self->is_symbol()) {
	     $ord_plus_one = $ord_plus_one + 61440;
	 }
	 my $index_plus_one = $self->get_glyph_index($ord_plus_one);
	 $kern = $kern + $self->kern_value($index, $index_plus_one);
     }
  }
  my $start_ord = ord ($s[0]);
  if ($self->is_symbol()) {
      $start_ord = $start_ord + 61440;
  }
  my $start_index = $self->get_glyph_index($start_ord);
  #print STDERR "\n****start index : $start_index\n";
  #my $lsb = $self->get_lsb($start_index);
  return $width + $kern;
}

# returns the glyph index for a given chracter ordinal number from the
# cmap table. The function first check whether the ordinal number
# passed to it lies in the range 0-255. If it is then it simple get
# the index number from the $self->{glyph_index} array set by
# make_glyph_index(). If the ordinal value is greater than 255 the
# function queries the cmap table itself and returns the value.

sub get_glyph_index {
    my $self = shift;
    my $char = shift;    # ordinal number of the character
    if ( $char < 256 ) {
        return $self->{glyph_index}->[$char];
    }
    my $buf = "";
    my $fh  = $self->get_file_handle();
    my $add = $self->get_table_address('cmap');
    my $offset;

    seek( $fh, $add, 0 );
    read( $fh, $buf, 4 );
    my $num = unpack( "x2n", $buf );

    for ( my $i = 0 ; $i < $num ; $i++ ) {
        read( $fh, $buf, 8 );
        my ( $id, $encoding, $off ) = unpack( "nnN", $buf );

        #print $id , "\n";
        #print $encoding , "\n";

        if ( $id == $self->{platform} && $encoding == $self->{encoding} ) {

            #print "Match Found ", $id, "\n";
            # print "Offset: $off\n";
            $offset = $off;

            last;
        }
    }

    seek( $fh, $add + $offset, 0 );
    read( $fh, $buf, 6 );
    my ( $format, $length, $version ) = unpack( "nnn", $buf );
    read( $fh, $buf, 8 );

    #print STDERR "\nlength = $length\n";
    my ( $seg_countX2, $search_range, $entry_selector, $range_shift ) =
      unpack( "nnnn", $buf );
    my $seg_count = $seg_countX2 / 2;

    #print STDERR "\n",$seg_count,"\n"; 
    read( $fh, $buf, 2 * $seg_count );
    my (@end_count) = unpack( "n" x $seg_count, $buf );
    read( $fh, $buf, 2 );

    #my $reserve_pad = unpack( "n", $buf );
    read( $fh, $buf, 2 * $seg_count );
    my (@start_count) = unpack( "n" x $seg_count, $buf );

    #print STDERR "\n", "@start_count","\n";

    #print "Start Count: ", join("\t",@start_count), "\n";

    read( $fh, $buf, 2 * $seg_count );
    my (@id_delta) = unpack( "n" x $seg_count, $buf );

    #print "idDelta: ", join("\t",@id_delta), "\n";

    read( $fh, $buf, 2 * $seg_count );
    my (@id_range_offset) = unpack( "n" x $seg_count, $buf );

    #print "idRangeOffset: ", join("\t",@id_range_offset), "\n";

    #my $num1 = read( $fh, $buf, $length - ( $seg_count * 8 ) - 16 );
    #my (@glyph_id) = unpack( "n" x ( $num1 / 2 ), $buf );
    #print STDERR "\n",join("\n",@glyph_id),"\n";
    #my $i;
    #my $j;
    my $index;
    my $present =
      0;    # boolean to indicate the char code is actually present or not
    for ( my $i = 0 ; $i < $seg_count ; $i++ ) {
        if ( $start_count[$i] <= $char && $end_count[$i] >= $char ) {
            $index   = $i;
            $present = 1;
            last;
        }

    }

    #print STDERR "\nIndex: ", $index,"\n";
    #print STDERR "\nId offset: ", $id_range_offset[$index],"\n";
    my $glyph;

    # If the char code is not there just return the missing glyph
    if ( !$present ) {
        return 0;
    }
    elsif ( $id_range_offset[$index] != 0 ) {
        my $glyph_id_index =
          $id_range_offset[$index] / 2 + ( $char - $start_count[$index] ) -
          ( $seg_count - $index );

        seek( $fh, $glyph_id_index * 2, 1 );
        read( $fh, $buf, 2 );
        $glyph = unpack( "n", $buf );

        #print STDERR "is range not 0\n";
        #print STDERR "\nGlyph : $glyph\n";
    }
    else {
        $glyph = ( $id_delta[$index] + $char ) % 65536;
    }

    return $glyph;
}

# Look into the cmap table and create and array of 256 glyph
# indexes. Should be called only once during the initialization of the
# module. This array is used to find quickly the index of a particulr
# glyph if the ordinal value of the character lies in the range
# 0-255. If the ordinal number in greater than 255 use
# get_glyph_index() to get the index of particular glyph.

sub make_glyph_index {

    #print STDERR "**Inside glyph index\n";
    my $self = shift;
    my $buf;
    my $offset;
    my $PLATFORM_ID = $self->{platform};
    my $ENCODING_ID = $self->{encoding};
    my $fh          = $self->get_file_handle();
    my $cmap        = $self->get_table_address("cmap");
    my @glyph_index;

    #Go there
    seek( $fh, $cmap, 0 );

    #'cmap' table starts with
    # USHORT    Table version number
    # USHORT    Number of encoding tables
    # Read 4 bytes
    read( $fh, $buf, 4 );

    #Get number of tables and skip the version number
    my ($num) = unpack( "x2n", $buf );

    # Read the tables. There will $num tables
    # Each one for a specific encoding and platform id
    # There are three most important id and encoding-
    # Windows        :      ID=3    Encoding = 1
    # Windows symbol :      ID=3    Encoding = 0
    # Mac/Poscript   :      ID=1    Encoding = 0

    #Each subtable:
    # USHORT         Platform ID
    # USHORT         Platform specific encoding ID
    # ULONG          Byte ofset from the begining of the 'cmap' table

    for ( my $i = 0 ; $i < $num ; $i++ ) {
        read( $fh, $buf, 8 );
        my ( $id, $encoding, $off ) = unpack( "nnN", $buf );

        #print $id , "\n";
        #print $encoding , "\n";

        if ( $id == $PLATFORM_ID && $encoding == $ENCODING_ID ) {

            #print "Match Found ", $id, "\n";
            # print "Offset: $off\n";
            $offset = $off;
            seek( $fh, $cmap + $offset, 0 );
        }
    }

    #Goto the specific table

    # Mac/Poscript table with encoding 0 use the following format
    # USHORT    format set to 0
    # USHORT    length
    # USHORT    version starts at 0
    # BYTE      glyphIdArray[256] There is no trick here just read the whole
    #           thing as 256 array

    # If MAC/Postcript table
    if ( $PLATFORM_ID == "1" && $ENCODING_ID == "0" ) {

        # Skip the format, length and version information
        read( $fh, $buf, 6 );

        #print (unpack("nnn", $buf));
        # Now read the 256 element array directly

        for ( my $i = 0 ; $i < 256 ; $i++ ) {
            read( $fh, $buf, 1 );

            #print $buf;
            $glyph_index[$i] = unpack( "C", $buf );

            #print $glyph_index[$i];
            #print "Char $i\t\t-> Index $glyph_index[$i]\n";
        }

    }

    # Windows  table with encoding 1 use the following format FORMAT 4
    #   USHORT         format                 Format number is set to 4. 
    #    USHORT         length                 Length in bytes. 
    #    USHORT         version                Version number (starts at 0).
    #    USHORT         segCountX2             2 x segCount.
    #    USHORT         searchRange            2 x (2**floor(log2(segCount)))
    #    USHORT         entrySelector          log2(searchRange/2)
    #    USHORT         rangeShift             2 x segCount - searchRange
    #    USHORT         endCount[segCount]     End characterCode for each segment,
    #                                           last =0xFFFF.
    #    USHORT         reservedPad            Set to 0.
    #    USHORT         startCount[segCount]   Start character code for each segment.
    #    USHORT         idDelta[segCount]      Delta for all character codes in segment.
    #    USHORT         idRangeOffset[segCount]Offsets into glyphIdArray or 0
    #    USHORT         glyphIdArray[ ]        Glyph index array (arbitrary length)

    if ( $PLATFORM_ID == 3 ) {
        read( $fh, $buf, 6 );
        my ( $format, $length, $version ) = unpack( "nnn", $buf );

        #print "Format: $format\tLength: $length\tVersion: $version\n\n";
        read( $fh, $buf, 8 );
        my ( $seg_countX2, $search_range, $entry_selector, $range_shift ) =
          unpack( "nnnn", $buf );
        my $seg_count = $seg_countX2 / 2;

        #print "SegcountX2:\t\t$seg_countX2\n";
        #print "Search Range:\t$search_range\n";
        #print "Entry:\t$entry_selector\n";
        #print "Range Shift:\t$range_shift\n";

        read( $fh, $buf, 2 * $seg_count );
        my (@end_count) = unpack( "n" x $seg_count, $buf );

        #print "EndCount: ", join("\t",@end_count), "\n";
        read( $fh, $buf, 2 );
        my $reserve_pad = unpack( "n", $buf );

        #print "Reserve Pad: $reserve_pad\n";

        read( $fh, $buf, 2 * $seg_count );
        my (@start_count) = unpack( "n" x $seg_count, $buf );

        #print "Start Count: ", join("\t",@start_count), "\n";

        read( $fh, $buf, 2 * $seg_count );
        my (@id_delta) = unpack( "n" x $seg_count, $buf );

        #print "idDelta: ", join("\t",@id_delta), "\n";

        read( $fh, $buf, 2 * $seg_count );
        my (@id_range_offset) = unpack( "n" x $seg_count, $buf );

        #print "idRangeOffset: ", join("\t",@id_range_offset), "\n";

        my $num = read( $fh, $buf, $length - ( $seg_count * 8 ) - 16 );
        my (@glyph_id) = unpack( "n" x ( $num / 2 ), $buf );

        #print STDERR "\n",join("\n",@glyph_id),"\n",
        my $i;
        my $j;

        #print "Last count:", $end_count[$#end_count], "\n";
        for ( $j = 0 ; $j < $seg_count ; $j++ ) {

            #for ( $i = $start_count[$j] ; $i <= $end_count[$j] ; $i++ ) {
            for ( $i = $start_count[$j] ; $i < 256 ; $i++ ) {

                #print $start_count[$j], "****", $end_count[$j], "\n";

                #if ($end_count[$j] >= $i && $start_count[$j] <= $i){
                #print "ID RANGE OFFSET $id_range_offset[$j]", "\n";
                if ( $id_range_offset[$j] != 0 ) {

                    $glyph_index[$i] = $glyph_id[ $id_range_offset[$j] / 2 +
                      ( $i - $start_count[$j] ) - ( $seg_count - $j ) ];
                }
                else {
                    $glyph_index[$i] = ( $id_delta[$j] + $i ) % 65536;

                }

                if ( !defined( $glyph_index[$i] ) ) {

                    #$glyph_index[$i] = $glyph_id[0];
                    $glyph_index[$i] = 0;
                }
            }
        }

        for ( my $i = 0 ; $i < @glyph_index ; $i++ ) {
            if ( !defined( $glyph_index[$i] ) ) {
                $glyph_index[$i] = 0;
            }
        }
    }
    $self->{glyph_index} = \@glyph_index;

    # print STDERR "\n","Number of glyphs:", scalar(@{$self->{glyph_index}}), "\n";
    # print STDERR "\n","glyphs:", "@{$self->{glyph_index}}", "\n";
}

sub make_advance_width {
    my $self = shift;
    if ( $self->is_symbol() ) {
        return;
    }
    my $fh = $self->get_file_handle();
    my $buf;

    #print STDERR "***", $self->{table}->{"hhea"}, "\n";
    seek( $fh, $self->get_table_address("hhea"), 0 );
    read( $fh, $buf, 36 );
    my ($num) = unpack( "x34n", $buf );
    my $number_of_glyphs = $self->maxp_get_number_of_glyph();

    #$num = $num > 256 ? 256: $num;

    #print STDERR "*** ", $num, "\n";
    seek( $fh, $self->get_table_address("hmtx"), 0 );
    read( $fh, $buf, 4 * $num );
    my (@temp) = unpack( "n" x ( 2 * $num ), $buf );
    my @advanced_width;
    my @lsb;
    my $index = @temp;

    # if ($num > 256) {
    #	$index = 256 * 2;
    #    }
    for ( my $i = 0 ; $i < $index - 1 ; $i++ ) {
        $advanced_width[@advanced_width] = $temp[$i];
        $lsb[@lsb] = $temp[ $i + 1 ] - ( $temp[ $i + 1 ] > 32768 ? 65536 : 0 );
        $i++;
    }

    my $end_lsb = $number_of_glyphs;

    # if ($number_of_glyphs > 256) {
    #	$end_lsb = 256;
    #    }else {
    #	$end_lsb = $number_of_glyphs;
    #    }
    if ( @lsb < $end_lsb ) {
        my $more_lsb = $end_lsb - scalar(@lsb);
        read( $fh, $buf, 2 * $more_lsb );
        @temp = unpack( "n*", $buf );
        for ( my $i = 0 ; $i < @temp ; $i++ ) {
            $lsb[@lsb] = $temp[$i] - ( $temp[$i] > 32768 ? 65536 : 0 );
        }

    }
    undef(@temp);
    my @ad;
    my @l;

    for ( my $i = 0 ; $i < 256 ; $i++ ) {
        my $index = $self->get_glyph_index($i);
        if ( $advanced_width[$index] ) {
            $ad[$i] = $advanced_width[$index];
        }
        else {
            $ad[$i] = $advanced_width[0];
        }
        if ( defined( $lsb[$index] ) ) {

            $l[$i] = $lsb[$index];
        }
        else {
            $l[$i] = $lsb[0];
        }
    }

    $self->{advance_width} = \@ad;
    $self->{lsb}           = \@l;

    #print STDERR "\n",$self->get_font_family(),$self->get_subfamily(),"\n";
    #print STDERR "\nadv:\n@advanced_width", "\n";
    #print STDERR "\nlsb\n@lsb", "\n";
}


sub get_lsb {
    my ($self, $index) = @_;

    my $fh = $self->get_file_handle();
    my $buf;

    seek( $fh, $self->get_table_address("hhea"), 0 );
    read( $fh, $buf, 36 );
    my ($num) = unpack( "x34n", $buf );
    my $number_of_glyphs = $self->maxp_get_number_of_glyph();

    #$num = $num > 256 ? 256: $num;

    #print STDERR "*** ", $num, "\n";
    seek( $fh, $self->get_table_address("hmtx"), 0 );
    read( $fh, $buf, 4 * $num );
    my (@temp) = unpack( "n" x ( 2 * $num ), $buf );
    #my @advanced_width;
    my @lsb;
    my $loop_index = @temp;

    for ( my $i = 0 ; $i < $loop_index - 1 ; $i++ ) {
        #$advanced_width[@advanced_width] = $temp[$i];
        $lsb[@lsb] = $temp[ $i + 1 ] - ( $temp[ $i + 1 ] > 32768 ? 65536 : 0 );
        $i++;
    }

    my $end_lsb = $number_of_glyphs;
    if ( @lsb < $end_lsb ) {
        my $more_lsb = $end_lsb - scalar(@lsb);
        read( $fh, $buf, 2 * $more_lsb );
        @temp = unpack( "n*", $buf );
        for ( my $i = 0 ; $i < @temp ; $i++ ) {
            $lsb[@lsb] = $temp[$i] - ( $temp[$i] > 32768 ? 65536 : 0 );
        }

    }
    return defined ($lsb[$index])? $lsb[$index] : undef;


}

sub get_advance_width {
    my $self  = shift;
    my $index = shift;                      # glyph index
    my $fh    = $self->get_file_handle();
    my $buf;

    seek( $fh, $self->{table}->{"hhea"}, 0 );
    read( $fh, $buf, 36 ) == 36 || die "reading hhea table";
    my ($h_num) = unpack( "x34n", $buf );
    my $num = $h_num;

    seek( $fh, $self->{table}->{"hmtx"}, 0 );
    read( $fh, $buf, 4 * $num ) == 4 * $num || die "reading hmtx table";
    my (@h_temp) = unpack( "n" x ( 2 * $num ), $buf );

    # print "******@h_temp\n";
    my (@advanced_width);
    #my (@lsb);
    for ( my $i = 0 ; $i < @h_temp - 1 ; $i += 2 ) {
        push ( @advanced_width, $h_temp[$i] );
        #push ( @lsb,            $h_temp[ $i + 1 ] );
    }

    #print @advanced_width, "\n";
    #print @lsb;
    if ($index > $#advanced_width && $self->is_fixed_pitch()) {
	$index = $#advanced_width;
    }
    
    #if ( $index > @lsb ) { $index = @lsb; }
    my $a =
      $advanced_width[$index] - ( $advanced_width[$index] > 32768 ? 65536 : 0 );
    #my $l = $lsb[$index] - ( $lsb[$index] > 32768 ? 65536 : 0 );

    #return $a, $l;
    return $a ? $a : undef;
}

=head2 get_leading()

"Leading" is the gap between two lines. The value is present in the
C<OS/2> table of the font.

 Usage   : $metrics->get_leading();
 Args    : None.
 Returns : A scalar Integer.

=cut

sub get_leading {
    my $self = shift;
    if ( defined( $self->{leading} ) ) {
        return $self->{leading};
    }
    else {
        $self->_parse_os2();

        #$self->{leading} = $self->_get_leading();
        return $self->{leading};
    }
}

sub _get_leading {
    my $self = shift;
    my $fh   = $self->get_file_handle();

    # Get the adress of the OS/2 table
    my $add = $self->get_table_address('OS/2');
    my $buf;

    #print $add, "\n";

    #Leading is sTypoLineGap in OS/2 table
    seek( $fh, $add, 0 );
    read( $fh, $buf, 74 ) == 74 || die "reading OS/2 table";
    my ($leading) = unpack( "x72n", $buf );

    #print join(" ",@panose), "\n";
    #print $leading, "\n";
    return $leading - ( $leading > 32768 ? 65536 : 0 );
}

=head2 get_units_per_em()

Get C<units_per_em> of the font. This value is present in the C<head>
table of the font and for TTF is generally 2048.

 Usage   : $metrics->get_units_per_em();
 Args    : None.
 Returns : A scalar integer.

=cut

sub get_units_per_em {
    my $self = shift;

    # Get Headtable address
    my $add = $self->get_table_address("head");
    my $buf;
    my $fh = $self->get_file_handle();

    seek( $fh, $add, 0 );

    read( $fh, $buf, 54 ) == 54 || die "reading head table";
    my ( $units_per_em, $index_to_loc ) = unpack( "x18nx30n", $buf );

    # print "Unit/EM: $units_per_em\tIndex_to_loc: $index_to_loc\n\n";

    return $units_per_em;
}

=head2 get_ascent()

"Ascent" is the distance between the baseline to the top of the glyph.

 Usage   : $metrics->get_ascent();
 Args    : None.
 Returns : A scalar integer.

=cut

sub get_ascent {
    my $self = shift;
    if ( defined( $self->{ascent} ) ) {
        return $self->{ascent};
    }
    else {
        $self->_parse_os2();

        #$self->{ascent} = $self->_get_ascent();
        return $self->{ascent};
    }
}

sub _get_ascent {
    my $self = shift;
    my $fh   = $self->get_file_handle();

    # Get the adress of the OS/2 table
    my $add = $self->get_table_address('OS/2');
    my $buf;

    #print $add, "\n";

    # Ascent is  is sTypoAscender in OS/2 table
    seek( $fh, $add, 0 );
    read( $fh, $buf, 70 ) == 70 || die "reading OS/2 table";
    my ($ascent) = unpack( "x68n", $buf );

    #print join(" ",@panose), "\n";
    #print $ascent, "\n";
    return $ascent - ( $ascent > 32768 ? 65536 : 0 );
}

=head2 get_descent()

"Descent" is the negative distance from the baseline to the lowest
point of the glyph.

 Usage   : $metrics->get_descent();
 Args    : None.
 Returns : A scalar integer.

=cut

sub get_descent {
    my $self = shift;
    if ( defined( $self->{descent} ) ) {
        return $self->{descent};
    }
    else {
        $self->_parse_os2();

        #$self->{descent} = $self->_get_descent();
        return $self->{descent};
    }
}

sub _parse_os2 {
    my $self = shift;
    my $fh   = $self->get_file_handle();
    my $add  = $self->get_table_address('OS/2');
    my $buf;

    seek( $fh, $add, 0 );
    read( $fh, $buf, 74 ) == 74 || die "reading OS/2 table";

    #my ($ascent, $descent, $leading) =
    #           unpack("x68nnn", $buf);
    my ( $fs, $ascent, $descent, $leading ) = unpack( "x62nx4nnn", $buf );

    #print STDERR dec2bin($fs) ,"\n";
    if ( $fs & 0x20 ) {
        $self->{isbold} = 1;
    }
    else {
        $self->{isbold} = 0;
    }

    if ( $fs & 0x01 ) {
        $self->{isitalic} = 1;
    }
    else {
        $self->{isitalic} = 0;
    }

    if ( $fs & 0x40 ) {
        $self->{isregular} = 1;
    }
    else {
        $self->{isregular} = 0;
    }

    $self->{ascent}  = $ascent -  ( $ascent > 32768  ? 65536 : 0 );
    $self->{descent} = $descent - ( $descent > 32768 ? 65536 : 0 );
    $self->{leading} = $leading - ( $leading > 32768 ? 65536 : 0 );
}

=head2 is_bold()

Returns true if the font is a bold variation of the font. That means
if you call this function of arial.ttf, it returns false. If you call
this function on arialb.ttf it returns true.

 Usage   : $metrics->is_bold()
 Args    : None.
 Returns : True if the font is a bold font, returns false otherwise.

=cut

sub is_bold {
    my $self = shift;
    if ( defined( $self->{isbold} ) ) {
        return $self->{isbold};
    }
    else {
        $self->_parse_os2();
    }
    return $self->{isbold};
}

=head2 is_italic()

Returns true if the font is italic version of the font. Thar means if
you call this function on arialbi.ttf or ariali.ttf it returns true.

 Usage   : $metrics->is_italic()
 Args    : None 
 Returns : True if the font italic, false otherwise

=cut

sub is_italic {
    my $self = shift;
    if ( defined( $self->{isitalic} ) ) {
        return $self->{isitalic};
    }
    else {
        $self->_parse_os2();
    }
    return $self->{isitalic};
}

=head2 get_font_family()

Returns the family name of the font.

 Usage   : $metrics->get_font_family()
 Args    : None
 Returns : A scalar

=cut

sub get_font_family {
    my $self = shift;
    if ( defined( $self->{family} ) ) {
        return $self->{family};
    }
    else {
        $self->_parse_name_table();
    }
    return $self->{family};
}

=head2 get_subfamily()

Reuturns the style variation of the font in text. Note that depending
on this description might actully be pretty confusing. Call
C<is_bold()> and/or C<is_italic()> to detemine the style. For example
a "demi" version of the font is not "bold" by text. But in display
this in actually bold variation. In this case C<is_bold()> will return
true.

 Usage   : $metrics->get_subfamily() 
 Args    : None
 Returns : A scalar.

=cut

sub get_subfamily {
    my $self = shift;
    if ( defined( $self->{subfamily} ) ) {
        return $self->{subfamily};
    }
    else {
        $self->_parse_name_table();
    }
    return $self->{subfamily};
}

sub _parse_name_table {

    my $self = shift;
    my $buf;
    my $fh = $self->get_file_handle();

    my $LANGUAGE_ID;
    my $PLATFORM_ID = $self->{platform};
    my $ENCODING_ID = $self->{encoding};
    if ( $self->{platform} == "1" && $self->{encoding} == "0" ) {
        $LANGUAGE_ID = 0;
    }
    else {
        $LANGUAGE_ID = 1033;
    }
    my $add = $self->get_table_address("name");
    seek( $fh, $add, 0 );
    read( $fh, $buf, 6 );
    my ( $num, $offset ) = unpack( "x2nn", $buf );

    #print "*******NAME : Number of records, $num, Offset: $offset\n";

    my (
        $copyright_offset,  $font_family_name_offset,
        $subfamily_offset,  $id_offset,
        $full_name_offset,  $version_string_offset,
        $postscript_offset, $trademark_offset
    );

    my (
        $copyright_length,  $font_family_length, $subfamily_length,
        $id_length,         $full_name_length,   $version_length,
        $postscript_length, $trademark_length
    );

    for ( my $i = 0 ; $i < $num ; $i++ ) {
        read( $fh, $buf, 12 );
        my ( $id, $encoding, $language, $name_id, $length, $string_offset ) =
          unpack( "n6", $buf );

        #print "****NAMERECORDS: $id, $encoding, $language, $name_id, $length, $string_offset\n";

        if (
            ( $id == $PLATFORM_ID )       &&    # Windows??
            ( $encoding == $ENCODING_ID ) &&    #UGL??
            ( $language == $LANGUAGE_ID )
          )
        {
            if ( $name_id == 0 ) {              #Copyright
                $copyright_offset = $string_offset;
                $copyright_length = $length;
            }
            if ( $name_id == 1 ) {              # Familyname
                $font_family_name_offset = $string_offset;
                $font_family_length      = $length;
            }
            if ( $name_id == 2 ) {              # Subfamily
                $subfamily_offset = $string_offset;
                $subfamily_length = $length;
            }
            if ( $name_id == 3 ) {              # Identifier
                $id_offset = $string_offset;
                $id_length = $length;
            }
            if ( $name_id == 4 ) {              # Full name
                $full_name_offset = $string_offset;
                $full_name_length = $length;
            }
            if ( $name_id == 5 ) {              #version string
                $version_string_offset = $string_offset;
                $version_length        = $length;
            }
            if ( $name_id == 6 ) {              # Postscript name
                $postscript_offset = $string_offset;
                $postscript_length = $length;
            }
            if ( $name_id == 7 ) {              # Trademark
                $trademark_offset = $string_offset;
                $trademark_length = $length;
            }
        }

    }    # End for loop;

    # Print copyright
    seek( $fh, $self->get_table_address("name") + $offset + $copyright_offset,
        0 );
    read( $fh, $buf, $copyright_length );

    # print "COPYRIGHT: $buf\n\n";

    # Print familyname
    seek( $fh,
        $self->get_table_address("name") + $offset + $font_family_name_offset,
        0 );
    read( $fh, $buf, $font_family_length );

    #print $s;
    $self->{family} = $self->_remove_white_space( $buf, $font_family_length );

    #print  "\n****", "@char", "*****\n"; 
    #return "@char";
    # print "FAMILY: $buf\n\n";

    #Print Subfamily
    seek( $fh, $self->get_table_address('name') + $offset + $subfamily_offset,
        0 );
    read( $fh, $buf, $subfamily_length );

    #print "SUBFAMILY: $buf\n\n";
    $self->{subfamily} = $self->_remove_white_space( $buf, $subfamily_length );

    #    #Print Identifier
    #    seek( $fh, $self->get_table_address('name') + $offset + $id_offset, 0 );
    #    read( $fh, $buf, $id_length );

    #    #print "ID: $buf\n\n";

    #    #Print Full name
    #    seek( $fh, $self->get_table_address('name') + $offset + $full_name_offset,
    #        0 );
    #    read( $fh, $buf, $full_name_length );

    #    #print "FULL NAME: $buf\n\n";

    #    #Print Version string
    #    seek( $fh,
    #        $self->get_table_address('name') + $offset + $version_string_offset,
    #        0 );
    #    read( $fh, $buf, $version_length );

    #    #print "VERSION: $buf\n\n";

    #    #Print Postscript
    #    seek( $fh, $self->get_table_address('name') + $offset + $postscript_offset,
    #        0 );
    #    read( $fh, $buf, $postscript_length );

    #    #print "Postscript: $buf\n\n";

    #    #Print Trademark
    #    seek( $fh, $self->get_table_address('name') + $offset + $trademark_offset,
    #        0 );
    #    read( $fh, $buf, $trademark_length );

    #    #print "TRADEMARK: $buf\n\n";

}

sub _remove_white_space {
    my $self               = shift;
    my $buf                = shift;
    my $font_family_length = shift;
    my @char               = unpack( "C*", $buf );
    my $i                  = $font_family_length;
    my $s                  = "";
    my $j                  = 0;
    while ( $j < $i ) {

        if ( defined $char[ $j + 1 ] ) {
            $s .= pack( "C", $char[ $j + 1 ] );
        }
        $j += 2;
    }
    return $s;
}

=head2 is_fixed_pitch()

Returns true for a fixed-pitched font like courier.

 Usage   : $metrics->is_fixed_pitch()
 Args    : None
 Returns : True for a fixed-pitched font, false otherwise

=cut

sub is_fixed_pitch {
    my $self = shift;
    if ( defined $self->{isfixedpitch} ) {
        return $self->{isfixedpitch};
    }
    else {

        return 0;
    }
}

sub make_ps_name_table {
    my $self    = shift;
    my $fh      = $self->get_file_handle();
    my $address = $self->get_table_address("post");
    my $buf;
    seek( $fh, $address, 0 );
    read( $fh, $buf, 4 );
    my $format_type = unpack( "N", $buf );

    #print "Format type:$format_type\n";

    if ( $format_type == 131072 ) {    # Test whether 0x00020000
                                       #print "Microsoft table! \n";
        read( $fh, $buf, 30 );
        my ( $italic_angle_m, $italic_angle_f, $fixed_pitched, $num_glyphs ) =
          unpack( "nnx4Nx16n", $buf );

        #$italic_angle_m  = $italic_angle_m  - ($italic_angle_m > 32768 ? 65536 :0);
        #print STDERR $fixed_pitched, "\n";
        if ($fixed_pitched) {
            $self->{isfixedpitch} = 1;
        }

        #print $num_glyphs, "\n";
        my $highest_glyph_index = 0;

        for ( my $i = 0 ; $i < $num_glyphs ; $i++ ) {
            read( $fh, $buf, 2 );
            $glyph_name_index[$i] = unpack( "n", $buf );
            if ( $highest_glyph_index < $glyph_name_index[$i] ) {
                $highest_glyph_index = $glyph_name_index[$i];
            }
        }

        if ( $highest_glyph_index > 257 ) {
            $highest_glyph_index -= 257;
        }

        for ( my $i = 0 ; $i < $highest_glyph_index ; $i++ ) {
            read( $fh, $buf, 1 );
            my $length = unpack( "C", $buf );
            read( $fh, $buf, $length );
            $post_glyph_name[$i] = pack( "C*", unpack( "C*", $buf ) );

            #print $post_glyph_name[$i], "\n";
        }

    }
    elsif ( $format_type == 131077 ) {

        #Do Nothing
    }
}

sub make_mac_glyph_name {
    @mac_glyph_name = (
        ".notdef", "null", "CR", "space",
        "exclam",            # 4
        "quotedbl",          # 5
        "numbersign",        # 6
        "dollar",            # 7
        "percent",           # 8
        "ampersand",         # 9
        "quotesingle",       # 10
        "parenleft",         # 11
        "parenright",        # 12
        "asterisk",          # 13
        "plus",              # 14
        "comma",             # 15
        "hyphen",            # 16
        "period",            # 17
        "slash",             # 18
        "zero",              # 19
        "one",               # 20
        "two",               # 21
        "three",             # 22
        "four",              # 23
        "five",              # 24
        "six",               # 25
        "seven",             # 26
        "eight",             # 27
        "nine",              # 28
        "colon",             # 29
        "semicolon",         # 30
        "less",              # 31
        "equal",             # 32
        "greater",           # 33
        "question",          # 34
        "at",                # 35
        "A",                 # 36
        "B",                 # 37
        "C",                 # 38
        "D",                 # 39
        "E",                 # 40
        "F",                 # 41
        "G",                 # 42
        "H",                 # 43
        "I",                 # 44
        "J",                 # 45
        "K",                 # 46
        "L",                 # 47
        "M",                 # 48
        "N",                 # 49
        "O",                 # 50
        "P",                 # 51
        "Q",                 # 52
        "R",                 # 53
        "S",                 # 54
        "T",                 # 55
        "U",                 # 56
        "V",                 # 57
        "W",                 # 58
        "X",                 # 59
        "Y",                 # 60
        "Z",                 # 61
        "bracketleft",       # 62
        "backslash",         # 63
        "bracketright",      # 64
        "asciicircum",       # 65
        "underscore",        # 66
        "grave",             # 67
        "a",                 # 68
        "b",                 # 69
        "c",                 # 70
        "d",                 # 71
        "e",                 # 72
        "f",                 # 73
        "g",                 # 74
        "h",                 # 75
        "i",                 # 76
        "j",                 # 77
        "k",                 # 78
        "l",                 # 79
        "m",                 # 80
        "n",                 # 81
        "o",                 # 82
        "p",                 # 83
        "q",                 # 84
        "r",                 # 85
        "s",                 # 86
        "t",                 # 87
        "u",                 # 88
        "v",                 # 89
        "w",                 # 90
        "x",                 # 91
        "y",                 # 92
        "z",                 # 93
        "braceleft",         # 94
        "bar",               # 95
        "braceright",        # 96
        "asciitilde",        # 97
        "Adieresis",         # 98
        "Aring",             # 99
        "Ccedilla",          # 100
        "Eacute",            # 101
        "Ntilde",            # 102
        "Odieresis",         # 103
        "Udieresis",         # 104
        "aacute",            # 105
        "agrave",            # 106
        "acircumflex",       # 107
        "adieresis",         # 108
        "atilde",            # 109
        "aring",             # 110
        "ccedilla",          # 111
        "eacute",            # 112
        "egrave",            # 113
        "ecircumflex",       # 114
        "edieresis",         # 115
        "iacute",            # 116
        "igrave",            # 117
        "icircumflex",       # 118
        "idieresis",         # 119
        "ntilde",            # 120
        "oacute",            # 121
        "ograve",            # 122
        "ocircumflex",       # 123
        "odieresis",         # 124
        "otilde",            # 125
        "uacute",            # 126
        "ugrave",            # 127
        "ucircumflex",       # 128
        "udieresis",         # 129
        "dagger",            # 130
        "degree",            # 131
        "cent",              # 132
        "sterling",          # 133
        "section",           # 134
        "bullet",            # 135
        "paragraph",         # 136
        "germandbls",        # 137
        "registered",        # 138
        "copyright",         # 139
        "trademark",         # 140
        "acute",             # 141
        "dieresis",          # 142
        "notequal",          # 143
        "AE",                # 144
        "Oslash",            # 145
        "infinity",          # 146
        "plusminus",         # 147
        "lessequal",         # 148
        "greaterequal",      # 149
        "yen",               # 150
        "mu",                # 151
        "partialdiff",       # 152
        "summation",         # 153
        "product",           # 154
        "pi",                # 155
        "integral'",         # 156
        "ordfeminine",       # 157
        "ordmasculine",      # 158
        "Omega",             # 159
        "ae",                # 160
        "oslash",            # 161
        "questiondown",      # 162
        "exclamdown",        # 163
        "logicalnot",        # 164
        "radical",           # 165
        "florin",            # 166
        "approxequal",       # 167
        "increment",         # 168
        "guillemotleft",     # 169
        "guillemotright",    #170
        "ellipsis",          # 171
        "nbspace",           # 172
        "Agrave",            # 173
        "Atilde",            # 174
        "Otilde",            # 175
        "OE",                # 176
        "oe",                # 177
        "endash",            # 178
        "emdash",            # 179
        "quotedblleft",      # 180
        "quotedblright",     # 181
        "quoteleft",         # 182
        "quoteright",        # 183
        "divide",            # 184
        "lozenge",           # 185
        "ydieresis",         # 186
        "Ydieresis",         # 187
        "fraction",          # 188
        "currency",          # 189
        "guilsinglleft",     # 190
        "guilsinglright",    #191
        "fi",                # 192
        "fl",                # 193
        "daggerdbl",         # 194
        "middot",            # 195
        "quotesinglbase",    #196
        "quotedblbase",      # 197
        "perthousand",       # 198
        "Acircumflex",       # 199
        "Ecircumflex",       # 200
        "Aacute",            # 201
        "Edieresis",         # 202
        "Egrave",            # 203
        "Iacute",            # 204
        "Icircumflex",       # 205
        "Idieresis",         # 206
        "Igrave",            # 207
        "Oacute",            # 208
        "Ocircumflex",       # 209
        "",                  # 210
        "Ograve",            # 211
        "Uacute",            # 212
        "Ucircumflex",       # 213
        "Ugrave",            # 214
        "dotlessi",          # 215
        "circumflex",        # 216
        "tilde",             # 217
        "overscore",         # 218
        "breve",             # 219
        "dotaccent",         # 220
        "ring",              # 221
        "cedilla",           # 222
        "hungarumlaut",      # 223
        "ogonek",            # 224
        "caron",             # 225
        "Lslash",            # 226
        "lslash",            # 227
        "Scaron",            # 228
        "scaron",            # 229
        "Zcaron",            # 230
        "zcaron",            # 231
        "brokenbar",         # 232
        "Eth",               # 233
        "eth",               # 234
        "Yacute",            # 235
        "yacute",            # 236
        "Thorn",             # 237
        "thorn",             # 238
        "minus",             # 239
        "multiply",          # 240
        "onesuperior",       # 241
        "twosuperior",       # 242
        "threesuperior",     # 243
        "onehalf",           # 244
        "onequarter",        # 245
        "threequarters",     # 246
        "franc",             # 247
        "Gbreve",            # 248
        "gbreve",            # 249
        "Idot",              # 250
        "Scedilla",          # 251
        "scedilla",          # 252
        "Cacute",            # 253
        "cacute",            # 254
        "Ccaron",            # 255
        "ccaron",            # 256
        ""                   # 257
    );
}

sub get_glyph_name {
    my $index = shift;
    if ( $glyph_name_index[$index] > 257 ) {

        #print $post_glyph_name[$glyph_name_index[$index] -258], "******\n";
        return $post_glyph_name[ $glyph_name_index[$index] - 258 ];
    }
    else {

        #print $glyph_name_index[$index], "*****\n";
        #print $mac_glyph_name[$glyph_name_index[$index]], "******\n";
        #print $mac_glyph_name[3], "*****\n";
        return $mac_glyph_name[ $glyph_name_index[$index] ];
    }
}

sub get_panose {
    my $self = shift;
    my $buf;
    my $add = $self->get_table_address('OS/2');
    my $fh  = $self->get_file_handle();
    seek( $fh, $add, 0 );
    read( $fh, $buf, 42 );

    #Throw away first 32 bytes and take last 10

    my (@panose) = unpack( "x32c10", $buf );
    return @panose;
}



sub kern_value{
  my ($self,$left, $right) = @_;
  unless ($self->{kern}) {
      return 0;
  }
  if (exists ($self->{kern}->{$left}->{$right}) ) {
      return $self->{kern}->{$left}->{$right};
  }else {
      return 0;
  }
}


sub process_kern_table {
    my $self = shift;
    my $buf;

    #print STDERR $self->get_font_family(), "\n";
    #my $s = "";
    unless ( defined( $self->get_table_address("kern") ) ) {
        return 0;
    }
    my $add = $self->get_table_address("kern");
    my $fh  = $self->get_file_handle();
    my %kern;

    seek( $fh, $add, 0 );
    read( $fh, $buf, 4 );
    my $num_of_tables = unpack( "x2n", $buf );

    #print $num_of_tables, "\n";

    for ( my $i = 0 ; $i < $num_of_tables ; $i++ ) {
        read( $fh, $buf, 4 );
        my $length = unpack( "x2n", $buf );
        read( $fh, $buf, 2 );
        my $coverage = unpack( "n", $buf );
        my $format = $coverage >> 8;

        #print $format, "\n";

        if ( ( $format == 0 ) && ( ( $coverage & 1 ) != 0 ) ) {

            #print "FORMAT 0\n";
            read( $fh, $buf, 2 );
            my $npairs = unpack( "n", $buf );

            #print $npairs, "\n";
            read( $fh, $buf, 6 );

            for ( my $j = 0 ; $j < $npairs ; $j++ ) {
                read( $fh, $buf, 4 );

                # my $right_and_left = unpack("N", $buf);
                my ( $left, $right ) = unpack( "nn", $buf );
                if ( $left > 255 ) {
                    last;
                }
                read( $fh, $buf, 2 );
                my $kern_data = unpack( "n", $buf );
                $kern_data = $kern_data - ( $kern_data > 32768 ? 65536 : 0 );

                #	$kern_data = $kern_data * ( -1);
                #	if(exists($kern_to_print{$left})){
                #	  $s .= write_kern_data($left, $right, $kern_data);
                #	}
                $kern{$left}->{$right} = $kern_data;

                #print STDERR $left,"\t",$right, "\t", $kern_data,"\n";
                #print get_glyph_name($left), ":", get_glyph_name($right);
                #print "$right_and_left ";

                #	$kern{$right_and_left} = $kern_data;
                #print $kern_data, "\n";

            }
        }
        else {
            read( $fh, $buf, $length - 6 );
        }
    }
    $self->{kern} = \%kern;

    #return $s; 
}

sub DESTROY {
    my $self = shift;
    close $self->{_fh};
}





sub set_file_handle {
    my $self = shift;
    my $path = shift;
    my $fh   = IO::File->new();

    if ( $fh->open("< $path") ) {
        binmode($fh);
        $self->{_fh} = $fh;
    }
    else {
        croak "Could not open $path in Pastel::Font::TTF::set_file_handle\n";
    }

}

sub get_file_handle {
    my $self = shift;
    if ( defined( $self->{_fh} ) ) {
        return $self->{_fh};
    }
    else {
        return 0;
    }
}

sub _rearrange {

    my ( $self, $order, @param ) = @_;

    return unless @param;
    return @param unless ( defined( $param[0] ) && $param[0] =~ /^-/ );

    for ( my $i = 0 ; $i < @param ; $i += 2 ) {
        $param[$i] =~ s/^\-//;
        $param[$i] =~ tr/a-z/A-Z/;
    }

    # Now we'll convert the @params variable into an associative array.
    local ($^W) = 0;    # prevent "odd number of elements" warning with -w.
    my (%param) = @param;

    my (@return_array);

    # What we intend to do is loop through the @{$order} variable,
    # and for each value, we use that as a key into our associative
    # array, pushing the value at that key onto our return array.
    my ($key);

    foreach $key ( @{$order} ) {
        my ($value) = $param{$key};
        delete $param{$key};
        push ( @return_array, $value );
    }

    #    print "\n_rearrange() after processing:\n";
    #    my $i; for ($i=0;$i<@return_array;$i++) { printf "%20s => %s\n", ${$order}[$i], $return_array[$i]; } <STDIN>;

    return (@return_array);
}

sub maxp_get_number_of_glyph {
    my $self = shift;
    my $fh   = $self->get_file_handle();
    my $buf;
    seek( $fh, $self->get_table_address("maxp"), 0 );
    read( $fh, $buf, 6 );
    my ($num_glyph) = unpack( "x4n", $buf );
    return $num_glyph;

}

=head1 SEE ALSO

L<Font::TTF>, L<Pastel::Font::TTF>.

=head1 COPYRIGHTS

Copyright (c) 2003 by Malay <curiouser@ccmb.res.in>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
