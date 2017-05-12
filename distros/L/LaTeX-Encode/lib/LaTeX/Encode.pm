#========================================================================
#
# LaTeX::Encode
#
# DESCRIPTION
#   Provides a function to encode text that contains characters
#   special to LaTeX.
#
# AUTHOR
#   Andrew Ford <a.ford@ford-mason.co.uk>
#
# COPYRIGHT
#   Copyright (C) 2007-2012 Andrew Ford.   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#   $Id: Encode.pm 32 2012-09-30 20:33:42Z andrew $
#========================================================================

package LaTeX::Encode;

use strict;
use warnings;

require 5.008_001;

use Readonly;

use base qw(Exporter);

our $VERSION     = '0.091.6';

our @EXPORT      = qw(latex_encode);
our @EXPORT_OK   = qw(add_latex_encodings remove_latex_encodings reset_latex_encodings);
our %EXPORT_TAGS = ( all => [ qw( latex_encode 
                                  add_latex_encodings
                                  remove_latex_encodings
                                  reset_latex_encodings ) ] );

our @mappings_specified_on_import;

Readonly my $IMPORT_TAG_ADD    => 'add';
Readonly my $IMPORT_TAG_REMOVE => 'remove';

my %latex_encoding_base;

our $encoded_char_re;

our %latex_encoding;

our %provided_by;

# Encode text with characters special to LaTeX

sub latex_encode {
    my $text = shift;
    my $options = ref $_[0] ? shift : { @_ };
    my $exceptions    = $options->{except};
    my $iquotes       = $options->{iquotes};
    my $packages_reqd = $options->{packages};
    my $unmatched     = $options->{unmatched};


    # If a list of exception characters was specified then we replace
    # those characters in the text string with something that is not
    # going to match the encoding regular expression.  The encoding we
    # use is a hex 01 byte followed by four hexadecimal digits

    if ($exceptions) {
        $exceptions =~ s{ \\ }{\\\\}gx;
        $text =~ s{ ([\x{01}$exceptions]) }
                  { sprintf("\x{01}%04x", ord($1)); }gxe;
    }

    # Deal with "intelligent quotes".  This can be done separately
    # from the rest of the encoding as the characters ` and ' are not
    # encoded.

    if ($iquotes) {

        # A single or double quote before a word character, preceded
        # by start of line, whitespace or punctuation gets converted
        # to "`" or "``" respectively.

        $text =~ s{ ( ^ | [\s\p{IsPunct}] )( ['"] ) (?= \w ) }
                  { $2 eq '"' ? "$1``" : "$1`" }mgxe;

        # A double quote preceded by a word or punctuation character
        # and followed by whitespace or end of line gets converted to
        # "''".  (Final single quotes are represented by themselves so
        # we don't need to worry about those.)

        $text =~ s{ (?<= [\w\p{IsPunct}] ) " (?= \s | $ ) }
                  { "''" }mgxe
    }


    # Replace any characters that need encoding

    $text =~ s{ ($encoded_char_re) }
              { $packages_reqd->{$provided_by{$1}} = 1
                    if ref $packages_reqd and exists $provided_by{$1};
                $latex_encoding{$1} }gsxe;

    $text =~ s{ ([\x{00}\x{02}-\x{09}\x{0b}\x{0c}\x{0e}-\x{1f}\x{007f}-\x{ffff}]) }
              { _replace_unencoded_char(ord($1), $unmatched) }gxse;


    # If the caller specified exceptions then we need to decode them

    if ($exceptions) {
        $text =~ s{ \x{01} ([0-9a-f]{4}) }{ chr(hex($1)) }gxe;
    }

    return $text;
}


sub _replace_unencoded_char {
    my ($charcode, $action) = @_;
    
    if (ref $action eq 'CODE') {
        return $action->($charcode);
    }
    elsif (($action || '') eq 'ignore') {
        return '';
    }
    else {
        return sprintf('\\%s{%04x}', $action || 'unmatched', $charcode);
    }
}


# Add encodings to the encoding table
# Return the changed encodings

sub add_latex_encodings {
    my (%new_encoding) = @_;
    my %old_encoding;
    my $changed;

    foreach my $key (keys %new_encoding) {
        if ((! exists $latex_encoding{$key}) or ($latex_encoding{$key} ne $new_encoding{$key})) {
            $old_encoding{$key} = $latex_encoding{$key} if defined wantarray and exists $latex_encoding{$key};
            $latex_encoding{$key} = $new_encoding{$key};
            $changed = 1;
        }
    }
    _compile_encoding_regexp() if $changed;
    return unless defined wantarray;
    return %old_encoding;
}


# Remove encodings from the encoding table
# Return the removed encodings

sub remove_latex_encodings {
    my (@keys) = @_;
    my %removed_encoding;
    
    foreach my $key (@keys) {
        if (exists $latex_encoding{$key}) {
            $removed_encoding{$key} = delete $latex_encoding{$key};
        }
    }
    _compile_encoding_regexp() if keys %removed_encoding;
    return unless defined wantarray;
    return %removed_encoding;
}


# Reset the encoding table

sub reset_latex_encodings {
    my ($class, $forget_import_specifiers) = @_;
    if ($class !~ /::/) {
        $forget_import_specifiers = $class;
    }
    %latex_encoding = ();

    $latex_encoding{$_} = $latex_encoding_base{$_} 
         for keys %latex_encoding_base;

    if (! $forget_import_specifiers ) {
        foreach my $spec ( @mappings_specified_on_import ) {
            if ($spec->[0] eq $IMPORT_TAG_ADD) {
                add_latex_encodings(%{$spec->[1]});
            }
            elsif ($spec->[0] eq $IMPORT_TAG_REMOVE) {
                remove_latex_encodings(@{$spec->[1]});
            }
        }
    }
    _compile_encoding_regexp();
    
    return;
}


# Import function - picks out 'add' and 'remove' tags and adds or removes encodings
# appropriately

sub import {
    my ($self, @list) = @_;
    $DB::Simple = 1;
    my $i = 0;
    while ($i < @list) {
        if ($list[$i] eq $IMPORT_TAG_ADD) {
            my ($add, $to_add) = splice(@list, $i, 2);
            add_latex_encodings(%$to_add);
            push @mappings_specified_on_import, [ $IMPORT_TAG_ADD => $to_add ];
        }
        elsif ($list[$i] eq $IMPORT_TAG_REMOVE) {
            my ($remove, $to_remove) = splice(@list, $i, 2);
            remove_latex_encodings(@$to_remove);
            push @mappings_specified_on_import, [ $IMPORT_TAG_REMOVE => $to_remove ];
        }
        else {
            $i++;
        }
    }
    $self->export_to_level(1, $self, @list);
    return;
}


%latex_encoding_base = (

    chr(0x0022) => '{\\textacutedbl}',            # QUOTATION MARK                               (&quot;)
    chr(0x0023) => '\\#',                         # NUMBER SIGN                                  (&#35;)
    chr(0x0024) => '\\$',                         # DOLLAR SIGN                                  (&#36;)
    chr(0x0025) => '\\%',                         # PERCENT SIGN                                 (&#37;)
    chr(0x0026) => '\\&',                         # AMPERSAND                                    (&amp;)
    chr(0x003c) => '{\\textlangle}',              # LESS-THAN SIGN                               (&lt;)
    chr(0x003e) => '{\\textrangle}',              # GREATER-THAN SIGN                            (&gt;)
    chr(0x005c) => '{\\textbackslash}',           # REVERSE SOLIDUS                              (&#92;)
    chr(0x005e) => '\\^{ }',                      # CIRCUMFLEX ACCENT                            (&#94;)
    chr(0x005f) => '\\_',                         # LOW LINE                                     (&#95;)
    chr(0x007b) => '\\{',                         # LEFT CURLY BRACKET                           (&#123;)
    chr(0x007d) => '\\}',                         # RIGHT CURLY BRACKET                          (&#125;)
    chr(0x007e) => '{\\texttildelow}',            # TILDE                                        (&#126;)

    # C1 Controls and Latin-1 Supplement

    chr(0x00a0) => '~',                           # NO-BREAK SPACE                               (&nbsp;)
    chr(0x00a1) => '{\\textexclamdown}',          # INVERTED EXCLAMATION MARK                    (&iexcl;)
    chr(0x00a2) => '{\\textcent}',                # CENT SIGN                                    (&cent;)
    chr(0x00a3) => '{\\textsterling}',            # POUND SIGN                                   (&pound;)
    chr(0x00a4) => '{\\textcurrency}',            # CURRENCY SIGN                                (&curren;)
    chr(0x00a5) => '{\\textyen}',                 # YEN SIGN                                     (&yen;)
    chr(0x00a6) => '{\\textbrokenbar}',           # BROKEN BAR                                   (&brvbar;)
    chr(0x00a7) => '{\\textsection}',             # SECTION SIGN                                 (&sect;)
    chr(0x00a8) => '{\\textasciidieresis}',       # DIAERESIS                                    (&uml;)
    chr(0x00a9) => '{\\textcopyright}',           # COPYRIGHT SIGN                               (&copy;)
    chr(0x00aa) => '{\\textordfeminine}',         # FEMININE ORDINAL INDICATOR                   (&ordf;)
    chr(0x00ab) => '{\\guillemotleft}',           # LEFT-POINTING DOUBLE ANGLE QUOTATION MARK    (&laquo;)
    chr(0x00ac) => '{\\textlnot}',                # NOT SIGN                                     (&not;)
    chr(0x00ad) => '\\-',                         # SOFT HYPHEN                                  (&shy;)
    chr(0x00ae) => '{\\textregistered}',          # REGISTERED SIGN                              (&reg;)
    chr(0x00af) => '{\\textasciimacron}',         # MACRON                                       (&macr;)
    chr(0x00b0) => '{\\textdegree}',              # DEGREE SIGN                                  (&deg;)
    chr(0x00b1) => '{\\textpm}',                  # PLUS-MINUS SIGN                              (&plusmn;)
    chr(0x00b2) => '{\\texttwosuperior}',         # SUPERSCRIPT TWO                              (&sup2;)
    chr(0x00b3) => '{\\textthreesuperior}',       # SUPERSCRIPT THREE                            (&sup3;)
    chr(0x00b4) => '{\\textasciiacute}',          # ACUTE ACCENT                                 (&acute;)
    chr(0x00b5) => '{\\textmu}',                  # MICRO SIGN                                   (&micro;)
    chr(0x00b6) => '{\\textparagraph}',           # PILCROW SIGN                                 (&para;)
    chr(0x00b7) => '{\\textperiodcentered}',      # MIDDLE DOT                                   (&middot;)
    chr(0x00b8) => '{\\c{~}}',                    # CEDILLA                                      (&cedil;)
    chr(0x00b9) => '{\\textonesuperior}',         # SUPERSCRIPT ONE                              (&sup1;)
    chr(0x00ba) => '{\\textordmasculine}',        # MASCULINE ORDINAL INDICATOR                  (&ordm;)
    chr(0x00bb) => '{\\guillemotright}',          # RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK   (&raquo;)
    chr(0x00bc) => '{\\textonequarter}',          # VULGAR FRACTION ONE QUARTER                  (&frac14;)
    chr(0x00bd) => '{\\textonehalf}',             # VULGAR FRACTION ONE HALF                     (&frac12;)
    chr(0x00be) => '{\\textthreequarters}',       # VULGAR FRACTION THREE QUARTERS               (&frac34;)
    chr(0x00bf) => '{\\textquestiondown}',        # INVERTED QUESTION MARK                       (&iquest;)
    chr(0x00c0) => '{\\`A}',                      # LATIN CAPITAL LETTER A WITH GRAVE            (&Agrave;)
    chr(0x00c1) => '{\\\'A}',                     # LATIN CAPITAL LETTER A WITH ACUTE            (&Aacute;)
    chr(0x00c2) => '{\\^A}',                      # LATIN CAPITAL LETTER A WITH CIRCUMFLEX       (&Acirc;)
    chr(0x00c3) => '{\\~A}',                      # LATIN CAPITAL LETTER A WITH TILDE            (&Atilde;)
    chr(0x00c4) => '{\\"A}',                      # LATIN CAPITAL LETTER A WITH DIAERESIS        (&Auml;)
    chr(0x00c5) => '{\\AA}',                      # LATIN CAPITAL LETTER A WITH RING ABOVE       (&Aring;)
    chr(0x00c6) => '{\\AE}',                      # LATIN CAPITAL LETTER AE                      (&AElig;)
    chr(0x00c7) => '\\c{C}',                      # LATIN CAPITAL LETTER C WITH CEDILLA          (&Ccedil;)
    chr(0x00c8) => '{\\`E}',                      # LATIN CAPITAL LETTER E WITH GRAVE            (&Egrave;)
    chr(0x00c9) => '{\\\'E}',                     # LATIN CAPITAL LETTER E WITH ACUTE            (&Eacute;)
    chr(0x00ca) => '{\\^E}',                      # LATIN CAPITAL LETTER E WITH CIRCUMFLEX       (&Ecirc;)
    chr(0x00cb) => '{\\"E}',                      # LATIN CAPITAL LETTER E WITH DIAERESIS        (&Euml;)
    chr(0x00cc) => '{\\`I}',                      # LATIN CAPITAL LETTER I WITH GRAVE            (&Igrave;)
    chr(0x00cd) => '{\\\'I}',                     # LATIN CAPITAL LETTER I WITH ACUTE            (&Iacute;)
    chr(0x00ce) => '{\\^I}',                      # LATIN CAPITAL LETTER I WITH CIRCUMFLEX       (&Icirc;)
    chr(0x00cf) => '{\\"I}',                      # LATIN CAPITAL LETTER I WITH DIAERESIS        (&Iuml;)
    chr(0x00d0) => '{\\DH}',                      # LATIN CAPITAL LETTER ETH                     (&ETH;)
    chr(0x00d1) => '{\\~N}',                      # LATIN CAPITAL LETTER N WITH TILDE            (&Ntilde;)
    chr(0x00d2) => '{\\`O}',                      # LATIN CAPITAL LETTER O WITH GRAVE            (&Ograve;)
    chr(0x00d3) => '{\\\'O}',                     # LATIN CAPITAL LETTER O WITH ACUTE            (&Oacute;)
    chr(0x00d4) => '{\\^O}',                      # LATIN CAPITAL LETTER O WITH CIRCUMFLEX       (&Ocirc;)
    chr(0x00d5) => '{\\~O}',                      # LATIN CAPITAL LETTER O WITH TILDE            (&Otilde;)
    chr(0x00d6) => '{\\"O}',                      # LATIN CAPITAL LETTER O WITH DIAERESIS        (&Ouml;)
    chr(0x00d7) => '{\\texttimes}',               # MULTIPLICATION SIGN                          (&times;)
    chr(0x00d8) => '{\\O}',                       # LATIN CAPITAL LETTER O WITH STROKE           (&Oslash;)
    chr(0x00d9) => '{\\`U}',                      # LATIN CAPITAL LETTER U WITH GRAVE            (&Ugrave;)
    chr(0x00da) => '{\\\'U}',                     # LATIN CAPITAL LETTER U WITH ACUTE            (&Uacute;)
    chr(0x00db) => '{\\^U}',                      # LATIN CAPITAL LETTER U WITH CIRCUMFLEX       (&Ucirc;)
    chr(0x00dc) => '{\\"U}',                      # LATIN CAPITAL LETTER U WITH DIAERESIS        (&Uuml;)
    chr(0x00dd) => '{\\\'Y}',                     # LATIN CAPITAL LETTER Y WITH ACUTE            (&Yacute;)
    chr(0x00de) => '{\\TH}',                      # LATIN CAPITAL LETTER THORN                   (&THORN;)
    chr(0x00df) => '{\\ss}',                      # LATIN SMALL LETTER SHARP S                   (&szlig;)
    chr(0x00e0) => '{\\`a}',                      # LATIN SMALL LETTER A WITH GRAVE              (&agrave;)
    chr(0x00e1) => '{\\\'a}',                     # LATIN SMALL LETTER A WITH ACUTE              (&aacute;)
    chr(0x00e2) => '{\\^a}',                      # LATIN SMALL LETTER A WITH CIRCUMFLEX         (&acirc;)
    chr(0x00e3) => '{\\~a}',                      # LATIN SMALL LETTER A WITH TILDE              (&atilde;)
    chr(0x00e4) => '{\\"a}',                      # LATIN SMALL LETTER A WITH DIAERESIS          (&auml;)
    chr(0x00e5) => '{\\aa}',                      # LATIN SMALL LETTER A WITH RING ABOVE         (&aring;)
    chr(0x00e6) => '{\\ae}',                      # LATIN SMALL LETTER AE                        (&aelig;)
    chr(0x00e7) => '\\c{c}',                      # LATIN SMALL LETTER C WITH CEDILLA            (&ccedil;)
    chr(0x00e8) => '{\\`e}',                      # LATIN SMALL LETTER E WITH GRAVE              (&egrave;)
    chr(0x00e9) => '{\\\'e}',                     # LATIN SMALL LETTER E WITH ACUTE              (&eacute;)
    chr(0x00ea) => '{\\^e}',                      # LATIN SMALL LETTER E WITH CIRCUMFLEX         (&ecirc;)
    chr(0x00eb) => '{\\"e}',                      # LATIN SMALL LETTER E WITH DIAERESIS          (&euml;)
    chr(0x00ec) => '{\\`i}',                      # LATIN SMALL LETTER I WITH GRAVE              (&igrave;)
    chr(0x00ed) => '{\\\'i}',                     # LATIN SMALL LETTER I WITH ACUTE              (&iacute;)
    chr(0x00ee) => '{\\^i}',                      # LATIN SMALL LETTER I WITH CIRCUMFLEX         (&icirc;)
    chr(0x00ef) => '{\\"i}',                      # LATIN SMALL LETTER I WITH DIAERESIS          (&iuml;)
    chr(0x00f0) => '{\\dh}',                      # LATIN SMALL LETTER ETH                       (&eth;)
    chr(0x00f1) => '{\\~n}',                      # LATIN SMALL LETTER N WITH TILDE              (&ntilde;)
    chr(0x00f2) => '{\\`o}',                      # LATIN SMALL LETTER O WITH GRAVE              (&ograve;)
    chr(0x00f3) => '{\\\'o}',                     # LATIN SMALL LETTER O WITH ACUTE              (&oacute;)
    chr(0x00f4) => '{\\^o}',                      # LATIN SMALL LETTER O WITH CIRCUMFLEX         (&ocirc;)
    chr(0x00f5) => '{\\~o}',                      # LATIN SMALL LETTER O WITH TILDE              (&otilde;)
    chr(0x00f6) => '{\\"o}',                      # LATIN SMALL LETTER O WITH DIAERESIS          (&ouml;)
    chr(0x00f7) => '{\\textdiv}',                 # DIVISION SIGN                                (&divide;)
    chr(0x00f8) => '{\\o}',                       # LATIN SMALL LETTER O WITH STROKE             (&oslash;)
    chr(0x00f9) => '{\\`u}',                      # LATIN SMALL LETTER U WITH GRAVE              (&ugrave;)
    chr(0x00fa) => '{\\\'u}',                     # LATIN SMALL LETTER U WITH ACUTE              (&uacute;)
    chr(0x00fb) => '{\\^u}',                      # LATIN SMALL LETTER U WITH CIRCUMFLEX         (&ucirc;)
    chr(0x00fc) => '{\\"u}',                      # LATIN SMALL LETTER U WITH DIAERESIS          (&uuml;)
    chr(0x00fd) => '{\\\'y}',                     # LATIN SMALL LETTER Y WITH ACUTE              (&yacute;)
    chr(0x00fe) => '{\\th}',                      # LATIN SMALL LETTER THORN                     (&thorn;)
    chr(0x00ff) => '{\\"y}',                      # LATIN SMALL LETTER Y WITH DIAERESIS          (&yuml;)

    # Latin Extended-A

    chr(0x0100) => '\\={A}',                      # LATIN CAPITAL LETTER A WITH MACRON
    chr(0x0101) => '\\={a}',                      # LATIN SMALL LETTER A WITH MACRON
    chr(0x0102) => '\\u{A}',                      # LATIN CAPITAL LETTER A WITH BREVE
    chr(0x0103) => '\\u{a}',                      # LATIN SMALL LETTER A WITH BREVE
    chr(0x0104) => '\\k{A}',                      # LATIN CAPITAL LETTER A WITH OGONEK
    chr(0x0105) => '\\k{a}',                      # LATIN SMALL LETTER A WITH OGONEK
    chr(0x0106) => '\\\'{C}',                     # LATIN CAPITAL LETTER C WITH ACUTE
    chr(0x0107) => '\\\'{c}',                     # LATIN SMALL LETTER C WITH ACUTE
    chr(0x0108) => '\\^{C}',                      # LATIN CAPITAL LETTER C WITH CIRCUMFLEX
    chr(0x0109) => '\\^{c}',                      # LATIN SMALL LETTER C WITH CIRCUMFLEX
    chr(0x010a) => '\\.{C}',                      # LATIN CAPITAL LETTER C WITH DOT ABOVE
    chr(0x010b) => '\\.{c}',                      # LATIN SMALL LETTER C WITH DOT ABOVE
    chr(0x010c) => '\\v{C}',                      # LATIN CAPITAL LETTER C WITH CARON
    chr(0x010d) => '\\v{c}',                      # LATIN SMALL LETTER C WITH CARON
    chr(0x010e) => '\\v{D}',                      # LATIN CAPITAL LETTER D WITH CARON
    chr(0x010f) => '\\v{d}',                      # LATIN SMALL LETTER D WITH CARON
    chr(0x0112) => '\\={E}',                      # LATIN CAPITAL LETTER E WITH MACRON
    chr(0x0113) => '\\={e}',                      # LATIN SMALL LETTER E WITH MACRON
    chr(0x0114) => '\\u{E}',                      # LATIN CAPITAL LETTER E WITH BREVE
    chr(0x0115) => '\\u{e}',                      # LATIN SMALL LETTER E WITH BREVE
    chr(0x0116) => '\\.{E}',                      # LATIN CAPITAL LETTER E WITH DOT ABOVE
    chr(0x0117) => '\\.{e}',                      # LATIN SMALL LETTER E WITH DOT ABOVE
    chr(0x0118) => '\\k{E}',                      # LATIN CAPITAL LETTER E WITH OGONEK
    chr(0x0119) => '\\k{e}',                      # LATIN SMALL LETTER E WITH OGONEK
    chr(0x011a) => '\\v{E}',                      # LATIN CAPITAL LETTER E WITH CARON
    chr(0x011b) => '\\v{e}',                      # LATIN SMALL LETTER E WITH CARON
    chr(0x011c) => '\\^{G}',                      # LATIN CAPITAL LETTER G WITH CIRCUMFLEX
    chr(0x011d) => '\\^{g}',                      # LATIN SMALL LETTER G WITH CIRCUMFLEX
    chr(0x011e) => '\\u{G}',                      # LATIN CAPITAL LETTER G WITH BREVE
    chr(0x011f) => '\\u{g}',                      # LATIN SMALL LETTER G WITH BREVE
    chr(0x0120) => '\\.{G}',                      # LATIN CAPITAL LETTER G WITH DOT ABOVE
    chr(0x0121) => '\\.{g}',                      # LATIN SMALL LETTER G WITH DOT ABOVE
    chr(0x0122) => '\\c{G}',                      # LATIN CAPITAL LETTER G WITH CEDILLA
    chr(0x0123) => '\\c{g}',                      # LATIN SMALL LETTER G WITH CEDILLA
    chr(0x0124) => '\\^{H}',                      # LATIN CAPITAL LETTER H WITH CIRCUMFLEX
    chr(0x0125) => '\\^{h}',                      # LATIN SMALL LETTER H WITH CIRCUMFLEX
    chr(0x0128) => '\\~{I}',                      # LATIN CAPITAL LETTER I WITH TILDE
    chr(0x0129) => '\\~{\\i}',                    # LATIN SMALL LETTER I WITH TILDE
    chr(0x012a) => '\\={I}',                      # LATIN CAPITAL LETTER I WITH MACRON
    chr(0x012b) => '\\={\\i}',                    # LATIN SMALL LETTER I WITH MACRON
    chr(0x012c) => '\\u{I}',                      # LATIN CAPITAL LETTER I WITH BREVE
    chr(0x012d) => '\\u{\\i}',                    # LATIN SMALL LETTER I WITH BREVE
    chr(0x012e) => '\\k{I}',                      # LATIN CAPITAL LETTER I WITH OGONEK
    chr(0x012f) => '\\k{i}',                      # LATIN SMALL LETTER I WITH OGONEK
    chr(0x0130) => '\\.{I}',                      # LATIN CAPITAL LETTER I WITH DOT ABOVE
    chr(0x0131) => '{\\i}',                       # LATIN SMALL LETTER DOTLESS I
    chr(0x0134) => '\\^{J}',                      # LATIN CAPITAL LETTER J WITH CIRCUMFLEX
    chr(0x0135) => '\\^{\\j}',                    # LATIN SMALL LETTER J WITH CIRCUMFLEX
    chr(0x0136) => '\\c{K}',                      # LATIN CAPITAL LETTER K WITH CEDILLA
    chr(0x0137) => '\\c{k}',                      # LATIN SMALL LETTER K WITH CEDILLA
    chr(0x0139) => '\\\'{L}',                     # LATIN CAPITAL LETTER L WITH ACUTE
    chr(0x013a) => '\\\'{l}',                     # LATIN SMALL LETTER L WITH ACUTE
    chr(0x013b) => '\\c{L}',                      # LATIN CAPITAL LETTER L WITH CEDILLA
    chr(0x013c) => '\\c{l}',                      # LATIN SMALL LETTER L WITH CEDILLA
    chr(0x013d) => '\\v{L}',                      # LATIN CAPITAL LETTER L WITH CARON
    chr(0x013e) => '\\v{l}',                      # LATIN SMALL LETTER L WITH CARON
    chr(0x0143) => '\\\'{N}',                     # LATIN CAPITAL LETTER N WITH ACUTE
    chr(0x0144) => '\\\'{n}',                     # LATIN SMALL LETTER N WITH ACUTE
    chr(0x0145) => '\\c{N}',                      # LATIN CAPITAL LETTER N WITH CEDILLA
    chr(0x0146) => '\\c{n}',                      # LATIN SMALL LETTER N WITH CEDILLA
    chr(0x0147) => '\\v{N}',                      # LATIN CAPITAL LETTER N WITH CARON
    chr(0x0148) => '\\v{n}',                      # LATIN SMALL LETTER N WITH CARON
    chr(0x014c) => '\\={O}',                      # LATIN CAPITAL LETTER O WITH MACRON
    chr(0x014d) => '\\={o}',                      # LATIN SMALL LETTER O WITH MACRON
    chr(0x014e) => '\\u{O}',                      # LATIN CAPITAL LETTER O WITH BREVE
    chr(0x014f) => '\\u{o}',                      # LATIN SMALL LETTER O WITH BREVE
    chr(0x0152) => '{\\OE}',                      # LATIN CAPITAL LIGATURE OE                    (&OElig;)
    chr(0x0153) => '{\\oe}',                      # LATIN SMALL LIGATURE OE                      (&oelig;)
    chr(0x0154) => '\\\'{R}',                     # LATIN CAPITAL LETTER R WITH ACUTE
    chr(0x0155) => '\\\'{r}',                     # LATIN SMALL LETTER R WITH ACUTE
    chr(0x0156) => '\\c{R}',                      # LATIN CAPITAL LETTER R WITH CEDILLA
    chr(0x0157) => '\\c{r}',                      # LATIN SMALL LETTER R WITH CEDILLA
    chr(0x0158) => '\\v{R}',                      # LATIN CAPITAL LETTER R WITH CARON
    chr(0x0159) => '\\v{r}',                      # LATIN SMALL LETTER R WITH CARON
    chr(0x015a) => '\\\'{S}',                     # LATIN CAPITAL LETTER S WITH ACUTE
    chr(0x015b) => '\\\'{s}',                     # LATIN SMALL LETTER S WITH ACUTE
    chr(0x015c) => '\\^{S}',                      # LATIN CAPITAL LETTER S WITH CIRCUMFLEX
    chr(0x015d) => '\\^{s}',                      # LATIN SMALL LETTER S WITH CIRCUMFLEX
    chr(0x015e) => '\\c{S}',                      # LATIN CAPITAL LETTER S WITH CEDILLA
    chr(0x015f) => '\\c{s}',                      # LATIN SMALL LETTER S WITH CEDILLA
    chr(0x0160) => '\\v{S}',                      # LATIN CAPITAL LETTER S WITH CARON            (&Scaron;)
    chr(0x0161) => '\\v{s}',                      # LATIN SMALL LETTER S WITH CARON              (&scaron;)
    chr(0x0162) => '\\c{T}',                      # LATIN CAPITAL LETTER T WITH CEDILLA
    chr(0x0163) => '\\c{t}',                      # LATIN SMALL LETTER T WITH CEDILLA
    chr(0x0164) => '\\v{T}',                      # LATIN CAPITAL LETTER T WITH CARON
    chr(0x0165) => '\\v{t}',                      # LATIN SMALL LETTER T WITH CARON
    chr(0x0168) => '\\~{U}',                      # LATIN CAPITAL LETTER U WITH TILDE
    chr(0x0169) => '\\~{u}',                      # LATIN SMALL LETTER U WITH TILDE
    chr(0x016a) => '\\={U}',                      # LATIN CAPITAL LETTER U WITH MACRON
    chr(0x016b) => '\\={u}',                      # LATIN SMALL LETTER U WITH MACRON
    chr(0x016c) => '\\u{U}',                      # LATIN CAPITAL LETTER U WITH BREVE
    chr(0x016d) => '\\u{u}',                      # LATIN SMALL LETTER U WITH BREVE
    chr(0x016e) => '\\r{U}',                      # LATIN CAPITAL LETTER U WITH RING ABOVE
    chr(0x016f) => '\\r{u}',                      # LATIN SMALL LETTER U WITH RING ABOVE
    chr(0x0172) => '\\k{U}',                      # LATIN CAPITAL LETTER U WITH OGONEK
    chr(0x0173) => '\\k{u}',                      # LATIN SMALL LETTER U WITH OGONEK
    chr(0x0174) => '\\^{W}',                      # LATIN CAPITAL LETTER W WITH CIRCUMFLEX
    chr(0x0175) => '\\^{w}',                      # LATIN SMALL LETTER W WITH CIRCUMFLEX
    chr(0x0176) => '\\^{Y}',                      # LATIN CAPITAL LETTER Y WITH CIRCUMFLEX
    chr(0x0177) => '\\^{y}',                      # LATIN SMALL LETTER Y WITH CIRCUMFLEX
    chr(0x0178) => '{\\"Y}',                      # LATIN CAPITAL LETTER Y WITH DIAERESIS        (&Yuml;)
    chr(0x0179) => '\\\'{Z}',                     # LATIN CAPITAL LETTER Z WITH ACUTE
    chr(0x017a) => '\\\'{z}',                     # LATIN SMALL LETTER Z WITH ACUTE
    chr(0x017b) => '\\.{Z}',                      # LATIN CAPITAL LETTER Z WITH DOT ABOVE
    chr(0x017c) => '\\.{z}',                      # LATIN SMALL LETTER Z WITH DOT ABOVE
    chr(0x017d) => '\\v{Z}',                      # LATIN CAPITAL LETTER Z WITH CARON
    chr(0x017e) => '\\v{z}',                      # LATIN SMALL LETTER Z WITH CARON
    chr(0x0192) => '{\\textflorin}',              # LATIN SMALL LETTER F WITH HOOK               (&fnof;)
    chr(0x01cd) => '\\v{A}',                      # LATIN CAPITAL LETTER A WITH CARON
    chr(0x01ce) => '\\v{a}',                      # LATIN SMALL LETTER A WITH CARON
    chr(0x01cf) => '\\v{I}',                      # LATIN CAPITAL LETTER I WITH CARON
    chr(0x01d0) => '\\v{i}',                      # LATIN SMALL LETTER I WITH CARON
    chr(0x01d1) => '\\v{O}',                      # LATIN CAPITAL LETTER O WITH CARON
    chr(0x01d2) => '\\v{o}',                      # LATIN SMALL LETTER O WITH CARON
    chr(0x01d3) => '\\v{U}',                      # LATIN CAPITAL LETTER U WITH CARON
    chr(0x01d4) => '\\v{u}',                      # LATIN SMALL LETTER U WITH CARON
    chr(0x01e6) => '\\v{G}',                      # LATIN CAPITAL LETTER G WITH CARON
    chr(0x01e7) => '\\v{g}',                      # LATIN SMALL LETTER G WITH CARON
    chr(0x01e8) => '\\v{K}',                      # LATIN CAPITAL LETTER K WITH CARON
    chr(0x01e9) => '\\v{k}',                      # LATIN SMALL LETTER K WITH CARON
    chr(0x01ea) => '\\k{O}',                      # LATIN CAPITAL LETTER O WITH OGONEK
    chr(0x01eb) => '\\k{o}',                      # LATIN SMALL LETTER O WITH OGONEK
    chr(0x01f0) => '\\v{j}',                      # LATIN SMALL LETTER J WITH CARON
    chr(0x01f4) => '\\\'{G}',                     # LATIN CAPITAL LETTER G WITH ACUTE
    chr(0x01f5) => '\\\'{g}',                     # LATIN SMALL LETTER G WITH ACUTE
    chr(0x01f8) => '\\`{N}',                      # LATIN CAPITAL LETTER N WITH GRAVE
    chr(0x01f9) => '\\`{n}',                      # LATIN SMALL LETTER N WITH GRAVE

    # Spacing Modifier Letters

    chr(0x02c6) => '{\\textasciicircum}',         # MODIFIER LETTER CIRCUMFLEX ACCENT            (&circ;)
    chr(0x02dc) => '{\\textasciitilde}',          # SMALL TILDE                                  (&tilde;)

    # Greek and Coptic

    chr(0x0391) => '\\ensuremath{\\mathrm{A}}',   # GREEK CAPITAL LETTER ALPHA                   (&Alpha;)
    chr(0x0392) => '\\ensuremath{\\mathrm{B}}',   # GREEK CAPITAL LETTER BETA                    (&Beta;)
    chr(0x0393) => '\\ensuremath{\\Gamma}',       # GREEK CAPITAL LETTER GAMMA                   (&Gamma;)
    chr(0x0394) => '\\ensuremath{\\Delta}',       # GREEK CAPITAL LETTER DELTA                   (&Delta;)
    chr(0x0395) => '\\ensuremath{\\mathrm{E}}',   # GREEK CAPITAL LETTER EPSILON                 (&Epsilon;)
    chr(0x0396) => '\\ensuremath{\\mathrm{Z}}',   # GREEK CAPITAL LETTER ZETA                    (&Zeta;)
    chr(0x0397) => '\\ensuremath{\\mathrm{H}}',   # GREEK CAPITAL LETTER ETA                     (&Eta;)
    chr(0x0398) => '\\ensuremath{\\Theta}',       # GREEK CAPITAL LETTER THETA                   (&Theta;)
    chr(0x0399) => '\\ensuremath{\\mathrm{I}}',   # GREEK CAPITAL LETTER IOTA                    (&Iota;)
    chr(0x039a) => '\\ensuremath{\\mathrm{K}}',   # GREEK CAPITAL LETTER KAPPA                   (&Kappa;)
    chr(0x039b) => '\\ensuremath{\\Lambda}',      # GREEK CAPITAL LETTER LAMDA                   (&Lambda;)
    chr(0x039c) => '\\ensuremath{\\mathrm{M}}',   # GREEK CAPITAL LETTER MU                      (&Mu;)
    chr(0x039d) => '\\ensuremath{\\mathrm{N}}',   # GREEK CAPITAL LETTER NU                      (&Nu;)
    chr(0x039e) => '\\ensuremath{\\Xi}',          # GREEK CAPITAL LETTER XI                      (&Xi;)
    chr(0x039f) => '\\ensuremath{\\mathrm{O}}',   # GREEK CAPITAL LETTER OMICRON                 (&Omicron;)
    chr(0x03a0) => '\\ensuremath{\\Pi}',          # GREEK CAPITAL LETTER PI                      (&Pi;)
    chr(0x03a1) => '\\ensuremath{\\mathrm{R}}',   # GREEK CAPITAL LETTER RHO                     (&Rho;)
    chr(0x03a3) => '\\ensuremath{\\Sigma}',       # GREEK CAPITAL LETTER SIGMA                   (&Sigma;)
    chr(0x03a4) => '\\ensuremath{\\mathrm{T}}',   # GREEK CAPITAL LETTER TAU                     (&Tau;)
    chr(0x03a5) => '\\ensuremath{\\Upsilon}',     # GREEK CAPITAL LETTER UPSILON                 (&Upsilon;)
    chr(0x03a6) => '\\ensuremath{\\Phi}',         # GREEK CAPITAL LETTER PHI                     (&Phi;)
    chr(0x03a7) => '\\ensuremath{\\mathrm{X}}',   # GREEK CAPITAL LETTER CHI                     (&Chi;)
    chr(0x03a8) => '\\ensuremath{\\Psi}',         # GREEK CAPITAL LETTER PSI                     (&Psi;)
    chr(0x03a9) => '\\ensuremath{\\Omega}',       # GREEK CAPITAL LETTER OMEGA                   (&Omega;)
    chr(0x03b1) => '\\ensuremath{\\alpha}',       # GREEK SMALL LETTER ALPHA                     (&alpha;)
    chr(0x03b2) => '\\ensuremath{\\beta}',        # GREEK SMALL LETTER BETA                      (&beta;)
    chr(0x03b3) => '\\ensuremath{\\gamma}',       # GREEK SMALL LETTER GAMMA                     (&gamma;)
    chr(0x03b4) => '\\ensuremath{\\delta}',       # GREEK SMALL LETTER DELTA                     (&delta;)
    chr(0x03b5) => '\\ensuremath{\\epsilon}',     # GREEK SMALL LETTER EPSILON                   (&epsilon;)
    chr(0x03b6) => '\\ensuremath{\\zeta}',        # GREEK SMALL LETTER ZETA                      (&zeta;)
    chr(0x03b7) => '\\ensuremath{\\eta}',         # GREEK SMALL LETTER ETA                       (&eta;)
    chr(0x03b8) => '\\ensuremath{\\theta}',       # GREEK SMALL LETTER THETA                     (&theta;)
    chr(0x03b9) => '\\ensuremath{\\iota}',        # GREEK SMALL LETTER IOTA                      (&iota;)
    chr(0x03ba) => '\\ensuremath{\\kappa}',       # GREEK SMALL LETTER KAPPA                     (&kappa;)
    chr(0x03bb) => '\\ensuremath{\\lambda}',      # GREEK SMALL LETTER LAMDA                     (&lambda;)
    chr(0x03bc) => '\\ensuremath{\\mu}',          # GREEK SMALL LETTER MU                        (&mu;)
    chr(0x03bd) => '\\ensuremath{\\nu}',          # GREEK SMALL LETTER NU                        (&nu;)
    chr(0x03be) => '\\ensuremath{\\xi}',          # GREEK SMALL LETTER XI                        (&xi;)
    chr(0x03bf) => '\\ensuremath{o}',             # GREEK SMALL LETTER OMICRON                   (&omicron;)
    chr(0x03c0) => '\\ensuremath{\\pi}',          # GREEK SMALL LETTER PI                        (&pi;)
    chr(0x03c1) => '\\ensuremath{\\rho}',         # GREEK SMALL LETTER RHO                       (&rho;)
    chr(0x03c3) => '\\ensuremath{\\sigma}',       # GREEK SMALL LETTER SIGMA                     (&sigma;)
    chr(0x03c4) => '\\ensuremath{\\tau}',         # GREEK SMALL LETTER TAU                       (&tau;)
    chr(0x03c5) => '\\ensuremath{\\upsilon}',     # GREEK SMALL LETTER UPSILON                   (&upsilon;)
    chr(0x03c6) => '\\ensuremath{\\phi}',         # GREEK SMALL LETTER PHI                       (&phi;)
    chr(0x03c7) => '\\ensuremath{\\chi}',         # GREEK SMALL LETTER CHI                       (&chi;)
    chr(0x03c8) => '\\ensuremath{\\psi}',         # GREEK SMALL LETTER PSI                       (&psi;)
    chr(0x03c9) => '\\ensuremath{\\omega}',       # GREEK SMALL LETTER OMEGA                     (&omega;)
    chr(0x0e3f) => '{\\textbaht}',                # THAI CURRENCY SYMBOL BAHT

    # Latin Extended Additional

    chr(0x1e02) => '\\.{B}',                      # LATIN CAPITAL LETTER B WITH DOT ABOVE
    chr(0x1e03) => '\\.{b}',                      # LATIN SMALL LETTER B WITH DOT ABOVE
    chr(0x1e04) => '\\d{B}',                      # LATIN CAPITAL LETTER B WITH DOT BELOW
    chr(0x1e05) => '\\d{b}',                      # LATIN SMALL LETTER B WITH DOT BELOW
    chr(0x1e06) => '\\b{B}',                      # LATIN CAPITAL LETTER B WITH LINE BELOW
    chr(0x1e07) => '\\b{b}',                      # LATIN SMALL LETTER B WITH LINE BELOW
    chr(0x1e0a) => '\\.{D}',                      # LATIN CAPITAL LETTER D WITH DOT ABOVE
    chr(0x1e0b) => '\\.{d}',                      # LATIN SMALL LETTER D WITH DOT ABOVE
    chr(0x1e0c) => '\\d{D}',                      # LATIN CAPITAL LETTER D WITH DOT BELOW
    chr(0x1e0d) => '\\d{d}',                      # LATIN SMALL LETTER D WITH DOT BELOW
    chr(0x1e0e) => '\\b{D}',                      # LATIN CAPITAL LETTER D WITH LINE BELOW
    chr(0x1e0f) => '\\b{d}',                      # LATIN SMALL LETTER D WITH LINE BELOW
    chr(0x1e10) => '\\c{D}',                      # LATIN CAPITAL LETTER D WITH CEDILLA
    chr(0x1e11) => '\\c{d}',                      # LATIN SMALL LETTER D WITH CEDILLA
    chr(0x1e1e) => '\\.{F}',                      # LATIN CAPITAL LETTER F WITH DOT ABOVE
    chr(0x1e1f) => '\\.{f}',                      # LATIN SMALL LETTER F WITH DOT ABOVE
    chr(0x1e20) => '\\={G}',                      # LATIN CAPITAL LETTER G WITH MACRON
    chr(0x1e21) => '\\={g}',                      # LATIN SMALL LETTER G WITH MACRON
    chr(0x1e22) => '\\.{H}',                      # LATIN CAPITAL LETTER H WITH DOT ABOVE
    chr(0x1e23) => '\\.{h}',                      # LATIN SMALL LETTER H WITH DOT ABOVE
    chr(0x1e24) => '\\d{H}',                      # LATIN CAPITAL LETTER H WITH DOT BELOW
    chr(0x1e25) => '\\d{h}',                      # LATIN SMALL LETTER H WITH DOT BELOW
    chr(0x1e28) => '\\c{H}',                      # LATIN CAPITAL LETTER H WITH CEDILLA
    chr(0x1e29) => '\\c{h}',                      # LATIN SMALL LETTER H WITH CEDILLA
    chr(0x1e30) => '\\\'{K}',                     # LATIN CAPITAL LETTER K WITH ACUTE
    chr(0x1e31) => '\\\'{k}',                     # LATIN SMALL LETTER K WITH ACUTE
    chr(0x1e32) => '\\d{K}',                      # LATIN CAPITAL LETTER K WITH DOT BELOW
    chr(0x1e33) => '\\d{k}',                      # LATIN SMALL LETTER K WITH DOT BELOW
    chr(0x1e34) => '\\b{K}',                      # LATIN CAPITAL LETTER K WITH LINE BELOW
    chr(0x1e35) => '\\b{k}',                      # LATIN SMALL LETTER K WITH LINE BELOW
    chr(0x1e36) => '\\d{L}',                      # LATIN CAPITAL LETTER L WITH DOT BELOW
    chr(0x1e37) => '\\d{l}',                      # LATIN SMALL LETTER L WITH DOT BELOW
    chr(0x1e3a) => '\\b{L}',                      # LATIN CAPITAL LETTER L WITH LINE BELOW
    chr(0x1e3b) => '\\b{l}',                      # LATIN SMALL LETTER L WITH LINE BELOW
    chr(0x1e3e) => '\\\'{M}',                     # LATIN CAPITAL LETTER M WITH ACUTE
    chr(0x1e3f) => '\\\'{m}',                     # LATIN SMALL LETTER M WITH ACUTE
    chr(0x1e40) => '\\.{M}',                      # LATIN CAPITAL LETTER M WITH DOT ABOVE
    chr(0x1e41) => '\\.{m}',                      # LATIN SMALL LETTER M WITH DOT ABOVE
    chr(0x1e42) => '\\d{M}',                      # LATIN CAPITAL LETTER M WITH DOT BELOW
    chr(0x1e43) => '\\d{m}',                      # LATIN SMALL LETTER M WITH DOT BELOW
    chr(0x1e44) => '\\.{N}',                      # LATIN CAPITAL LETTER N WITH DOT ABOVE
    chr(0x1e45) => '\\.{n}',                      # LATIN SMALL LETTER N WITH DOT ABOVE
    chr(0x1e46) => '\\d{N}',                      # LATIN CAPITAL LETTER N WITH DOT BELOW
    chr(0x1e47) => '\\d{n}',                      # LATIN SMALL LETTER N WITH DOT BELOW
    chr(0x1e48) => '\\b{N}',                      # LATIN CAPITAL LETTER N WITH LINE BELOW
    chr(0x1e49) => '\\b{n}',                      # LATIN SMALL LETTER N WITH LINE BELOW
    chr(0x1e54) => '\\\'{P}',                     # LATIN CAPITAL LETTER P WITH ACUTE
    chr(0x1e55) => '\\\'{p}',                     # LATIN SMALL LETTER P WITH ACUTE
    chr(0x1e56) => '\\.{P}',                      # LATIN CAPITAL LETTER P WITH DOT ABOVE
    chr(0x1e57) => '\\.{p}',                      # LATIN SMALL LETTER P WITH DOT ABOVE
    chr(0x1e58) => '\\.{R}',                      # LATIN CAPITAL LETTER R WITH DOT ABOVE
    chr(0x1e59) => '\\.{r}',                      # LATIN SMALL LETTER R WITH DOT ABOVE
    chr(0x1e5a) => '\\d{R}',                      # LATIN CAPITAL LETTER R WITH DOT BELOW
    chr(0x1e5b) => '\\d{r}',                      # LATIN SMALL LETTER R WITH DOT BELOW
    chr(0x1e5e) => '\\b{R}',                      # LATIN CAPITAL LETTER R WITH LINE BELOW
    chr(0x1e5f) => '\\b{r}',                      # LATIN SMALL LETTER R WITH LINE BELOW
    chr(0x1e60) => '\\.{S}',                      # LATIN CAPITAL LETTER S WITH DOT ABOVE
    chr(0x1e61) => '\\.{s}',                      # LATIN SMALL LETTER S WITH DOT ABOVE
    chr(0x1e62) => '\\d{S}',                      # LATIN CAPITAL LETTER S WITH DOT BELOW
    chr(0x1e63) => '\\d{s}',                      # LATIN SMALL LETTER S WITH DOT BELOW
    chr(0x1e6a) => '\\.{T}',                      # LATIN CAPITAL LETTER T WITH DOT ABOVE
    chr(0x1e6b) => '\\.{t}',                      # LATIN SMALL LETTER T WITH DOT ABOVE
    chr(0x1e6c) => '\\d{T}',                      # LATIN CAPITAL LETTER T WITH DOT BELOW
    chr(0x1e6d) => '\\d{t}',                      # LATIN SMALL LETTER T WITH DOT BELOW
    chr(0x1e6e) => '\\b{T}',                      # LATIN CAPITAL LETTER T WITH LINE BELOW
    chr(0x1e6f) => '\\b{t}',                      # LATIN SMALL LETTER T WITH LINE BELOW
    chr(0x1e7c) => '\\~{V}',                      # LATIN CAPITAL LETTER V WITH TILDE
    chr(0x1e7d) => '\\~{v}',                      # LATIN SMALL LETTER V WITH TILDE
    chr(0x1e7e) => '\\d{V}',                      # LATIN CAPITAL LETTER V WITH DOT BELOW
    chr(0x1e7f) => '\\d{v}',                      # LATIN SMALL LETTER V WITH DOT BELOW
    chr(0x1e80) => '\\`{W}',                      # LATIN CAPITAL LETTER W WITH GRAVE
    chr(0x1e81) => '\\`{w}',                      # LATIN SMALL LETTER W WITH GRAVE
    chr(0x1e82) => '\\\'{W}',                     # LATIN CAPITAL LETTER W WITH ACUTE
    chr(0x1e83) => '\\\'{w}',                     # LATIN SMALL LETTER W WITH ACUTE
    chr(0x1e86) => '\\.{W}',                      # LATIN CAPITAL LETTER W WITH DOT ABOVE
    chr(0x1e87) => '\\.{w}',                      # LATIN SMALL LETTER W WITH DOT ABOVE
    chr(0x1e88) => '\\d{W}',                      # LATIN CAPITAL LETTER W WITH DOT BELOW
    chr(0x1e89) => '\\d{w}',                      # LATIN SMALL LETTER W WITH DOT BELOW
    chr(0x1e8a) => '\\.{X}',                      # LATIN CAPITAL LETTER X WITH DOT ABOVE
    chr(0x1e8b) => '\\.{x}',                      # LATIN SMALL LETTER X WITH DOT ABOVE
    chr(0x1e8e) => '\\.{Y}',                      # LATIN CAPITAL LETTER Y WITH DOT ABOVE
    chr(0x1e8f) => '\\.{y}',                      # LATIN SMALL LETTER Y WITH DOT ABOVE
    chr(0x1e90) => '\\^{Z}',                      # LATIN CAPITAL LETTER Z WITH CIRCUMFLEX
    chr(0x1e91) => '\\^{z}',                      # LATIN SMALL LETTER Z WITH CIRCUMFLEX
    chr(0x1e92) => '\\d{Z}',                      # LATIN CAPITAL LETTER Z WITH DOT BELOW
    chr(0x1e93) => '\\d{z}',                      # LATIN SMALL LETTER Z WITH DOT BELOW
    chr(0x1e94) => '\\b{Z}',                      # LATIN CAPITAL LETTER Z WITH LINE BELOW
    chr(0x1e95) => '\\b{z}',                      # LATIN SMALL LETTER Z WITH LINE BELOW
    chr(0x1e96) => '\\b{h}',                      # LATIN SMALL LETTER H WITH LINE BELOW
    chr(0x1e98) => '\\r{w}',                      # LATIN SMALL LETTER W WITH RING ABOVE
    chr(0x1e99) => '\\r{y}',                      # LATIN SMALL LETTER Y WITH RING ABOVE
    chr(0x1ea0) => '\\d{A}',                      # LATIN CAPITAL LETTER A WITH DOT BELOW
    chr(0x1ea1) => '\\d{a}',                      # LATIN SMALL LETTER A WITH DOT BELOW
    chr(0x1eb8) => '\\d{E}',                      # LATIN CAPITAL LETTER E WITH DOT BELOW
    chr(0x1eb9) => '\\d{e}',                      # LATIN SMALL LETTER E WITH DOT BELOW
    chr(0x1ebc) => '\\~{E}',                      # LATIN CAPITAL LETTER E WITH TILDE
    chr(0x1ebd) => '\\~{e}',                      # LATIN SMALL LETTER E WITH TILDE
    chr(0x1eca) => '\\d{I}',                      # LATIN CAPITAL LETTER I WITH DOT BELOW
    chr(0x1ecb) => '\\d{i}',                      # LATIN SMALL LETTER I WITH DOT BELOW
    chr(0x1ecc) => '\\d{O}',                      # LATIN CAPITAL LETTER O WITH DOT BELOW
    chr(0x1ecd) => '\\d{o}',                      # LATIN SMALL LETTER O WITH DOT BELOW
    chr(0x1ee4) => '\\d{U}',                      # LATIN CAPITAL LETTER U WITH DOT BELOW
    chr(0x1ee5) => '\\d{u}',                      # LATIN SMALL LETTER U WITH DOT BELOW
    chr(0x1ef2) => '\\`{Y}',                      # LATIN CAPITAL LETTER Y WITH GRAVE
    chr(0x1ef3) => '\\`{y}',                      # LATIN SMALL LETTER Y WITH GRAVE
    chr(0x1ef4) => '\\d{Y}',                      # LATIN CAPITAL LETTER Y WITH DOT BELOW
    chr(0x1ef5) => '\\d{y}',                      # LATIN SMALL LETTER Y WITH DOT BELOW
    chr(0x1ef8) => '\\~{Y}',                      # LATIN CAPITAL LETTER Y WITH TILDE
    chr(0x1ef9) => '\\~{y}',                      # LATIN SMALL LETTER Y WITH TILDE

    # General Punctuation

    chr(0x2002) => '\\phantom{N}',                # EN SPACE                                     (&ensp;)
    chr(0x2003) => '\\hspace{1em}',               # EM SPACE                                     (&emsp;)
    chr(0x2004) => '\\hspace{.333333em}',         # THREE-PER-EM SPACE
    chr(0x2005) => '\\hspace{.25em}',             # FOUR-PER-EM SPACE
    chr(0x2006) => '\\hspace{.166666em}',         # SIX-PER-EM SPACE
    chr(0x2007) => '\\phantom{0}',                # FIGURE SPACE
    chr(0x2008) => '\\phantom{,}',                # PUNCTUATION SPACE
    chr(0x2009) => '\\,',                         # THIN SPACE                                   (&thinsp;)
    chr(0x200a) => '\\ensuremath{\\mkern1mu}',    # HAIR SPACE
    chr(0x200c) => '{}',                          # ZERO WIDTH NON-JOINER                        (&zwnj;)
    chr(0x2013) => '--',                          # EN DASH                                      (&ndash;)
    chr(0x2014) => '---',                         # EM DASH                                      (&mdash;)
    chr(0x2015) => '\\rule{1em}{1pt}',            # HORIZONTAL BAR
    chr(0x2016) => '{\\textbardbl}',              # DOUBLE VERTICAL LINE
    chr(0x2018) => '{\\textquoteleft}',           # LEFT SINGLE QUOTATION MARK                   (&lsquo;)
    chr(0x2019) => '{\\textquoteright}',          # RIGHT SINGLE QUOTATION MARK                  (&rsquo;)
    chr(0x201a) => '{\\quotesinglbase}',          # SINGLE LOW-9 QUOTATION MARK                  (&sbquo;)
    chr(0x201c) => '{\\textquotedblleft}',        # LEFT DOUBLE QUOTATION MARK                   (&ldquo;)
    chr(0x201d) => '{\\textquotedblright}',       # RIGHT DOUBLE QUOTATION MARK                  (&rdquo;)
    chr(0x201e) => '{\\quotedblbase}',            # DOUBLE LOW-9 QUOTATION MARK                  (&bdquo;)
    chr(0x2020) => '{\\textdagger}',              # DAGGER                                       (&dagger;)
    chr(0x2021) => '{\\textdaggerdbl}',           # DOUBLE DAGGER                                (&Dagger;)
    chr(0x2022) => '{\\textbullet}',              # BULLET                                       (&bull;)
    chr(0x2026) => '{\\textellipsis}',            # HORIZONTAL ELLIPSIS                          (&hellip;)
    chr(0x2030) => '{\\textperthousand}',         # PER MILLE SIGN                               (&permil;)
    chr(0x2032) => '{\\textquotesingle}',         # PRIME                                        (&prime;)
    chr(0x2033) => '{\\textquotedbl}',            # DOUBLE PRIME                                 (&Prime;)
    chr(0x2039) => '{\\guilsinglleft}',           # SINGLE LEFT-POINTING ANGLE QUOTATION MARK    (&lsaquo;)
    chr(0x203a) => '{\\guilsinglright}',          # SINGLE RIGHT-POINTING ANGLE QUOTATION MARK   (&rsaquo;)
    chr(0x203b) => '{\\textreferencemark}',       # REFERENCE MARK
    chr(0x203d) => '{\\textinterrobang}',         # INTERROBANG
    chr(0x203e) => '{\\textasciimacron}',         # OVERLINE                                     (&oline;)
    chr(0x2044) => '{\\textfractionsolidus}',     # FRACTION SLASH                               (&frasl;)

    # Currency Symbols

    chr(0x20a1) => '{\\textcolonmonetary}',       # COLON SIGN
    chr(0x20a4) => '{\\textlira}',                # LIRA SIGN
    chr(0x20a6) => '{\\textnaira}',               # NAIRA SIGN
    chr(0x20a9) => '{\\textwon}',                 # WON SIGN
    chr(0x20ab) => '{\\textdong}',                # DONG SIGN
    chr(0x20ac) => '{\\texteuro}',                # EURO SIGN                                    (&euro;)

    # Letterlike Symbols

    chr(0x2111) => '\\ensuremath{\\Re}',          # BLACK-LETTER CAPITAL I                       (&image;)
    chr(0x2116) => '{\\textnumero}',              # NUMERO SIGN
    chr(0x2117) => '{\\textcircledP}',            # SOUND RECORDING COPYRIGHT
    chr(0x2118) => '\\ensuremath{\\wp}',          # SCRIPT CAPITAL P                             (&weierp;)
    chr(0x211c) => '\\ensuremath{\\Im}',          # BLACK-LETTER CAPITAL R                       (&real;)
    chr(0x211e) => '{\\textrecipe}',              # PRESCRIPTION TAKE
    chr(0x2120) => '{\\textservicemark}',         # SERVICE MARK
    chr(0x2122) => '{\\texttrademark}',           # TRADE MARK SIGN                              (&trade;)
    chr(0x2126) => '{\\textohm}',                 # OHM SIGN
    chr(0x2127) => '{\\textmho}',                 # INVERTED OHM SIGN
    chr(0x212e) => '{\\textestimated}',           # ESTIMATED SYMBOL
    chr(0x2190) => '{\\textleftarrow}',           # LEFTWARDS ARROW                              (&larr;)
    chr(0x2191) => '{\\textuparrow}',             # UPWARDS ARROW                                (&uarr;)
    chr(0x2192) => '{\\textrightarrow}',          # RIGHTWARDS ARROW                             (&rarr;)
    chr(0x2193) => '{\\textdownarrow}',           # DOWNWARDS ARROW                              (&darr;)
    chr(0x2194) => '\\ensuremath{\\leftrightarrow}', # LEFT RIGHT ARROW                             (&harr;)
    chr(0x21d0) => '\\ensuremath{\\Leftarrow}',   # LEFTWARDS DOUBLE ARROW                       (&lArr;)
    chr(0x21d1) => '\\ensuremath{\\Uparrow}',     # UPWARDS DOUBLE ARROW                         (&uArr;)
    chr(0x21d2) => '\\ensuremath{\\Rightarrow}',  # RIGHTWARDS DOUBLE ARROW                      (&rArr;)
    chr(0x21d3) => '\\ensuremath{\\Downarrow}',   # DOWNWARDS DOUBLE ARROW                       (&dArr;)
    chr(0x21d4) => '\\ensuremath{\\Leftrightarrow}', # LEFT RIGHT DOUBLE ARROW                      (&hArr;)

    # Mathematical Operations

    chr(0x2200) => '\\ensuremath{\\forall}',      # FOR ALL                                      (&forall;)
    chr(0x2202) => '\\ensuremath{\\partial}',     # PARTIAL DIFFERENTIAL                         (&part;)
    chr(0x2203) => '\\ensuremath{\\exists}',      # THERE EXISTS                                 (&exist;)
    chr(0x2205) => '\\ensuremath{\\emptyset}',    # EMPTY SET                                    (&empty;)
    chr(0x2207) => '\\ensuremath{\\nabla}',       # NABLA                                        (&nabla;)
    chr(0x2208) => '\\ensuremath{\\in}',          # ELEMENT OF                                   (&isin;)
    chr(0x2209) => '\\ensuremath{\\notin}',       # NOT AN ELEMENT OF                            (&notin;)
    chr(0x220b) => '\\ensuremath{\\ni}',          # CONTAINS AS MEMBER                           (&ni;)
    chr(0x220f) => '\\ensuremath{\\prod}',        # N-ARY PRODUCT                                (&prod;)
    chr(0x2211) => '\\ensuremath{\\sum}',         # N-ARY SUMMATION                              (&sum;)
    chr(0x2212) => '\\ensuremath{-}',             # MINUS SIGN                                   (&minus;)
    chr(0x2217) => '\\ensuremath{\\ast}',         # ASTERISK OPERATOR                            (&lowast;)
    chr(0x221a) => '\\ensuremath{\\surd}',        # SQUARE ROOT                                  (&radic;)
    chr(0x221d) => '\\ensuremath{\\propto}',      # PROPORTIONAL TO                              (&prop;)
    chr(0x221e) => '\\ensuremath{\\infty}',       # INFINITY                                     (&infin;)
    chr(0x2220) => '\\ensuremath{\\angle}',       # ANGLE                                        (&ang;)
    chr(0x2227) => '\\ensuremath{\\wedge}',       # LOGICAL AND                                  (&and;)
    chr(0x2228) => '\\ensuremath{\\vee}',         # LOGICAL OR                                   (&or;)
    chr(0x2229) => '\\ensuremath{\\cap}',         # INTERSECTION                                 (&cap;)
    chr(0x222a) => '\\ensuremath{\\cup}',         # UNION                                        (&cup;)
    chr(0x222b) => '\\ensuremath{\\int}',         # INTEGRAL                                     (&int;)
    chr(0x2234) => '\\ensuremath{\\therefore}',   # THEREFORE                                    (&there4;)
    chr(0x223c) => '\\ensuremath{\\sim}',         # TILDE OPERATOR                               (&sim;)
    chr(0x2245) => '\\ensuremath{\\cong}',        # APPROXIMATELY EQUAL TO                       (&cong;)
    chr(0x2248) => '\\ensuremath{\\asymp}',       # ALMOST EQUAL TO                              (&asymp;)
    chr(0x2260) => '\\ensuremath{\\neq}',         # NOT EQUAL TO                                 (&ne;)
    chr(0x2261) => '\\ensuremath{\\equiv}',       # IDENTICAL TO                                 (&equiv;)
    chr(0x2264) => '\\ensuremath{\\leq}',         # LESS-THAN OR EQUAL TO                        (&le;)
    chr(0x2265) => '\\ensuremath{\\geq}',         # GREATER-THAN OR EQUAL TO                     (&ge;)
    chr(0x2282) => '\\ensuremath{\\subset}',      # SUBSET OF                                    (&sub;)
    chr(0x2283) => '\\ensuremath{\\supset}',      # SUPERSET OF                                  (&sup;)
    chr(0x2284) => '\\ensuremath{\\not\\subset}', # NOT A SUBSET OF                              (&nsub;)
    chr(0x2286) => '\\ensuremath{\\subseteq}',    # SUBSET OF OR EQUAL TO                        (&sube;)
    chr(0x2287) => '\\ensuremath{\\supseteq}',    # SUPERSET OF OR EQUAL TO                      (&supe;)
    chr(0x2295) => '\\ensuremath{\\oplus}',       # CIRCLED PLUS                                 (&oplus;)
    chr(0x2297) => '\\ensuremath{\\otimes}',      # CIRCLED TIMES                                (&otimes;)
    chr(0x22a5) => '\\ensuremath{\\perp}',        # UP TACK                                      (&perp;)
    chr(0x22c5) => '\\ensuremath{\\cdot}',        # DOT OPERATOR                                 (&sdot;)
    chr(0x2308) => '\\ensuremath{\\lceil}',       # LEFT CEILING                                 (&lceil;)
    chr(0x2309) => '\\ensuremath{\\rceil}',       # RIGHT CEILING                                (&rceil;)
    chr(0x230a) => '\\ensuremath{\\lfloor}',      # LEFT FLOOR                                   (&lfloor;)
    chr(0x230b) => '\\ensuremath{\\rfloor}',      # RIGHT FLOOR                                  (&rfloor;)
    chr(0x2329) => '\\ensuremath{\\langle}',      # LEFT-POINTING ANGLE BRACKET                  (&lang;)
    chr(0x232a) => '\\ensuremath{\\rangle}',      # RIGHT-POINTING ANGLE BRACKET                 (&rang;)
    chr(0x25ca) => '\\ensuremath{\\lozenge}',     # LOZENGE                                      (&loz;)

    # Miscellaneous Symbols

    chr(0x263f) => '{\\Mercury}',                 # MERCURY
    chr(0x2640) => '{\\Venus}',                   # FEMALE SIGN
    chr(0x2641) => '{\\Earth}',                   # EARTH
    chr(0x2642) => '{\\Mars}',                    # MALE SIGN
    chr(0x2643) => '{\\Jupiter}',                 # JUPITER
    chr(0x2644) => '{\\Saturn}',                  # SATURN
    chr(0x2645) => '{\\Uranus}',                  # URANUS
    chr(0x2646) => '{\\Neptune}',                 # NEPTUNE
    chr(0x2647) => '{\\Pluto}',                   # PLUTO
    chr(0x2648) => '{\\Aries}',                   # ARIES
    chr(0x2649) => '{\\Taurus}',                  # TAURUS
    chr(0x264a) => '{\\Gemini}',                  # GEMINI
    chr(0x264b) => '{\\Cancer}',                  # CANCER
    chr(0x264c) => '{\\Leo}',                     # LEO
    chr(0x264d) => '{\\Virgo}',                   # VIRGO
    chr(0x264e) => '{\\Libra}',                   # LIBRA
    chr(0x264f) => '{\\Scorpio}',                 # SCORPIUS
    chr(0x2650) => '{\\Sagittarius}',             # SAGITTARIUS
    chr(0x2651) => '{\\Capricorn}',               # CAPRICORN
    chr(0x2652) => '{\\Aquarius}',                # AQUARIUS
    chr(0x2653) => '{\\Pisces}',                  # PISCES
    chr(0x2660) => '\\ensuremath{\\spadesuit}',   # BLACK SPADE SUIT                             (&spades;)
    chr(0x2663) => '\\ensuremath{\\clubsuit}',    # BLACK CLUB SUIT                              (&clubs;)
    chr(0x2665) => '\\ensuremath{\\heartsuit}',   # BLACK HEART SUIT                             (&hearts;)
    chr(0x2666) => '\\ensuremath{\\diamondsuit}', # BLACK DIAMOND SUIT                           (&diams;)
    chr(0x266d) => '\\ensuremath{\\flat}',        # MUSIC FLAT SIGN
    chr(0x266e) => '\\ensuremath{\\natural}',     # MUSIC NATURAL SIGN
    chr(0x266f) => '\\ensuremath{\\sharp}',       # MUSIC SHARP SIGN
    chr(0x26ad) => '{\\textmarried}',             # MARRIAGE SYMBOL
    chr(0x26ae) => '{\\textdivorced}',            # DIVORCE SYMBOL

    # Supplemental Punctuation

    chr(0x2e18) => '{\\textinterrobangdown}',     # INVERTED INTERROBANG
    chr(0x2e3a) => '---{}---',                    # unnamed character
    chr(0x2e3b) => '---{}---{}---',               # unnamed character

);

%provided_by = (

    chr(0x0022) => 'textcomp',    # QUOTATION MARK
    chr(0x003c) => 'textcomp',    # LESS-THAN SIGN
    chr(0x003e) => 'textcomp',    # GREATER-THAN SIGN
    chr(0x005c) => 'textcomp',    # REVERSE SOLIDUS
    chr(0x007e) => 'textcomp',    # TILDE
    chr(0x0e3f) => 'textcomp',    # THAI CURRENCY SYMBOL BAHT
    chr(0x2016) => 'textcomp',    # DOUBLE VERTICAL LINE
    chr(0x203b) => 'textcomp',    # REFERENCE MARK
    chr(0x203d) => 'textcomp',    # INTERROBANG
    chr(0x20a1) => 'textcomp',    # COLON SIGN
    chr(0x20a4) => 'textcomp',    # LIRA SIGN
    chr(0x20a6) => 'textcomp',    # NAIRA SIGN
    chr(0x20a9) => 'textcomp',    # WON SIGN
    chr(0x20ab) => 'textcomp',    # DONG SIGN
    chr(0x2116) => 'textcomp',    # NUMERO SIGN
    chr(0x2117) => 'textcomp',    # SOUND RECORDING COPYRIGHT
    chr(0x211e) => 'textcomp',    # PRESCRIPTION TAKE
    chr(0x2120) => 'textcomp',    # SERVICE MARK
    chr(0x2126) => 'textcomp',    # OHM SIGN
    chr(0x2127) => 'textcomp',    # INVERTED OHM SIGN
    chr(0x212e) => 'textcomp',    # ESTIMATED SYMBOL
    chr(0x263f) => 'marvosym',    # MERCURY
    chr(0x2640) => 'marvosym',    # FEMALE SIGN
    chr(0x2641) => 'marvosym',    # EARTH
    chr(0x2642) => 'marvosym',    # MALE SIGN
    chr(0x2643) => 'marvosym',    # JUPITER
    chr(0x2644) => 'marvosym',    # SATURN
    chr(0x2645) => 'marvosym',    # URANUS
    chr(0x2646) => 'marvosym',    # NEPTUNE
    chr(0x2647) => 'marvosym',    # PLUTO
    chr(0x2648) => 'marvosym',    # ARIES
    chr(0x2649) => 'marvosym',    # TAURUS
    chr(0x264a) => 'marvosym',    # GEMINI
    chr(0x264b) => 'marvosym',    # CANCER
    chr(0x264c) => 'marvosym',    # LEO
    chr(0x264d) => 'marvosym',    # VIRGO
    chr(0x264e) => 'marvosym',    # LIBRA
    chr(0x264f) => 'marvosym',    # SCORPIUS
    chr(0x2650) => 'marvosym',    # SAGITTARIUS
    chr(0x2651) => 'marvosym',    # CAPRICORN
    chr(0x2652) => 'marvosym',    # AQUARIUS
    chr(0x2653) => 'marvosym',    # PISCES
    chr(0x26ad) => 'textcomp',    # MARRIAGE SYMBOL
    chr(0x26ae) => 'textcomp',    # DIVORCE SYMBOL
    chr(0x2e18) => 'textcomp',    # INVERTED INTERROBANG

);

reset_latex_encodings(1);

sub _compile_encoding_regexp {
    $encoded_char_re = join q{}, sort keys %latex_encoding;
    $encoded_char_re =~ s{ ([#\[\]\\\$]) }{\\$1}gmsx;
    $encoded_char_re = eval "qr{[$encoded_char_re]}x";
    return;
}

_compile_encoding_regexp;


1;

__END__

=head1 NAME

LaTeX::Encode - encode characters for LaTeX formatting

=head1 SYNOPSIS

  use LaTeX::Encode ':all', add => { '@' => 'AT' }, remove => [ '$' ];

  $latex_string  = latex_encode($text, %options);

  %old_encodings = add_latex_encodings( chr(0x2002) => '\\hspace{.6em}' );
  %old_encodings = remove_latex_encodings( '<', '>' );

  reset_latex_encodings(1);

=head1 VERSION

This manual page describes version 0.091.5 of the C<LaTeX::Encode> module.


=head1 DESCRIPTION

This module provides a function to encode text that is to be formatted
with LaTeX.  It encodes characters that are special to LaTeX or that
are represented in LaTeX by LaTeX text-mode commands.

The special characters are: C<\> (command character), C<{> (open
group), C<}> (end group), C<&> (table column separator), C<#>
(parameter specifier), C<%> (comment character), C<_> (subscript),
C<^> (superscript), C<~> (non-breakable space), C<$> (mathematics mode).

Note that some of the LaTeX commands for characters are defined in the
LaTeX C<textcomp> package.  If your text includes such characters, you
will need to include the following lines in the preamble to your LaTeX
document.

    \usepackage[T1]{fontenc}
    \usepackage{textcomp}

The function is useful for encoding data that is interpolated into
LaTeX document templates, say with C<Template::Plugin::Latex>
(shameless plug!).

=head1 WARNING ABOUT UTF-8 DATA

Note that C<latex_encode()> will encode a UTF8 string (a string with the UTF8 flag set) or
a non-UTF8 string, which will normally be regarded as ISO-8859-1 (Latin 1) and will be
upgraded to UTF8.  The UTF8 flag indicates whether the contents of a string are regarded
as a sequence of Unicode characters or as a string of bytes.  Refer to the L<Unicode
Support in Perl|perlunicode>, L<Perl Unicode Introduction|perluniintro> and L<Perl Unicode
Tutorial|perlunitut> manual pages for more details.

If you are seeing spurious LaTeX commands in the output of C<latex_encode()> then it may
be that you are reading from a UTF-8 input or have data with UTF-8 characters in a literal
but the UTF8 flag is not being set correctly.  The fact that your programs are dealing
with UTF-8 characters on a byte-by-byte basis may not be apparent normally as the terminal
may make no distinction and happily display the byte sequence in the program's output as
the UTF-8 characters they represent, however in a Perl program that deals with individual
characters, what happens is that the individual bytes that make up multi-byte characters
are regarded as separate characters; if the strings are promoted to UTF8 strings then the
individual bytes are converted separately to UTF8.  This is termed double encoding.
C<latex_encode()> will then map the double-encoded characters.

If the input text is Western European text then what you are likely to see in the output
from C<latex_encode()> is spurious sequences of C<{\^A}> or C<{\~A}> followed by the
mapping of an apparently random character (or the right character if it is a symbol such
as the Sterling POUND sign, i.e. "£" will map to C<{\^A}\textsterling>); this is because
the initial byte of a two-byte UTF-8 character in the LATIN1 range will either be 0xC2 or
0xC3 and the next byte will always have the top two bits set to C<10> to indicate that it
is a continuation byte.


=head1 SUBROUTINES/METHODS

=over 4

=item C<latex_encode($text, %options)>

Encodes the specified text such that it is suitable for processing
with LaTeX.  The behaviour of the filter is modified by the options:

=over 4

=item C<except>

Lists the characters that should be excluded from encoding.  By
default no special characters are excluded, but it may be useful to
specify C<except = "\\{}"> to allow the input string to contain LaTeX
commands such as C<"this is \\textbf{bold} text"> (the doubled
backslashes in the strings represent Perl escapes, and will be
evaluated to single backslashes).

=item C<iquotes>

If true then single or double quotes around words will be changed to
LaTeX single or double quotes; double quotes around a phrase will be
converted to "``" and "''" and single quotes to "`" and "'".  This is
sometimes called "intelligent quotes"

=item C<packages>

If passed a reference to a hash C<latex_encode()> will update the hash with names of LaTeX
packages that are required for typesetting the encoded string.

=back


=item C<add_latex_encodings(%encodings)>

Adds a set of new or modified encodings.  Returns a hash of any encodings that were
modified.


=item C<remove_latex_encodings(@keys)>

Removes a set of encodings.  Returns a hash of the removed encodings.


=item C<reset_latex_encodings($forget_import_specifiers)>

Resets the LaTeX encodings to the state that they were when the module was loaded
(including any additions and removals specified on the 'use' statement), or to the
standard set of encodings if C<$forget_import_specifiers> is true.


=back


=head1 EXAMPLES

The following snippet shows how data from a database can be encoded
and inserted into a LaTeX table, the source of which is generated with
C<LaTeX::Table>.

    my $sth = $dbh->prepare('select col1, col2, col3 from table where $expr');
    $sth->execute;
    while (my $href = $sth->fetchrow_hashref) {
        my @row;
        foreach my $col (qw(col1 col2 col3)) {
            push(@row, latex_encode($href->{$col}));
        }
        push @data, \@row;
    }

    my $headings = [ [ 'Col1', 'Col2', 'Col3' ] ];

    my $table = LaTeX::Table->new( { caption => 'My caption',
                                     label   => 'table:caption',
                                     type    => 'xtab',
                                     header  => $header,
                                     data    => \@data } );

    my $table_text = $table->generate_string;    

Now C<$table_text> can be interpolated into a LaTeX document template.


=head1 DIAGNOSTICS

None.  You could probably break the C<latex_encode> function by
passing it an array reference as the options, but there are no checks
for that.

=head1 CONFIGURATION AND ENVIRONMENT

Not applicable.


=head1 DEPENDENCIES

The C<HTML::Entities> and C<Pod::LaTeX> modules were used for building
the encoding table but this is not
rebuilt at installation time.  The C<LaTeX::Driver> module is used for
formatting the character encodings reference document.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

Not all LaTeX special characters are included in the encoding tables
(more may be added when I track down the definitions).



=head1 AUTHOR

Andrew Ford E<lt>a.ford@ford-mason.co.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2012 Andrew Ford.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This software is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Template::Plugin::Latex>

L<Unicode Support in Perl|perlunicode>

L<Perl Unicode Introduction|perluniintro>

L<Perl Unicode Tutorial|perlunitut>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
