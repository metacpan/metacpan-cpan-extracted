#!perl

package MARC::File::MARCMaker;

=head1 NAME

MARC::File::MARCMaker -- Work with MARCMaker/MARCBreaker records.

=cut

use strict;
use integer;

use vars qw( $VERSION $ERROR );

$VERSION = 0.05;

use MARC::File;
use vars qw( @ISA ); @ISA = qw( MARC::File );

use MARC::Record qw( LEADER_LEN );
use constant SUBFIELD_INDICATOR     => "\x24"; #dollar sign
use constant END_OF_FIELD           => "\n\x3D"; #line break, equals sign


=head1 SYNOPSIS


    use MARC::File::MARCMaker;

    my $file = MARC::File::MARCMaker->in( $filename );

    while ( my $marc = $file->next() ) {
        # Do something
    }
    $file->close();
    undef $file;

####################################################

    use MARC::File::MARCMaker;

    ## reading with MARC::Batch
    my $batch = MARC::Batch->new( 'MARCMaker', $filename );
    my $record = $batch->next();

    ## or reading with MARC::File::MARCMaker explicitly
    my $file = MARC::File::MARCMaker->in( $filename );
    my $record = $file->next();

    ## output a single MARC::Record object in MARCMaker format (formatted plain text)
    #print $record->as_marcmaker(); #goal syntax
    print MARC::File::MARCMaker->encode($record); #current syntax

=head1 DESCRIPTION

The MARC-File-MARCMaker distribution is an extension to the MARC-Record
distribution for working with MARC21 data using the format used by the Library
of Congress MARCMaker and MARCBreaker programs.

More information may be obtained here: L<http://www.loc.gov/marc/makrbrkr.html>

You must have MARC::Record installed to use MARC::File::MARCMaker. In fact 
once you install the MARC-File-MARCMaker distribution you will most likely not 
use it directly, but will have an additional file format available to you 
when you use MARC::Batch.

This module is based on code from the original MARC.pm module, as well as the
MARC::Record distribution's MARC::File::USMARC and MARC::File::MicroLIF modules.

=head2 DEVIATIONS FROM LC'S DOCUMENTATION

LC's MARCMaker/MARCBreaker programs require files to have DOS line endings.
This module should be capable of reading any type of line ending.
It converts existing endings to "\n", the endings of the platform.

Initial version may or may not work well with line breaks in the middle of a field.

MARCMaker version of the LDR (record size bytes) will not necessarily be dependable, and should not be relied upon.

=head1 EXPORT

None.

=head1 TODO

Do limit tests in filling the buffer and getting chunks. Seems to work for first fill, but may fail on larger reads/multiple reads to fill the buffer.

Test special characters (those requiring escapes). Initial version may not fully support non-English characters. All MARC-8 may work, Unicode support is untested and unassured.

Implement better character encoding and decoding, including Unicode support.

Work on character set internal subs for both input and output. Currently, the original subs from MARC.pm are being used essentially as-is.

Error checking for line breaks vs. new fields? Probably not possible, since line breaks are allowed within fields, so checking for missing equals sign is not really possible.

Account for multiple occurences of =LDR in a single record, usually caused by lack of blank line between records, so records get mushed together. Also check for multiple =001s.

Determine why the constant SUBFIELD_INDICATOR can't be used in the split into subfields.

Work on encode(). 

Allow as_marcmaker() to be called with either MARC::Field or MARC::Record objects, returning the appropriate result. Desired behavior is as_usmarc() methods in MARC::Record and MARC::Field

Decode should mostly be working. Test for correctness.

Remove unnecessary code and documentation, remnants of the initial development of the module. Move internal subs to end of module?

=head1 VERSION HISTORY

Version 0.05: First CPAN release, Oct. 30, 2005.

Version 0.04: Updated Oct. 22, 2005. Released Oct. 23, 2005.

 -Initial commit to CVS on SourceForge
 -Misc. cleanup.

Version 0.03: Updated Aug. 2, 2005. Released Aug. 14, 2005.

 -Revised decode() to fix problem with dollar sign conversion from mnemonics to characters.

Version 0.02: Updated July 12-13, 2005. Released July 16, 2005.

 -Preliminary version of encode() for fields and records

Version 0.01: Initial version, Nov. 21, 2004-Mar. 7, 2005. Released Mar. 7, 2005.

 -Basic version, translates .mrk format file into MARC::Record objects.

=for internal

 ############################################################
 This section is copied from MARC::File::MicroLIF.
 ############################################################

The buffer must be large enough to handle any valid record because
we don't check for cases like a CR/LF pair or an end-of-record/CR/LF
trio being only partially in the buffer.

The max valid record is the max MARC record size (99999) plus one
or two characters per tag (CR, LF, or CR/LF).  It's hard to say
what the max number of tags is, so here we use 6000.  (6000 tags
can be squeezed into a MARC record only if every tag has only one
subfield containing a maximum of one character, or if data from
multiple tags overlaps in the MARC record body.  We're pretty safe.)

=cut

use constant BUFFER_MIN => (99999 + 6000 * 2);

=head1 METHODS

=cut

##################################
### START OF MARCMAKER METHODS ###
##################################

=head2 _next (merged from MicroLIF and USMARC)

Called by MARC::File::next().

=cut

sub _next { #done for MARCMaker?

    my $self = shift;

    #_get_chunk will separate records from each other and should convert
    # line endings to those of the platform.
    my $makerrec = $self->_get_chunk();
    # for ease, make sure the newlines match this platform
    $makerrec =~ s/[\x0d\x0a]+/\n/g if defined $makerrec;

    return $makerrec;
} #_next

=head2 decode( $string [, \&filter_func ] )

(description based on MARC::File::USMARC::decode POD information)

Constructor for handling data from a MARCMaker file.  This function takes care
of all the tag directory parsing & mangling.

Any warnings or coercions can be checked in the C<warnings()> function.

The C<$filter_func> is an optional reference to a user-supplied function
that determines on a tag-by-tag basis if you want the tag passed to it
to be put into the MARC record.  The function is passed the tag number
and the raw tag data, and must return a boolean.  The return of a true
value tells MARC::File::MARCMaker::decode that the tag should get put into
the resulting MARC record.

For example, if you only want title and subject tags in your MARC record,
try this:

    sub filter {
        my ($tagno,$tagdata) = @_;

        return ($tagno == 245) || ($tagno >= 600 && $tagno <= 699);
    }

    my $marc = MARC::File::MARCMaker->decode( $string, \&filter );

Why would you want to do such a thing?  The big reason is that creating
fields is processor-intensive, and if your program is doing read-only
data analysis and needs to be as fast as possible, you can save time by
not creating fields that you'll be ignoring anyway.

Another possible use is if you're only interested in printing certain
tags from the record, then you can filter them when you read from disc
and not have to delete unwanted tags yourself.

=cut


sub decode { #MARCMaker

    my $text;
    my $location = '';

    ## decode can be called in a variety of ways
    ## $object->decode( $string )
    ## MARC::File::MARCMaker->decode( $string )
    ## MARC::File::MARCMaker::decode( $string )
    ## this bit of code covers all three

    my $self = shift;
    if ( ref($self) =~ /^MARC::File/ ) {
        $location = 'in record '.$self->{recnum};
        $text = shift;
    } else {
        $location = 'in record 1';
        $text = $self=~/MARC::File/ ? shift : $self;
    }

    my $filter_func = shift;

    # for ease, make the newlines match this platform
    # this has probably already been taken care of at least once, but just in case
    $text =~ s/[\x0d\x0a]+/\n/g if defined $text;

    my $marc = MARC::Record->new();

    #report improperly passed $text (undefined $text)
    return $marc->_warn( "Unable to retrieve a record string $location" ) unless defined $text;

#############################
#### Charset work needed ####
#############################
    #use default charset until that function is revised
    my $charset = usmarc_default();
#############################
#############################


    #Split each record on the "\n=" into the @lines array
    my @lines=split END_OF_FIELD, $text;
    my $leader = shift @lines;
    unless ($leader =~ /^=LDR  /) {
        $marc->_warn( "First line must begin with =LDR" );
    }
    
    $leader=~s/^=LDR  //;    #Remove "=LDR  "
    $leader=~s/[\n\r]//g; #remove line endings
    $leader=~s/\\/ /g;    # substitute " " for \
    #report error if result is not 24 bytes long
    unless (length($leader) == LEADER_LEN) {
        $marc->_warn( "Leader must be exactly 24 bytes long" );
    }

    #add leader to the record
    $marc->leader( substr( $leader, 0, LEADER_LEN ) );

LINE: foreach my $line (@lines) {
        #Remove newlines from $line ; and also substitute " " for \
        $line=~s/[\n\r]//g;
        $line=~s/\\/ /g;
        #get the tag name
        my $tagno = substr($line,0,3);
        # Check tag validity
        ( $tagno =~ /^[0-9A-Za-z]{3}$/ ) or $marc->_warn( "Invalid tag in $location: \"$tagno\"" );

        if ( ($tagno =~ /^\d+$/ ) && ( $tagno < 10 ) ) {
            #translate characters for tag data
            #revise line below as needed for _maker2char
            my $tagdata = _maker2char ( substr( $line, 5 ), $charset );
            #filter_func implementation needs work
            if ( $filter_func ) {
                next LINE unless $filter_func->( $tagno, $tagdata );
            }
            #add field to record
            $marc->append_fields( MARC::Field->new( $tagno, $tagdata ) );
        } #if $tagno < 10
        else {
            #translate characters for subfield data
            #get indicators
            my $ind1 = substr( $line, 5, 1 );
            my $ind2 = substr( $line, 6, 1 );
            my $tagdata = substr( $line, 7 );
            #report error if first character of tagdata is not a subfield indicator ($)
                $marc->_warn( "First character of subfield data must be a subfield indicator (dollar sign), $tagdata, $location for tag $tagno" ) unless ($tagdata =~ /^\$/ );
            if ( $filter_func ) {
                next LINE unless $filter_func->( $tagno, $tagdata );
            }

            #why doesn't SUBFIELD_INDICATOR work in the split?
            my @subfields_mnemonic = split( /\x24/, $tagdata );
            #convert characters from mnemonics to characters
            my @subfields = map {_maker2char($_, $charset)} @subfields_mnemonic;
            
            #is there a better way to deal with the empty first item?
            my $empty = shift @subfields;
            $marc->_warn( "Subfield data appears before first subfield? $location in $tagno" ) if $empty;

            # Split the subfield data into subfield name and data pairs
            my @subfield_data;
            for ( @subfields ) {
                if ( length > 0 ) {
                    push( @subfield_data, substr($_,0,1),substr($_,1) );
                } else {
                    $marc->_warn( "Entirely empty subfield found in tag $tagno" );
                } 
            } #for @subfields

            if ( !@subfield_data ) {
                $marc->_warn( "no subfield data found $location for tag $tagno" );
                next;
            }

            my $field = MARC::Field->new($tagno, $ind1, $ind2, @subfield_data );
            if ( $field->warnings() ) {
                $marc->_warn( $field->warnings() );
            }
            $marc->append_fields( $field );
        }
    } # looping through all the fields


    return $marc;

} #decode MARCMaker

=head2 update_leader() #from USMARC

This may be unnecessary code. Delete this section if that is the case.

If any changes get made to the MARC record, the first 5 bytes of the
leader (the length) will be invalid.  This function updates the
leader with the correct length of the record as it would be if
written out to a file.


sub update_leader() { #from USMARC
        my $self = shift;

        my (undef,undef,$reclen,$baseaddress) = $self->_build_tag_directory();

        $self->_set_leader_lengths( $reclen, $baseaddress );
} #updated_leader() from USMARC

=head2 encode() #based on MARC::File::USMARC

Returns a string of characters suitable for writing out to a MARCMaker file,
including the leader, directory and all the fields.

Uses as_marcmaker() below to build each field.

=cut

sub encode { #MARCMaker, based on USMARC's encode()
    my $marc = shift;
    $marc = shift if (ref($marc)||$marc) =~ /^MARC::File/;
    my $field_string = '';
    #convert each field (after the leader) to MARCMaker format
    foreach my $field ($marc->fields()) {
        $field_string .= $field->MARC::File::MARCMaker::as_marcmaker();
    } #foreach field in record
    
    # Glomp it all together
    return join("", "=LDR  ", $marc->leader, "\n", $field_string, "\n");

} #encode from USMARC


=head2 as_marcmaker()

Based on MARC::Field::as_usmarc().
Turns a MARC::Field into a MARCMaker formatted field string.

=head2 TODO (as_marcmaker())

 -Change field encoding portion of as_marcmaker() to internal _as_marcmaker()
 -Implement as_marcmaker() as wrapper for MARC::Record object and MARC::Field object encoding into MARCMaker format.


=cut

sub as_marcmaker() {
    my $self = shift;
#    $self = shift if (ref($self)||$self) =~ /^MARC::File/;

    die "Wanted a MARC::Field but got a ", ref($self) unless ref($self) eq "MARC::Field";

    my $charset = ustext_default();

    # Tags < 010 are pretty easy
    if ( $self->is_control_field ) {
        #convert characters to MARCMaker codes
        my $field_data = (_char2maker($self->data(), $charset));
        #swap blank spaces for backslash ( \ )
        $field_data =~ s/ /\\/g;
        #return formatted field
        return sprintf "=%s  %s\n", $self->tag(), $field_data;
    } #if control field
    elsif ($self->tag() eq '000') {print "Leader?\n"} #leader?
    else {
        my @subs;
        my @subdata = @{$self->{_subfields}};
        while ( @subdata ) {
            #convert characters to MARCMaker codes as each subfield goes by
            push( @subs, join( "", SUBFIELD_INDICATOR, shift @subdata, (_char2maker(shift @subdata, $charset))) );
        } # while

        my $ind1 = $self->indicator(1);
        my $ind2 = $self->indicator(2);
        #swap blank for backslash ( \ )
        $ind1 =~ s/ /\\/g;
        $ind2 =~ s/ /\\/g;

        return
        join ("", "=", $self->tag(), "  ",
            $ind1,
            $ind2,
            @subs,
            "\n",
                );
    }
} #as_usmarc() #MARC::Field


####################################
###### END USMARC subs #############
####################################




#########################################
### begin internal subs from MicroLIF ###
#########################################

#################################
# fill the buffer if we need to #
#################################

sub _fill_buffer { #done for MARCMaker?

    my $self = shift;
    my $ok = 1;

    if ( !$self->{exhaustedfh} && length( $self->{inputbuf} ) < BUFFER_MIN ) {
        # append the next chunk of bytes to the buffer
        my $read = read $self->{fh}, $self->{inputbuf}, BUFFER_MIN, length($self->{inputbuf});
        #convert line endings within the input buffer
        if ($self->{inputbuf} =~ /\x0d\x0a/s) {
            $self->{inputbuf} =~ s/\x0d\x0a/\n/sg;
        } #if DOS endings
        elsif ($self->{inputbuf} =~ /\x0a/) {
            $self->{inputbuf} =~ s/\x0a/\n/sg;
        } #elsif Unix endings
        elsif ($self->{inputbuf} =~ /\x0d/) {
            $self->{inputbuf} =~ s/\x0d/\n/sg;
        } #elsif Macintosh endings

        #remove extra blank lines between records
        $self->{inputbuf} =~ s/\n\s*\n+/\n\n/g;

        if ( !defined $read ) {
            # error!
            $ok = undef;
            $MARC::File::ERROR = "error reading from file " . $self->{filename};
        }
        elsif ( $read < 1 ) {
            $self->{exhaustedfh} = 1;
        }
    }

    return $ok;
}

=for internal

=head2 _get_chunk( ) #for MARCMaker

Gets the next chunk of data (which should be a single complete record).

All extra \r and \n are stripped and line endings are converted to those of the platform (\n).

=cut

sub _get_chunk { #done for MARCMaker?

    my $self = shift;

    my $chunk = undef;
    
    #read from the file and fill the input buffer
    if ( $self->_fill_buffer() && length($self->{inputbuf}) > 0 ) {

        #retrieve the next record
        ($chunk) = split /\n\n/, $self->{inputbuf}, 0;
        #remove the chunk and record separator from the input buffer
        $self->{inputbuf} = substr( $self->{inputbuf}, length($chunk)+length("\n\n") );
        if ( !$chunk ) {
            $chunk = $self->{inputbuf};
            $self->{inputbuf} = '';
            $self->{exhaustedfh} = 1;
        } #if not chunk

    } #if buffer can be filled and has characters
    return $chunk;
} #_get_chunk()

=head2 _unget_chunk ( ) #done for MARCMaker?

 $chunk is put at the beginning of the buffer followed 
 by two line endings ("\n\n") as a record separator.

I don't know that this sub is necessary.

=cut

sub _unget_chunk {
    my $self = shift;
    my $chunk = shift;
    $self->{inputbuf} = $chunk . $self->{inputbuf};
    return;
}


#######################################
### End internal subs from MicroLIF ###
#######################################

#######################################
### Character handling from MARC.pm ###
#######################################

=head2 _char2maker

Pass in string of characters from a MARC record and a character map ($charset, or usmarc_default() by default).
Returns string of characters encoded in MARCMaker format.
(e.g. replaces '$' with {dollar})

=cut

sub _char2maker { #deal with charmap default
    my @marc_string = split (//, shift);
    my $charmap = shift; #|| $charset; #add default value
    my $maker_string = join ('', map {${$charmap}{$_} } @marc_string);
    #replace html-style entities (&acute;) with code in curly braces ({acute})
    while ($maker_string =~ s/(&)([^ ]{1,7}?)(;)/{$2}/o) {}

    return $maker_string;
} #_char2maker

######################


=head2 Default charset

usmarc_default() -- Originally from MARC.pm. Offers default mnemonics for character encoding and decoding.

Used by _maker2char.

This perhaps should be an internal _usmarc_default().

=cut

sub usmarc_default { # rec
    my @hexchar = (0x00..0x1a,0x1c,0x7f..0x8c,0x8f..0xa0,0xaf,0xbb,
           0xbe,0xbf,0xc7..0xdf,0xfc,0xfd,0xff);
    my %inchar = map {sprintf ("%2.2X",int $_), chr($_)} @hexchar;

    $inchar{esc} = chr(0x1b);        # escape
    $inchar{dollar} = chr(0x24);    # dollar sign
    $inchar{curren} = chr(0x24);    # dollar sign - alternate
    $inchar{24} = chr(0x24);        # dollar sign - alternate
    $inchar{bsol} = chr(0x5c);        # back slash (reverse solidus)
    $inchar{lcub} = chr(0x7b);        # opening curly brace
    $inchar{rcub} = "&rcub;";        # closing curly brace - part 1
    $inchar{joiner} = chr(0x8d);    # zero width joiner
    $inchar{nonjoin} = chr(0x8e);    # zero width non-joiner
    $inchar{Lstrok} = chr(0xa1);    # latin capital letter l with stroke
    $inchar{Ostrok} = chr(0xa2);    # latin capital letter o with stroke
    $inchar{Dstrok} = chr(0xa3);    # latin capital letter d with stroke
    $inchar{THORN} = chr(0xa4);        # latin capital letter thorn (icelandic)
    $inchar{AElig} = chr(0xa5);        # latin capital letter AE
    $inchar{OElig} = chr(0xa6);        # latin capital letter OE
    $inchar{softsign} = chr(0xa7);    # modifier letter soft sign
    $inchar{middot} = chr(0xa8);    # middle dot
    $inchar{flat} = chr(0xa9);        # musical flat sign
    $inchar{reg} = chr(0xaa);        # registered sign
    $inchar{plusmn} = chr(0xab);    # plus-minus sign
    $inchar{Ohorn} = chr(0xac);        # latin capital letter o with horn
    $inchar{Uhorn} = chr(0xad);        # latin capital letter u with horn
    $inchar{mlrhring} = chr(0xae);    # modifier letter right half ring (alif)
    $inchar{mllhring} = chr(0xb0);    # modifier letter left half ring (ayn)
    $inchar{lstrok} = chr(0xb1);    # latin small letter l with stroke
    $inchar{ostrok} = chr(0xb2);    # latin small letter o with stroke
    $inchar{dstrok} = chr(0xb3);    # latin small letter d with stroke
    $inchar{thorn} = chr(0xb4);        # latin small letter thorn (icelandic)
    $inchar{aelig} = chr(0xb5);        # latin small letter ae
    $inchar{oelig} = chr(0xb6);        # latin small letter oe
    $inchar{hardsign} = chr(0xb7);    # modifier letter hard sign
    $inchar{inodot} = chr(0xb8);    # latin small letter dotless i
    $inchar{pound} = chr(0xb9);        # pound sign
    $inchar{eth} = chr(0xba);        # latin small letter eth
    $inchar{ohorn} = chr(0xbc);        # latin small letter o with horn
    $inchar{uhorn} = chr(0xbd);        # latin small letter u with horn
    $inchar{deg} = chr(0xc0);        # degree sign
    $inchar{scriptl} = chr(0xc1);    # latin small letter script l
    $inchar{phono} = chr(0xc2);        # sound recording copyright
    $inchar{copy} = chr(0xc3);        # copyright sign
    $inchar{sharp} = chr(0xc4);        # sharp
    $inchar{iquest} = chr(0xc5);    # inverted question mark
    $inchar{iexcl} = chr(0xc6);        # inverted exclamation mark
    $inchar{hooka} = chr(0xe0);        # combining hook above
    $inchar{grave} = chr(0xe1);        # combining grave
    $inchar{acute} = chr(0xe2);        # combining acute
    $inchar{circ} = chr(0xe3);        # combining circumflex
    $inchar{tilde} = chr(0xe4);        # combining tilde
    $inchar{macr} = chr(0xe5);        # combining macron
    $inchar{breve} = chr(0xe6);        # combining breve
    $inchar{dot} = chr(0xe7);        # combining dot above
    $inchar{diaer} = chr(0xe8);        # combining diaeresis
    $inchar{uml} = chr(0xe8);        # combining umlaut
    $inchar{caron} = chr(0xe9);        # combining hacek
    $inchar{ring} = chr(0xea);        # combining ring above
    $inchar{llig} = chr(0xeb);        # combining ligature left half
    $inchar{rlig} = chr(0xec);        # combining ligature right half
    $inchar{rcommaa} = chr(0xed);    # combining comma above right
    $inchar{dblac} = chr(0xee);        # combining double acute
    $inchar{candra} = chr(0xef);    # combining candrabindu
    $inchar{cedil} = chr(0xf0);        # combining cedilla
    $inchar{ogon} = chr(0xf1);        # combining ogonek
    $inchar{dotb} = chr(0xf2);        # combining dot below
    $inchar{dbldotb} = chr(0xf3);    # combining double dot below
    $inchar{ringb} = chr(0xf4);        # combining ring below
    $inchar{dblunder} = chr(0xf5);    # combining double underscore
    $inchar{under} = chr(0xf6);        # combining underscore
    $inchar{commab} = chr(0xf7);    # combining comma below
    $inchar{rcedil} = chr(0xf8);    # combining right cedilla
    $inchar{breveb} = chr(0xf9);    # combining breve below
    $inchar{ldbltil} = chr(0xfa);    # combining double tilde left half
    $inchar{rdbltil} = chr(0xfb);    # combining double tilde right half
    $inchar{commaa} = chr(0xfe);    # combining comma above
    if ($MARC::DEBUG) {
        foreach my $str (sort keys %inchar) {
            printf "%s = %x\n", $str, ord($inchar{$str});
        }
    }
    return \%inchar;
} #usmarc_default

###################################################

=head2 ustext_default

ustext_default -- Originally from MARC.pm. Offers default mnemonics for character encoding and decoding.

Used by _char2maker.

This perhaps should be an internal _ustext_default().

=cut

sub ustext_default {
    my @hexchar = (0x00..0x1a,0x1c,0x7f..0x8c,0x8f..0xa0,0xaf,0xbb,
           0xbe,0xbf,0xc7..0xdf,0xfc,0xfd,0xff);
    my %outchar = map {chr($_), sprintf ("{%2.2X}",int $_)} @hexchar;

    my @ascchar = map {chr($_)} (0x20..0x23,0x25..0x7a,0x7c,0x7e);
    foreach my $asc (@ascchar) { $outchar{$asc} = $asc;}

    $outchar{chr(0x1b)} = '{esc}';    # escape
    $outchar{chr(0x24)} = '{dollar}';    # dollar sign
    $outchar{chr(0x5c)} = '{bsol}';    # back slash (reverse solidus)
    $outchar{chr(0x7b)} = '{lcub}';    # opening curly brace
    $outchar{chr(0x7d)} = '{rcub}';    # closing curly brace
    $outchar{chr(0x8d)} = '{joiner}';    # zero width joiner
    $outchar{chr(0x8e)} = '{nonjoin}';    # zero width non-joiner
    $outchar{chr(0xa1)} = '{Lstrok}';    # latin capital letter l with stroke
    $outchar{chr(0xa2)} = '{Ostrok}';    # latin capital letter o with stroke
    $outchar{chr(0xa3)} = '{Dstrok}';    # latin capital letter d with stroke
    $outchar{chr(0xa4)} = '{THORN}';    # latin capital letter thorn (icelandic)
    $outchar{chr(0xa5)} = '{AElig}';    # latin capital letter AE
    $outchar{chr(0xa6)} = '{OElig}';    # latin capital letter OE
    $outchar{chr(0xa7)} = '{softsign}';    # modifier letter soft sign
    $outchar{chr(0xa8)} = '{middot}';    # middle dot
    $outchar{chr(0xa9)} = '{flat}';    # musical flat sign
    $outchar{chr(0xaa)} = '{reg}';    # registered sign
    $outchar{chr(0xab)} = '{plusmn}';    # plus-minus sign
    $outchar{chr(0xac)} = '{Ohorn}';    # latin capital letter o with horn
    $outchar{chr(0xad)} = '{Uhorn}';    # latin capital letter u with horn
    $outchar{chr(0xae)} = '{mlrhring}';    # modifier letter right half ring (alif)
    $outchar{chr(0xb0)} = '{mllhring}';    # modifier letter left half ring (ayn)
    $outchar{chr(0xb1)} = '{lstrok}';    # latin small letter l with stroke
    $outchar{chr(0xb2)} = '{ostrok}';    # latin small letter o with stroke
    $outchar{chr(0xb3)} = '{dstrok}';    # latin small letter d with stroke
    $outchar{chr(0xb4)} = '{thorn}';    # latin small letter thorn (icelandic)
    $outchar{chr(0xb5)} = '{aelig}';    # latin small letter ae
    $outchar{chr(0xb6)} = '{oelig}';    # latin small letter oe
    $outchar{chr(0xb7)} = '{hardsign}';    # modifier letter hard sign
    $outchar{chr(0xb8)} = '{inodot}';    # latin small letter dotless i
    $outchar{chr(0xb9)} = '{pound}';    # pound sign
    $outchar{chr(0xba)} = '{eth}';    # latin small letter eth
    $outchar{chr(0xbc)} = '{ohorn}';    # latin small letter o with horn
    $outchar{chr(0xbd)} = '{uhorn}';    # latin small letter u with horn
    $outchar{chr(0xc0)} = '{deg}';    # degree sign
    $outchar{chr(0xc1)} = '{scriptl}';    # latin small letter script l
    $outchar{chr(0xc2)} = '{phono}';    # sound recording copyright
    $outchar{chr(0xc3)} = '{copy}';    # copyright sign
    $outchar{chr(0xc4)} = '{sharp}';    # sharp
    $outchar{chr(0xc5)} = '{iquest}';    # inverted question mark
    $outchar{chr(0xc6)} = '{iexcl}';    # inverted exclamation mark
    $outchar{chr(0xe0)} = '{hooka}';    # combining hook above
    $outchar{chr(0xe1)} = '{grave}';    # combining grave
    $outchar{chr(0xe2)} = '{acute}';    # combining acute
    $outchar{chr(0xe3)} = '{circ}';    # combining circumflex
    $outchar{chr(0xe4)} = '{tilde}';    # combining tilde
    $outchar{chr(0xe5)} = '{macr}';    # combining macron
    $outchar{chr(0xe6)} = '{breve}';    # combining breve
    $outchar{chr(0xe7)} = '{dot}';    # combining dot above
    $outchar{chr(0xe8)} = '{uml}';    # combining diaeresis (umlaut)
    $outchar{chr(0xe9)} = '{caron}';    # combining hacek
    $outchar{chr(0xea)} = '{ring}';    # combining ring above
    $outchar{chr(0xeb)} = '{llig}';    # combining ligature left half
    $outchar{chr(0xec)} = '{rlig}';    # combining ligature right half
    $outchar{chr(0xed)} = '{rcommaa}';    # combining comma above right
    $outchar{chr(0xee)} = '{dblac}';    # combining double acute
    $outchar{chr(0xef)} = '{candra}';    # combining candrabindu
    $outchar{chr(0xf0)} = '{cedil}';    # combining cedilla
    $outchar{chr(0xf1)} = '{ogon}';    # combining ogonek
    $outchar{chr(0xf2)} = '{dotb}';    # combining dot below
    $outchar{chr(0xf3)} = '{dbldotb}';    # combining double dot below
    $outchar{chr(0xf4)} = '{ringb}';    # combining ring below
    $outchar{chr(0xf5)} = '{dblunder}';    # combining double underscore
    $outchar{chr(0xf6)} = '{under}';    # combining underscore
    $outchar{chr(0xf7)} = '{commab}';    # combining comma below
    $outchar{chr(0xf8)} = '{rcedil}';    # combining right cedilla
    $outchar{chr(0xf9)} = '{breveb}';    # combining breve below
    $outchar{chr(0xfa)} = '{ldbltil}';    # combining double tilde left half
    $outchar{chr(0xfb)} = '{rdbltil}';    # combining double tilde right half
    $outchar{chr(0xfe)} = '{commaa}';    # combining comma above
    if ($MARC::DEBUG) {
        foreach my $num (sort keys %outchar) {
            printf "%x = %s\n", ord($num), $outchar{$num};
        }
    }
    return \%outchar;
} #ustext_default


#################################################################### 

=head2 _maker2char default

_maker2char() -- Translates MARCMaker encoded character into MARC-8 character.

=cut

sub _maker2char { # rec
    my $marc_string = shift;
    my $charmap = shift;
    while ($marc_string =~ /{(\w{1,8}?)}/o) {
    if (exists ${$charmap}{$1}) {
        $marc_string = join ('', $`, ${$charmap}{$1}, $');
    }
    else {
        $marc_string = join ('', $`, '&', $1, ';', $');
    }
    }
       # closing curly brace - part 2, permits {lcub}text{rcub} in input
    $marc_string =~ s/\&rcub;/\x7d/go;
    return $marc_string;
}

################################
### END OF MARCMAKER METHODS ###
################################

1;

=head1 RELATED MODULES

L<MARC::Record>

L<MARC.pm>

=head1 SEE ALSO

L<MARC::File>

L<http://www.loc.gov/marc/makrbrkr.html> for more information about the
DOS-based MARCMaker and MARCBreaker programs.


The methods in this MARCMaker module are based upon MARC::File::USMARC.pm and MARC::File::MicroLIF.pm.
Those are distributed with MARC::Record.
The underlying code is based on the MARCMaker-related methods in MARC.pm.


=head1 LICENSE

This code may be distributed under the same terms as Perl itself. 

Please note that this module is not a product of or supported by the 
employers of the various contributors to the code.

=head1 AUTHOR

Bryan Baldus
eijabb@cpan.org

Copyright (c) 2004-2005.

=cut
