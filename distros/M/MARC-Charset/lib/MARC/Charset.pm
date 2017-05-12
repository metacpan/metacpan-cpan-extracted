package MARC::Charset;

use strict;
use warnings;

our $VERSION = '1.35';

use base qw(Exporter);
our @EXPORT_OK = qw(marc8_to_utf8 utf8_to_marc8);

use Unicode::Normalize;
use Encode 'decode';
use charnames ':full';
use MARC::Charset::Table;
use MARC::Charset::Constants qw(:all);

=head1 NAME

MARC::Charset - convert MARC-8 encoded strings to UTF-8

=head1 SYNOPSIS

    # import the marc8_to_utf8 function
    use MARC::Charset 'marc8_to_utf8';
   
    # prepare STDOUT for utf8
    binmode(STDOUT, 'utf8');

    # print out some marc8 as utf8
    print marc8_to_utf8($marc8_string);

=head1 DESCRIPTION

MARC::Charset allows you to turn MARC-8 encoded strings into UTF-8
strings. MARC-8 is a single byte character encoding that predates unicode, and
allows you to put non-Roman scripts in MARC bibliographic records. 

    http://www.loc.gov/marc/specifications/spechome.html

=head1 EXPORTS

=cut

# get the mapping table
our $table = MARC::Charset::Table->new();

# set default character sets
# these are viewable at the package level
# in case someone wants to set them
our $DEFAULT_G0 = ASCII_DEFAULT; 
our $DEFAULT_G1 = EXTENDED_LATIN;

our %SPECIAL_DECOMPOSABLE = (
    chr(0x01a0) => chr(0x01a0), # uppercase o-hook
    chr(0x01af) => chr(0x01af), # uppercase u-hook
    chr(0x01a1) => chr(0x01a1), # lowercase o-hook
    chr(0x01b0) => chr(0x01b0), # lowercase u-hook
    chr(0x1ef1) => chr(0x01b0) . chr(0x0323), # lowercase u-hook with dot below
    chr(0x1ee9) => chr(0x01b0) . chr(0x0301), # lowercase u-hook with acute
    # Arabic to not decompose
    chr(0x0622) => chr(0x0622),
    chr(0x0623) => chr(0x0623),
    chr(0x0624) => chr(0x0624),
    chr(0x0625) => chr(0x0625),
    chr(0x0626) => chr(0x0626),
    chr(0x0649) => chr(0x0649),
    chr(0x0671) => chr(0x0671),
    chr(0x06c0) => chr(0x06c0),
    chr(0x06D3) => chr(0x06D3),
    # Cyrillic to not decompose
    chr(0x0439) => chr(0x0439),
    chr(0x0419) => chr(0x0419),
    chr(0x0453) => chr(0x0453),
    chr(0x0451) => chr(0x0451),
    chr(0x0457) => chr(0x0457),
    chr(0x045C) => chr(0x045C),
    chr(0x045E) => chr(0x045E),
    chr(0x0403) => chr(0x0403),
    chr(0x0401) => chr(0x0401),
    chr(0x0407) => chr(0x0407),
    chr(0x040C) => chr(0x040C),
    chr(0x040E) => chr(0x040E),
    # Katakana to not decompose
    chr(0x309B) => chr(0x309B),
    chr(0x309C) => chr(0x309C),
    chr(0x30AC) => chr(0x30AC),
    chr(0x30AE) => chr(0x30AE),
    chr(0x30B0) => chr(0x30B0),
    chr(0x30B2) => chr(0x30B2),
    chr(0x30B4) => chr(0x30B4),
    chr(0x30B6) => chr(0x30B6),
    chr(0x30B8) => chr(0x30B8),
    chr(0x30BA) => chr(0x30BA),
    chr(0x30BC) => chr(0x30BC),
    chr(0x30BE) => chr(0x30BE),
    chr(0x30C0) => chr(0x30C0),
    chr(0x30C2) => chr(0x30C2),
    chr(0x30C5) => chr(0x30C5),
    chr(0x30C7) => chr(0x30C7),
    chr(0x30C9) => chr(0x30C9),
    chr(0x30D0) => chr(0x30D0),
    chr(0x30D1) => chr(0x30D1),
    chr(0x30D3) => chr(0x30D3),
    chr(0x30D4) => chr(0x30D4),
    chr(0x30D6) => chr(0x30D6),
    chr(0x30D7) => chr(0x30D7),
    chr(0x30D9) => chr(0x30D9),
    chr(0x30DA) => chr(0x30DA),
    chr(0x30DC) => chr(0x30DC),
    chr(0x30DD) => chr(0x30DD),
    chr(0x30F4) => chr(0x30F4),
    chr(0x30F7) => chr(0x30F7),
    chr(0x30F8) => chr(0x30F8),
    chr(0x30F9) => chr(0x30F9),
    chr(0x30FA) => chr(0x30FA),
    chr(0x30FE) => chr(0x30FE),
    chr(0x30FF) => chr(0x30FF),
);

=head2 ignore_errors()

Tells MARC::Charset whether or not to ignore all encoding errors, and
returns the current setting.  This is helpful if you have records that
contain both MARC8 and UNICODE characters.

    my $ignore = MARC::Charset->ignore_errors();
    
    MARC::Charset->ignore_errors(1); # ignore errors
    MARC::Charset->ignore_errors(0); # DO NOT ignore errors

=cut


our $_ignore_errors = 0;
sub ignore_errors {
	my ($self,$i) = @_;
	$_ignore_errors = $i if (defined($i));
	return $_ignore_errors;
}


=head2 assume_unicode()

Tells MARC::Charset whether or not to assume UNICODE when an error is
encountered in ignore_errors mode and returns the current setting.
This is helpful if you have records that contain both MARC8 and UNICODE
characters.

    my $setting = MARC::Charset->assume_unicode();
    
    MARC::Charset->assume_unicode(1); # assume characters are unicode (utf-8)
    MARC::Charset->assume_unicode(0); # DO NOT assume characters are unicode

=cut


our $_assume = '';
sub assume_unicode {
	my ($self,$i) = @_;
	$_assume = 'utf8' if (defined($i) and $i);
	return 1 if ($_assume eq 'utf8');
}


=head2 assume_encoding()

Tells MARC::Charset whether or not to assume a specific encoding when an error
is encountered in ignore_errors mode and returns the current setting.  This
is helpful if you have records that contain both MARC8 and other characters.

    my $setting = MARC::Charset->assume_encoding();
    
    MARC::Charset->assume_encoding('cp850'); # assume characters are cp850
    MARC::Charset->assume_encoding(''); # DO NOT assume any encoding

=cut


sub assume_encoding {
	my ($self,$i) = @_;
	$_assume = $i if (defined($i));
	return $_assume;
}


# place holders for working graphical character sets
my $G0; 
my $G1;

=head2 marc8_to_utf8()

Converts a MARC-8 encoded string to UTF-8.

    my $utf8 = marc8_to_utf8($marc8);

If you'd like to ignore errors pass in a true value as the 2nd 
parameter or call MARC::Charset->ignore_errors() with a true
value:

    my $utf8 = marc8_to_utf8($marc8, 'ignore-errors');

  or
  
    MARC::Charset->ignore_errors(1);
    my $utf8 = marc8_to_utf8($marc8);

=cut


sub marc8_to_utf8
{
    my ($marc8, $ignore_errors) = @_;
    reset_charsets();

    $ignore_errors = $_ignore_errors if (!defined($ignore_errors));

    # holder for our utf8
    my $utf8 = '';

    my $index = 0;
    my $length = length($marc8);
    my $combining = '';
    CHAR_LOOP: while ($index < $length) 
    {
        # whitespace, line feeds and carriage returns just get added on unmolested
        if (substr($marc8, $index, 1) =~ m/(\s+|\x0A+|\x0D+)/so)
        {
            $utf8 .= $1;
            $index += 1;
            next CHAR_LOOP;
        }

        # look for any escape sequences
        my $new_index = _process_escape(\$marc8, $index, $length);
        if ($new_index > $index)
        {
            $index = $new_index;
            next CHAR_LOOP;
        }

        my $found;
	CHARSET_LOOP: foreach my $charset ($G0, $G1) 
        {

            # cjk characters are a string of three chars
	    my $char_size = $charset eq CJK ? 3 : 1;

            # extract the next code point to examine
	    my $chunk = substr($marc8, $index, $char_size);

            my $code;
            if ($char_size == 1) {
                my $codepoint = ord($chunk);
                if ($codepoint >= 0x21 && $codepoint <= 0x7e) {
                    # character is G0
                    $code = $table->lookup_by_marc8($G0, $chunk);
                } elsif ($codepoint >= 0xa1 && $codepoint <= 0xfe) {
                    # character is G1, map it to G0 before atttempting lookup
                    $code = $table->lookup_by_marc8($G1, chr($codepoint - 128));
                } elsif ($codepoint >= 0x88 && $codepoint <= 0x8e) {
                    # in the C1 range used by MARC8
                    $code = $table->lookup_by_marc8(EXTENDED_LATIN, $chunk);
                } elsif ($codepoint >= 0x1b && $codepoint <= 0x1f) {
                    # in the C0 range used by MARC8
                    $code = $table->lookup_by_marc8(BASIC_LATIN, $chunk);
                }
            } else {
                # EACC doesn't need G0/G1 conversion
                $code = $table->lookup_by_marc8($charset, $chunk);
            }

            # try the next character set if no mapping was found
            next CHARSET_LOOP if ! $code;
            $found = 1;

            # gobble up all combining characters for appending later
            # this is necessary because combinging characters precede
            # the character they modify in MARC-8, whereas they follow
            # the character they modify in UTF-8.
            if ($code->is_combining())
            {
                # If the current character is the right half of a MARC-8 
                # ligature or double tilde, we don't want to include
                # it in the UTF-8 output.  For the explanation, see
                # http://lcweb2.loc.gov/diglib/codetables/45.html#Note1
                # Note that if the MARC-8 string includes a right half
                # without the corresponding left half, the right half will
                # get dropped instead of being mapped to its UCS alternate.
                # That's OK since including only one half of a double diacritic
                # was presumably a mistake to begin with. 
                unless (defined $code->marc_left_half())
                {
                    $combining .= $code->char_value();
                }
	        }
            else
            {
                $utf8 .= $code->char_value() . $combining;
                $combining = '';
            }

            $index += $char_size;
            next CHAR_LOOP;
	}

        if (!$found)
        {
            warn(sprintf("no mapping found for [0x\%X] at position $index in $marc8 ".
                "g0=".MARC::Charset::Constants::charset_name($G0) . " " .
                "g1=".MARC::Charset::Constants::charset_name($G1), unpack('C',substr($marc8,$index,1))));
            if (!$ignore_errors)
            {
                reset_charsets();
                return;
            }
            if ($_assume)
            {
                reset_charsets();
                return NFC(decode($_assume => $marc8));
            }
            $index += 1;
        }

    }

    # return the utf8
    reset_charsets();
    utf8::upgrade($utf8);
    return $utf8;
}



=head2 utf8_to_marc8()

Will attempt to translate utf8 into marc8. 

    my $marc8 = utf8_to_marc8($utf8);

If you'd like to ignore errors, or characters that can't be
converted to marc8 then pass in a true value as the second
parameter:

    my $marc8 = utf8_to_marc8($utf8, 'ignore-errors');

  or
  
    MARC::Charset->ignore_errors(1);
    my $utf8 = marc8_to_utf8($marc8);

=cut

sub utf8_to_marc8
{
    my ($utf8, $ignore_errors) = @_;
    reset_charsets();

    $ignore_errors = $_ignore_errors if (!defined($ignore_errors));

    # decompose combined characters
    $utf8 = join('', 
        map { exists $SPECIAL_DECOMPOSABLE{$_} ? $SPECIAL_DECOMPOSABLE{$_} : NFD($_) }
        split //, $utf8
    );

    my $len = length($utf8);
    my $marc8 = '';
    for (my $i=0; $i<$len; $i++)
    {
        my $slice = substr($utf8, $i, 1);

        # spaces are copied from utf8 into marc8
        if ($slice eq ' ')
        {
            $marc8 .= ' ';
            next;
        }
        
        # try to find the code point in our mapping table 
        my $code = $table->lookup_by_utf8($slice);

        if (! $code)
        {
            warn("no mapping found at position $i in $utf8"); 
            reset_charsets() and return unless $ignore_errors;
        }

        # if it's a combining character move it around
        if ($code->is_combining())
        {
            my $prev = chop($marc8);
            if ($code->marc_left_half())
            {
                # don't add the MARC-8 right half character
                # if it was already inserted when the double
                # diacritic was converted from UTF-8
                if ($code->marc_value() eq substr($marc8, -1, 1))
                {
                    $marc8 .= $prev;
                    next;
                } 
            }
            $marc8 .= $code->marc_value() . $prev;
            if ($code->marc_right_half())
            {
                $marc8 .= chr(hex($code->marc_right_half()));
            }
            next;
        }

        # look to see if we need to escape to a new G0 charset
        my $charset_value = $code->charset_value();

        if ($code->default_charset_group() eq 'G0' 
            and $G0 ne $charset_value)
        {
            if ($G0 eq ASCII_DEFAULT and $charset_value eq BASIC_LATIN)
            {
                # don't bother escaping, they're functionally the same 
            }
            else 
            {
                $marc8 .= $code->get_escape();
                $G0 = $charset_value;
            }
        }

        # look to see if we need to escape to a new G1 charset
        elsif ($code->default_charset_group() eq 'G1'
            and $G1 ne $charset_value)
        {
            $marc8 .= $code->get_escape();
            $G1 = $charset_value;
        }

        $marc8 .= $code->marc_value();
    }

    # escape back to default G0 if necessary
    if ($G0 ne $DEFAULT_G0)
    {
        if ($DEFAULT_G0 eq ASCII_DEFAULT) { $marc8 .= ESCAPE . ASCII_DEFAULT; }
        elsif ($DEFAULT_G0 eq CJK) { $marc8 .= ESCAPE . MULTI_G0_A . CJK; }
        else { $marc8 .= ESCAPE . SINGLE_G0_A . $DEFAULT_G0; }
    }

    # escape back to default G1 if necessary
    if ($G1 ne $DEFAULT_G1)
    {
        if ($DEFAULT_G1 eq CJK) { $marc8 .= ESCAPE . MULTI_G1_A . $DEFAULT_G1; }
        else { $marc8 .= ESCAPE . SINGLE_G1_A . $DEFAULT_G1; }
    }

    return $marc8;
}



=head1 DEFAULT CHARACTER SETS

If you need to alter the default character sets you can set the 
$MARC::Charset::DEFAULT_G0 and $MARC::Charset::DEFAULT_G1 variables to the 
appropriate character set code:

    use MARC::Charset::Constants qw(:all);
    $MARC::Charset::DEFAULT_G0 = BASIC_ARABIC;
    $MARC::Charset::DEFAULT_G1 = EXTENDED_ARABIC;

=head1 SEE ALSO

=over 4

=item * L<MARC::Charset::Constant>

=item * L<MARC::Charset::Table>

=item * L<MARC::Charset::Code>

=item * L<MARC::Charset::Compiler>

=item * L<MARC::Record>

=item * L<MARC::XML>

=back 

=head1 AUTHOR

Ed Summers (ehs@pobox.com)

=cut


sub _process_escape 
{
    ## this stuff is kind of scary ... for an explanation of what is 
    ## going on here check out the MARC-8 specs at LC. 
    ## http://lcweb.loc.gov/marc/specifications/speccharmarc8.html
    my ($str_ref, $left, $right) = @_;

    # first char needs to be an escape or else this isn't an escape sequence
    return $left unless substr($$str_ref, $left, 1) eq ESCAPE;

    ## if we don't have at least one character after the escape
    ## then this can't be a character escape sequence
    return $left if ($left+1 >= $right); 

    ## pull off the first escape
    my $esc_char_1 = substr($$str_ref, $left+1, 1);

    ## the first method of escaping to small character sets
    if ( $esc_char_1 eq GREEK_SYMBOLS
        or $esc_char_1 eq SUBSCRIPTS 
        or $esc_char_1 eq SUPERSCRIPTS
        or $esc_char_1 eq ASCII_DEFAULT) 
    {
        $G0 = $esc_char_1;
        return $left+2;
    }

    ## the second more complicated method of escaping to bigger charsets 
    return $left if $left+2 >= $right;

    my $esc_char_2 = substr($$str_ref, $left+2, 1);
    my $esc_chars = $esc_char_1 . $esc_char_2;

    if ($esc_char_1 eq SINGLE_G0_A 
        or $esc_char_1 eq SINGLE_G0_B) 
    {
        $G0 = $esc_char_2;
        return $left+3;
    }

    elsif ($esc_char_1 eq SINGLE_G1_A 
        or $esc_char_1 eq SINGLE_G1_B) 
    {
        $G1 = $esc_char_2;
        return $left+3;
    }

    elsif ( $esc_char_1 eq MULTI_G0_A ) {
	$G0 = $esc_char_2;
        return $left+3;
    }

    elsif ($esc_chars eq MULTI_G0_B 
        and ($left+3 < $right)) 
    {
	$G0 = substr($$str_ref, $left+3, 1);
	return $left+4;
    }

    elsif (($esc_chars eq MULTI_G1_A or $esc_chars eq MULTI_G1_B)
        and ($left + 3 < $right)) 
    {
	$G1 = substr($$str_ref, $left+3, 1);
	return $left+4;
    }

    # we should never get here
    warn("seem to have fallen through in _process_escape()");
    return $left;
}

sub reset_charsets
{
    $G0 = $DEFAULT_G0;
    $G1 = $DEFAULT_G1;
}

1;
