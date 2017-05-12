package XeroxMetacode;
use strict;
use vars qw(@ISA @EXPORT_OK $VERSION);
require Exporter;
@ISA = ('Exporter');
@EXPORT_OK = ('translate_file', 'translate_record');
$VERSION = '0.01';

sub translate_file {
    # read each record from the input metacode file and append each to the
    # parsed text output
    my $parse = '';
    my $sourceMetacode = ${$_[0]};
    
    my $sourceMetacodeLen = length $sourceMetacode;
    my $sourceMetacodePos = 0;
    my $recordLen = 0;
    my $record;
    my @fonts = ();
    
    # Loop until the entire file has been traversed. This reads a series of
    # records from the binary file and passes each off to be individually
    # parsed. State is maintained between records in the @fonts array. While
    # proper metacode processing probably requires more state I just don't
    # know about that yet. Each record consists of a two byte record length
    # and then the binary record.
    
    while ($sourceMetacodePos < $sourceMetacodeLen) {
        $recordLen = unpack
            'n',
            substr
                $sourceMetacode,
                $sourceMetacodePos,
                2;

        $record = substr
            $sourceMetacode,
            $sourceMetacodePos + 2,
            $recordLen - 2;

        $parse .= ${ translate_record( \ $record,
                                         $sourceMetacodePos,
                                       \ @fonts ) };
    
        $sourceMetacodePos += $recordLen;
    }

    
    return \ $parse;
  }

sub translate_record {
    # this returns an array ref to a parse of the input metacode data. Each
    # element of the array is either a text node or another array ref. The
    # plain text nodes are just that. It's the text embedded in the metacode.
    # The array ref nodes have further meaning. The first element of the
    # array indicates which code was encountered. there may be other elements
    # following and you may want to do something with that depending on your
    # skill and knowledge level.
    my $parse = '';
    
    my $record = ${$_[0]};
    my $foffset = $_[1];
    my $fonts = $_[2];
    my $font = 0;
    my @image = ();
    
    while (not $record =~ m/\G\z/cog) {
        # Font switch - the second byte is a packed char
        if ($record =~ m/\G\000([\000-\377])/cog) {
            $font = unpack 'C', $1;
            $parse .= "FontSwitch $font "
                   .  ( $fonts->[$font]
                        ? $fonts->[$font]
                        : '?')
                   . "\n";
            next;
        }

        # record terminator
        if ($record =~ m/\G\001/cog) {
            $parse .= "EndOfLine\n";
            next;
        }

        if ($record =~ m/\G([\002-\003])/cog) {
            $parse .= "Orientation " . unpack('C', $1) . "\n";
            next;
        }

        if ($record =~ m/\G([\004-\007])([\000-\377][\000-\377])/cog ) {
            $parse .= "Positional "
                   .  join( ' ', unpack('C', $1),
                                 unpack('s', $2) )
                   . "\n";
            next;
        }

        if ($record =~ m/\G\010([\000-\377][\000-\377])([\000-\377])/cog ) {
            $parse .= "Drawing " . unpack('s',$1) . " $2\n";
            next;
        }

        if ($record =~ m/\G([\011-\037])/cog ) {
            $parse .= unpack('C',$1) . "\n";
            next;
        }

        # Plain text here. This is all mutually exclusive with the other
        # codes so there is no chance of a match coinciding with another code
        if ($record =~ m/\G([\040-\377]+)/cog ) {
            if ($font) {
                # print this
                $parse .= "Text $1\n";
                next;
            }

            # I assume IDEN was set to $DJDE$ - your mileage may vary
            my $text = $1;
            next unless $text =~ s/^.\$DJDE\$\s*//;

            while (not $text =~ m/\G\z/) {
                $text =~ m/\G\s+/gc and next;
                $text =~ m/\G,/gc and next;
                $text =~ m/\G;/gc and next;

                # FONTS start
                if ($text =~ m/\GFONTS/gc) {
                    @$fonts = ();
    
                    # skip ahead to the first token;
                    if ($text =~ m/\G\s*=\s*\(/gc) {
                        # loop until the ending parenthesis is found
                        while (not $text =~ m/\G\)/gc) {
                            # grab a token
                            push @$fonts, $1 if $text =~ m/\G([^),]+)/gc;
                            # optional comma and white space
                            $text =~ m/\G,?\s*/gc;
                        }

                        $parse .= "DJDE FONTS " . join(' ',@$fonts) . "\n";
                    }
                    next;
                }
                # FONTS end

                # IMAGE start
                if ($text =~ m/\GIMAGE/gc) {
                    @image = ();

                    # skip ahead to the first token
                    if ($text =~ m/\G\s*=\s*\(/gc) {
                        # loop until the ending parenthesis is found
                        while (not $text =~ m/\G\)/gc) {
                            # grab a token
                            push @image, $1 if $text =~ m/\G([^),]+)/gc;
                            # optional comma and white space
                            $text =~ m/\G,?\s*/gc;
                        }

                        $parse .= "DJDE IMAGE " . join(' ', @image) . "\n";
                    }
                    next;
                }
                # IMAGE end

                if ($text =~ m/\GEND/gc) {
                    $parse .= "DJDE END";
                    next;
                }

                $text =~ m/\G./gc and next;
            }

            next;
        }
        # End text record

        # Danger, danger Will Robinson!
        # This really shouldn't ever get here and if it does then it's likely
        # to be a script error. It's also possible that the source Metacode
        # wasn't well formed and somehow the script was led astray
        $record =~ m/\G([\000-\377])/cog;
        $parse .= sprintf q[ERROR Unexpected byte 0x%x at offset 0x%x. Reco]
                        . q[rd starts at 0x%x and is 0x%x bytes long.],
                      unpack('C',$1),
                       $foffset + pos $record,
                       $foffset,
                       length $record;
        next;
    }
    
    $parse .= "\n";
    return \ $parse;
}

1;

__DATA__

=head1 NAME

Metacode::Reader - parse Xerox Metacode data

=head1 SYNOPSIS

 use Metacode::Reader 'translate_file';

 open METACODE, 'source.met' or die "Can't open source.met: $!";
 $metacode = do { local $/ = undef; <METACODE> };
 $parse = translate_file( \$metacode );
 print $$parse;

=head1 ABSTRACT

Perl module for translating Xerox's binary data format printer file format
into a human readable format.

=head1 EXPORT

None by default.

=head1 DESCRIPTION

The Xerox Metacode format is fed directly to Xerox Enterprise Printing
Systems (EPS) for large volumn print jobs. The format is unpublished and this
module only handles part of the decoding task. You will have to continue the
reverse engineering effort if you want to get positional or drawing
characters to appear.

The output from this function should be further massaged into whatever format
is convenient for you.

=head1 PUBLIC METHODS

=over 4

=item $ref = translate_file( \$binary_file )

Pass in a scalar reference to the entire Metacode binary file and you'll be 
given a scalar reference to the parsed output.

=item $ref = translate_record( \$record, $sourceFilePosition, \@fonts )

Pass in a scalar reference to the binary Metacode record, the current offset
into the Metacode file and a fonts array. The file position is used for error
reporting in case any problems show up. The fonts array is used for when DJDE
records set the current operational fonts so further translate_record() calls
can use the font names.

=back

=head1 PARSED OUTPUT FORMAT

The output consists of a single string. Internally each metacode command is
ended by a single newline. Each record is also further ended by another
newline. I used this non-traditional format to avoid costs associated with
array allocation. The most natural format for this would have been to return
a single array for the entire file where each element is an array ref for
each metacode record. So... It's a comprimise. The newline character itself
is not valid text so there is no concern about embedded newlines altering the
parse.

 FontSwitch 0 ?
 DJDE FONTS UN104B HE18BP HE06NP HE08OP
 EndOfLine

 FontSwitch 0 UN104B
 Positional 6 1223
 Positional 4 3461
 FontSwitch 10 BLANKP
 Text LONG_TERM
 EndOfLine

 FontSwitch 0 UN104B
 Positional 6 1179
 Positional 4 3461
 FontSwitch 10 BLANKP
 Text XXNAME:foo
 EndOfLine

=over 4

=item Text

'Text ' followed by the text

=item DJDE FONTS

'DJDE FONTS ' followed by a list of font names.

=item DJDE IMAGE

'DJDE IMAGE ' followed by the image filename

=item DJDE END

'DJDE END' indicates the end (and activation) of any pending DJDE sequences.

=item FontSwitch

'FontSwitch # fontname' If the font number can be matched back to a name then
the font name is returned as well.

=item EndOfLine

'EndOfLine' This occurs at the end of Metacode records.

=item Orientation

'Orientation #' Portrait / Landscape

=item Positional

'Positional # ###' Seek to this location on the page. This must be further
explored to make it useful.

=item Drawing

'Drawing ## C' Display a drawing character. This is usually in a symbols font.

=item The codes 9 through 31

I have no idea.

=item ERROR

This indicates an error occured in the parse.

=back

=head1 METACODE FORMAT

A metacode file is separated into a series of contiguous records. Each record
consists of a two byte length value and the remainder is Metacode. The first
part of the Metacode is typically a font setting (to zero) and then a control
character. This can be ignored for most work. The following string
demonstrates the record format. Note that the two byte length value includes
itself so a record with length 3 is likely to simply be "\00\03\01".

The actual printer codes aren't fully understood yet though if you need more
detail just examine this module's source code.

=head1 METACODE EXAMPLE

This is an example of a complete Metacode record complete with header, body
and tail.

 "\00\11" .  # record length - 17 bytes
 "\00\00+" . # FontSwitch 0 and control character
 "\02" .     # a command
 "\06\00\04".#  ''
 "\04\00\04".#  ''
 "Text".     # printable data
 "\01";      # end of record

=head1 SEE ALSO

nntp://comp.sys.xerox
http://www.xerox-techsupport.com/

=head1 BUGS

Correctly parses text records - you cannot render images from the current
module. Further reverse engineering is required to get that.

I no longer have access to Xerox Metacode data and cannot create tests.

=head1 AUTHOR

Joshua b. Jore <jjore@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Joshua b. Jore. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software
   Foundation; version 2, or

b) the "Artistic License" which comes with Perl.

=cut
