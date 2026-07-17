package Encode::Wide;

# TODO: don't transform anything within <script>...</script> in wide_to_html

use strict;
use warnings;

use Carp qw(croak carp confess);
use Exporter qw(import);
use HTML::Entities;
use Params::Get 0.13;

our @EXPORT_OK = qw(wide_to_html wide_to_xml);

# HTML::Entities::decode does not handle these four named entities, so we
# decode them ourselves.  The regex is built once at compile time: longest
# key first to avoid partial-match ambiguity (e.g. &Scaron; before &s...).
my %_EXTRA_ENTITY_MAP = (
	'&ccaron;' => "\x{010D}",	# c with caron
	'&zcaron;' => "\x{017E}",	# z with caron
	'&Zcaron;' => "\x{017D}",	# Z with caron
	'&Scaron;' => "\x{0160}",	# S with caron
);
my $_EXTRA_ENTITY_RE = do {
	my $pat = join '|', map { quotemeta }
		sort { length($b) <=> length($a) } keys %_EXTRA_ENTITY_MAP;
	qr/$pat/;
};

# Module-level HTML escape map eliminates the /e eval flag in keep_hrefs substitutions
my %_HTML_ESCAPE = ( '<' => '&lt;', '>' => '&gt;', '"' => '&quot;' );

# Encode to HTML whatever the non-ASCII encoding scheme has been chosen
# Can't use HTML:Entities::encode since that doesn't seem to cope with
#	all encodings and misses some characters
#
# See https://www.compart.com/en/unicode/U+0161 etc.
#	https://www.compart.com/en/unicode/U+00EB
#
# keep_hrefs => 1 means ensure hyperlinks still work
# keep_apos => 1 means keep apostrophes, useful within <script>

=head1 NAME

Encode::Wide - Convert wide characters (Unicode, UTF-8, etc.) into ASCII-safe HTML or XML entities

=head1 VERSION

0.07

=cut

our $VERSION = 0.07;

=encoding UTF-8

=head1 SYNOPSIS

    use Encode::Wide qw(wide_to_html wide_to_xml);

    # Basic HTML conversion
    my $html = wide_to_html(string => "Cafe\x{E9} d\x{E9}j\x{E0} vu");
    # => 'Caf&eacute; d&eacute;j&agrave; vu'

    # Basic XML conversion (numeric entities, en-dash folded to hyphen)
    my $xml = wide_to_xml(string => "Cafe\x{E9} \x{2013} na\x{EF}ve");
    # => 'Caf&#x0E9; - na&#x0EF;ve'

    # Preserve embedded HTML markup (keep_hrefs)
    my $linked = wide_to_html(
        string     => '<a href="/menu">Caf\x{E9}</a>',
        keep_hrefs => 1,
    );
    # => '<a href="/menu">Caf&eacute;</a>'

    # Keep apostrophes literal for JavaScript contexts (keep_apos)
    my $js_safe = wide_to_html(
        string    => "it\x{2019}s na\x{EF}ve",
        keep_apos => 1,
    );
    # => "it\x{2019}s na&iuml;ve"   (curly apostrophe kept; i-umlaut encoded)

    # Get notified about unhandled characters instead of dying silently
    my $out = wide_to_html(
        string   => $untrusted,
        complain => sub { warn "Unhandled: $_[0]" },
    );

    # Accept a scalar reference
    my $text = "na\x{EF}ve";
    my $safe = wide_to_html(string => \$text);
    # => 'na&iuml;ve'

=head1 DESCRIPTION

Encode::Wide converts strings that contain non-ASCII (wide) characters into
pure 7-bit ASCII output suitable for embedding in HTML pages or XML documents.
Every non-ASCII codepoint is replaced by the appropriate entity reference so
the output can be safely placed in HTML attributes, HTML body text, or XML
element content without triggering encoding errors or security issues.

=head2 Why use this module?

L<HTML::Entities> is the obvious alternative for HTML, but it makes strict
assumptions about input encoding that cause silent failures when the input
arrives as raw UTF-8 bytes, already-partially-encoded entities, or a mix of
both.  Encode::Wide handles all three representations through a multi-pass
pipeline and falls back to L<HTML::Entities> numeric encoding for any
character not explicitly listed in its tables.

For XML, L<XML::Entities> works in the opposite direction (decoding entities,
not encoding them).  Encode::Wide fills that gap.

=head2 Input

Both functions accept:

=over 4

=item *

A B<Perl Unicode string> (the internal C<utf8> flag is set) - the normal case
when input comes from L<Encode/decode>, a database driver with C<pg_enable_utf8>,
or a source file declared C<use utf8>.

=item *

A B<raw UTF-8 byte string> - the common case when input arrives from a legacy
web form or an older database driver without automatic decoding.  The pipeline's
raw-byte substitution pass handles this transparently.

=item *

A B<scalar reference> - C<wide_to_html(string =E<gt> \$var)>.  The string is
read from the referent; the referent is not modified.

=item *

B<Already-encoded HTML entities> - e.g. C<&eacute;> or C<&lt;>.
By default the pipeline decodes these first so they are not double-encoded.
Pass C<keep_hrefs =E<gt> 1> to suppress decoding when the input contains
trusted HTML that must pass through unchanged.

=back

=head2 Output

Both functions return a B<defined scalar string> containing B<only ASCII
characters> (code points 0x00-0x7F).  The output is safe to concatenate
directly into an HTML or XML document without further escaping.

=head2 Choosing between the two functions

Use C<wide_to_html> when writing into an HTML context (C<< <p> >>, C<< <td> >>,
attribute values, etc.).  Named entities such as C<&eacute;> and C<&ndash;>
are used wherever possible; they are compact and human-readable in the source.

Use C<wide_to_xml> when writing into an XML context (XHTML, RSS, Atom, custom
XML schemas).  Named HTML entities other than the five predefined XML entities
(C<&amp;> C<&lt;> C<&gt;> C<&apos;> C<&quot;>) are not valid in XML.
This function uses only hexadecimal numeric entities (C<&#x0E9;>), which are
valid in all XML 1.0 processors.  Em-dashes and en-dashes are folded to a
plain ASCII hyphen because many XML consumers normalise whitespace and
punctuation anyway.

=head1 EXPORT

Nothing is exported by default.  Import the functions you need explicitly:

    use Encode::Wide qw(wide_to_html);          # one function
    use Encode::Wide qw(wide_to_html wide_to_xml);  # both

=head1 COMMON PARAMETERS

Both functions accept the following named parameters in addition to C<string>.
Pass them as a flat key-value list:

    wide_to_html(string => $text, keep_hrefs => 1, complain => \&handler);

=over 4

=item C<string> (required)

The text to encode.  May be a plain scalar or a B<reference to a scalar>.
Must be defined; passing C<undef> causes the function to C<croak> with a
usage message.

=item C<keep_hrefs> (optional, default 0)

When true, angle brackets (C<< < >>, C<< > >>) and double-quotes (C<">) are
B<not> escaped, allowing embedded HTML or XML markup to survive intact.

B<Security note:> when C<keep_hrefs> is set, entity-decoding is also
suppressed.  Without this suppression, an encoded payload such as
C<&lt;script&gt;> would be decoded to C<< <script> >> and then pass through
unescaped, creating an XSS vector.  With C<keep_hrefs =E<gt> 1> it is the
B<caller's responsibility> to ensure that the input does not contain untrusted
content that could be exploited.

=item C<complain> (optional)

A code reference called with a diagnostic string when the pipeline encounters a
character it cannot encode.  The function still C<croak>s with a C<BUG:>
prefix after invoking the callback - C<complain> is for logging, not recovery.

    wide_to_html(
        string   => $text,
        complain => sub {
            my ($msg) = @_;
            warn "Encode::Wide gap: $msg";
        },
    );

=back

=head2 wide_to_html

Convert a Unicode or UTF-8 string into a pure-ASCII HTML fragment.  Every
non-ASCII character is replaced by its named HTML entity (e.g. C<&eacute;>)
where one exists, or a hexadecimal numeric entity (e.g. C<&#xNNNN;>) otherwise.
Bare ampersands, angle brackets, and double-quotes are also escaped so the
result is safe to embed in HTML body text or attribute values without further
processing.

=head3 Arguments

All parameters are passed as a flat key-value list.  The C<string> key may be
omitted when passing a bare positional string as the first argument.

See L</COMMON PARAMETERS> for C<string>, C<keep_hrefs>, and C<complain>.

=over 4

=item C<keep_apos> (optional, default 0)

When true, apostrophes and their typographic variants (curly single quotes
U+2018, U+2019; grave accent U+0060; Windows-1252 byte 0x98) are B<not>
converted to C<&apos;>.  Useful when the result will be embedded inside a
JavaScript string literal where C<&apos;> is not valid syntax.

=back

=head3 Returns

A defined scalar string whose every character is in the ASCII range
(code points 0x00-0x7F).  The empty string is returned unchanged.

=head3 EXAMPLE

    use Encode::Wide qw(wide_to_html);

    # Accented characters to named entities
    my $out = wide_to_html(string => "na\x{EF}ve caf\x{E9}");
    # => 'na&iuml;ve caf&eacute;'

    # Ampersands and angle brackets are escaped
    $out = wide_to_html(string => 'Price < 100 & cost > 0');
    # => 'Price &lt; 100 &amp; cost &gt; 0'

    # Existing entities are decoded then re-encoded (no double-encoding)
    $out = wide_to_html(string => '&eacute;');
    # => '&eacute;'

    # keep_hrefs: HTML markup passes through; only wide chars are encoded
    $out = wide_to_html(
        string     => '<a href="/m\x{E9}nu">Men\x{FC}</a>',
        keep_hrefs => 1,
    );
    # => '<a href="/m&eacute;nu">Men&uuml;</a>'

    # keep_apos: apostrophes kept for JavaScript contexts
    $out = wide_to_html(
        string    => "it\x{2019}s clich\x{E9}",
        keep_apos => 1,
    );
    # => "it\x{2019}s clich&eacute;"

    # Scalar reference input
    my $text = "caf\x{E9}";
    $out = wide_to_html(string => \$text);
    # => 'caf&eacute;'

=head3 MESSAGES

=over 4

=item C<Usage: wide_to_html() string not set>

B<Fatal> (via C<croak>).  The C<string> parameter was C<undef>.
Resolution: pass a defined scalar or scalar reference.

=item C<TODO: wide_to_html(E<lt>hex-tokens...E<gt>)>

B<Warning> (via C<carp>).  A character survived all three byte_map passes and
the C<encode_entities_numeric> fallback.  The hex tokens in the message
identify the unhandled codepoint(s).
Resolution: add the character to the appropriate byte_map array, or file a bug
report at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Encode-Wide>.

=item C<BUG: wide_to_html(E<lt>hex-tokens...E<gt>)>

B<Fatal> (via C<croak>), always preceded by the C<TODO> warning above.
The same unhandled-character condition caused a hard failure.  This should
never occur in normal use; it indicates a gap in the character tables.

=back

=head3 API SPECIFICATION

=head4 Input

    {
        string     => { type => SCALAR | SCALARREF, required => 1, defined => 1 },
        keep_hrefs => { type => BOOLEAN, optional => 1, default => 0 },
        keep_apos  => { type => BOOLEAN, optional => 1, default => 0 },
        complain   => { type => CODEREF,  optional => 1 },
    }

=head4 Output

    { type => SCALAR, constraint => sub { $_[0] !~ /[^[:ascii:]]/ } }

=head3 PSEUDOCODE

    1. Unless keep_hrefs: decode HTML entities via HTML::Entities::decode
       and the four extra named entities (&ccaron; &zcaron; &Zcaron; &Scaron;)
    2. Escape bare & not followed by a valid entity name
       (possessive ++ quantifier prevents ReDoS backtracking)
    3. Unless keep_hrefs: escape <, >, and " using %_HTML_ESCAPE (no /e eval)
    4. First byte_map pass: typographic punctuation and exclamation mark
    5. Unless keep_apos: encode apostrophe variants to &apos;
       using an alternation regex built from the apostrophe key set
    6. Early return if the string is now pure ASCII
    7. Second byte_map pass: raw UTF-8 byte sequences -> named HTML entities
    8. Third byte_map pass: Perl Unicode chars (\N{U+...}) -> named HTML entities
    9. Fallback: HTML::Entities::encode_entities_numeric for any remaining
       non-ASCII codepoints
   10. If non-ASCII still remains after the fallback: invoke complain callback,
       carp a TODO warning, then croak a BUG error

=cut

sub wide_to_html
{
	my $params = Params::Get::get_params('string', @_);

	my $string = $params->{'string'};
	my $complain = $params->{'complain'};

	if(!defined($string)) {
		croak 'Usage: wide_to_html() string not set';
	}

	if(ref($string) eq 'SCALAR') {
		$string = ${$string};
	}


	# SECURITY: skip entity-decoding when keep_hrefs is set.  Calling
	# HTML::Entities::decode before the keep_hrefs gate converts encoded
	# payloads like &lt;script&gt; to raw <script>, which then bypass
	# re-escaping and produce XSS output.  When the caller asserts the input
	# contains trusted HTML (keep_hrefs => 1) we treat the text as-is and
	# only encode wide characters; entity-normalisation is then the caller's
	# responsibility.
	unless($params->{'keep_hrefs'}) {
		$string = HTML::Entities::decode($string);

		# Decode the four named entities HTML::Entities::decode misses
		$string =~ s/($_EXTRA_ENTITY_RE)/$_EXTRA_ENTITY_MAP{$1}/g;
	}

	# Escape bare & not already part of a valid entity.
	# Possessive ++ on the char class prevents O(n^2) backtracking (ReDoS)
	# when the input contains & not followed by a semicolon-terminated name.
	$string =~ s/&(?![A-Za-z#0-9]++;)/&amp;/g;

	unless($params->{'keep_hrefs'}) {
		# Escape the three characters that break HTML attribute or body contexts.
		# Module-level %_HTML_ESCAPE eliminates the /e eval flag.
		$string =~ s/([<>"])/$_HTML_ESCAPE{$1}/g;
	}

	# $string =~ s/&db=/&amp;db=/g;
	# $string =~ s/&id=/&amp;id=/g;

	# Table of byte-sequences->entities
	my @byte_map = (
		['“', '&quot;'],	# U+201C
		['”', '&quot;'],	# U+201D
		["\xe2\x80\x9c", '&quot;'],	# “
		["\xe2\x80\x9d", '&quot;'],	# ”
		["\xe2\x80\x93", '&ndash;'],
		["\xe2\x80\x94", '&mdash;'],
		["\xe2\x80\x98", '&apos;'],	# ‘
		["\xe2\x80\x99", '&apos;'],	# ’
		["\xe2\x80\xA6", '...'],	# …
		['!', '&excl;'],	# Do this early before the ascii check, since it's an ascii character
	);

	$string = _sub_map(\$string, \@byte_map);

	unless($params->{'keep_apos'}) {
		# Multi-byte curly apostrophes can’t be combined in a char-class, so use
		# an alternation regex built from the key set — no /e eval needed.
		my %apos_map = (
			"'"            => '&apos;',
			"\x{2018}" => '&apos;',	# U+2018 left single quotation mark
			"\x{2019}" => '&apos;',	# U+2019 right single quotation mark
			"\x{0060}" => '&apos;',	# U+0060 grave accent used as apostrophe
			"\x98"     => '&apos;',
		);
		my $apos_re = join '|', map { quotemeta } keys %apos_map;
		$string =~ s/($apos_re)/$apos_map{$1}/g;
	}

	if($string !~ /[^[:ascii:]]/) {
		return $string;
	}

	@byte_map = (
		["\xc2\xa0", ' '],	# Non breaking space
		["\xc2\xa3", '&pound;'],
		["\xc2\xa9", '&copy;'],
		["\xc2\xae", '&reg;'],
		["\xc3\xa2", '&acirc;'],
		["\xc3\xa4", '&auml;'],
		["\xc3\xa9", '&eacute;'],
		["\xc2\xaa", '&ordf;'],	# ª
		["\xc2\xab", '&quot;'],	# «
		["\xc2\xbb", '&quot;'],	# »
		["\xc3\x81", '&Aacute;'],	# Á
		["\xc3\x83", '&Icirc;'],	# Î
		["\xc3\x9e", '&THORN;'],	# Þ
		["\xc3\xa0", '&agrave;'],	# à
		["\xc3\xa1", '&aacute;'],	# á
		["\xc3\xad", '&iacute;'],	# í
		["\xc3\xb0", '&eth;'],	# ð
		["\xc3\xba", '&uacute;'],	# ú
		["\xc3\xb4", '&ocirc;'],	# ô
		["\xc3\xb6", '&ouml;'],
		["\xc3\xb8", '&oslash;'],	# ø
		["\xc5\xa1", '&scaron;'],
		["\xc4\x8d", '&ccaron;'],
		["\xc5\xbd", '&Zcaron;'],
		["\xc5\xbe", '&zcaron;'],
		["\xc3\xa5", '&aring;'],	# å
		["\xc3\xa7", '&ccedil;'],
		["\xc3\xaf", '&iuml;'],	# ï
		["\xc3\xb3", '&oacute;'],
		["\xc3\x96", '&Ouml;'], # Ö
		["\xc3\xa8", '&egrave;'],
		["\xc3\x89", '&Eacute;'],
		["\xc3\x9f", '&szlig;'],
		["\xc3\xaa", '&ecirc;'],
		["\xc3\xab", '&euml;'],
		["\xc3\xae", '&icirc;'],
		["\xc3\xbb", '&ucirc;'],
		["\xc3\xbc", '&uuml;'], # ü
		["\xc3\xbe", '&thorn;'],	# þ
		["\xc5\x9b", '&sacute;'],
		["\xc5\xa0", '&Scaron;'],
		["\xe2\x80\x93", '&ndash;'],
		["\xe2\x80\x94", '&mdash;'],
		["\xc3\xb1", '&ntilde;'],	# ñ
		["\xe2\x80\x9c", '&quot;'],
		["\xe2\x80\x9d", '&quot;'],
		["\xe2\x80\xa6", '...'],
		["\xe2\x97\x8f", '&#x25CF;'],	# ●
		["\N{U+00A0}", ' '],
		["\N{U+00A3}", '&pound;'],
		["\N{U+00A9}", '&copy;'],
		["\N{U+00AA}", '&ordf;'],	# ª
		["\N{U+00AB}", '&quot;'],	# «
		["\N{U+00AE}", '&reg;'],
		["\N{U+00B5}", '&micro;'],	# µ
		["\N{U+00BB}", '&quot;'],	# »
		["\N{U+00CE}", '&Icirc;'],	# Î
		["\N{U+00DE}", '&THORN;'],	# Þ
		["\N{U+0161}", '&scaron;'],
		["\N{U+010D}", '&ccaron;'],
		["\N{U+017D}", '&Zcaron;'],
		["\N{U+017E}", '&zcaron;'],
		["\N{U+00C9}", '&Eacute;'],
		["\N{U+00D6}", '&Ouml;'],	# Ö
		["\N{U+00DF}", '&szlig;'],	# ß
		["\N{U+00E1}", '&aacute;'],	# á
		["\N{U+00E2}", '&acirc;'],
		["\N{U+00E4}", '&auml;'],
		["\N{U+00E5}", '&aring;'],	# å
		["\N{U+00E0}", '&agrave;'],	# à
		["\N{U+00E7}", '&ccedil;'],	# ç
		["\N{U+00E8}", '&egrave;'],
		["\N{U+00E9}", '&eacute;'],
		["\N{U+00ED}", '&iacute;'],	# í
		["\N{U+00EE}", '&icirc;'],
		["\N{U+00EF}", '&iuml;'],	# ï
		["\N{U+00F0}", '&eth;'],	# ð
		["\N{U+00F1}", '&ntilde;'],	# ñ
		["\N{U+00F4}", '&ocirc;'],	# ô
		["\N{U+00F6}", '&ouml;'],
		["\N{U+00F8}", '&oslash;'],	# ø
		["\N{U+00FA}", '&uacute;'],	# ú
		["\N{U+00FC}", '&uuml;'],	# ü
		["\N{U+00FE}", '&thorn;'],	# þ
		["\N{U+00C1}", '&Aacute;'],	# Á
		["\N{U+00C9}", '&Eacute;'],
		["\N{U+00CA}", '&ecirc;'],
		["\N{U+00EB}", '&euml;'],
		["\N{U+00F3}", '&oacute;'],
		["\N{U+015B}", '&sacute;'],
		["\N{U+00FB}", '&ucirc;'],
		["\N{U+0160}", '&Scaron;'],
		["\N{U+2013}", '&ndash;'],
		["\N{U+2014}", '&mdash;'],
		["\N{U+2018}", '&quot;'],
		["\N{U+2019}", '&quot;'],
		["\N{U+201C}", '&quot;'],
		["\N{U+201D}", '&quot;'],
		["\N{U+2026}", '...'],	# …
		["\N{U+2122}", '&trade;'],	# ™
		["\xe2\x84\xa2", '&trade;'],	# ™ UTF-8
		["\N{U+25CF}", '&#x25CF;'],	# ●
	);

	$string = _sub_map(\$string, \@byte_map);


	@byte_map = (
		[ 'Á', '&Aacute;' ],
		[ 'å', '&aring;' ],
		[ 'ª', '&ordf;' ],
		[ 'š', '&scaron;' ],
		[ 'Š', '&Scaron;' ],
		[ 'č', '&ccaron;' ],
		[ 'Ž', '&Zcaron;' ],
		[ 'ž', '&zcaron;' ],
		[ 'à', '&agrave;' ],	# à
		[ 'á', '&aacute;' ],
		[ 'â', '&acirc;' ],
		[ 'é', '&eacute;' ],
		[ 'è', '&egrave;' ],
		[ 'ç', '&ccedil;' ],
		[ 'ê', '&ecirc;' ],
		[ 'ë', '&euml;' ],
		[ 'ð', '&eth;' ],
		[ 'í', '&iacute;' ],
		[ 'ï', '&iuml;' ],
		[ 'Î', '&Icirc;' ],
		[ '©', '&copy;' ],
		[ '®', '&reg;' ],
		[ 'ó', '&oacute;' ],
		[ 'ô', '&ocirc;' ],
		[ 'ö', '&ouml;' ],
		[ 'ø', '&oslash;' ],
		[ 'ś', '&sacute;' ],
		[ 'Þ', '&THORN;' ],
		[ 'þ', '&thorn;' ],
		[ 'û', '&ucirc;' ],
		[ 'ü', '&uuml;' ],
		[ 'ú', '&uacute;' ],
		[ 'µ', '&micro;'],
		[ '£', '&pound;' ],
		[ 'ß', '&szlig;' ],
		[ '–', '&ndash;' ],
		[ '—', '&mdash;' ],
		[ 'ñ', '&ntilde;' ],
		[ '“', '&quot;' ],
		[ '”', '&quot;' ],
		[ '«', '&quot;' ],
		[ '»', '&quot;' ],
		[ '…', '...' ],
		[ '™', '&trade;' ],
		[ '●', '&#x25CF;' ],
		[ "\x80\$", ' ' ],
	);

	$string = _sub_map(\$string, \@byte_map);

	if($string =~ /[^[:ascii:]]/) {
		$string = HTML::Entities::encode_entities_numeric($string, '\x80-\x{10FFFF}');
		if($string =~ /[^[:ascii:]]/) {
			$complain->("TODO: wide_to_html($string)") if($complain);
			# Sanitize non-ASCII to hex tokens before embedding in the error message
			$string =~ s{
					([^[:ascii:]])
				}{
					'>>>>' . sprintf('%04X', ord($1)) . '<<<<'
				}gex;
			carp "TODO: wide_to_html($string)";
			croak "BUG: wide_to_html($string)";
		}
	}

	return $string;
}

=head2 wide_to_xml

Convert a Unicode or UTF-8 string into a pure-ASCII XML fragment.  Every
non-ASCII character is replaced by a hexadecimal numeric entity
(e.g. C<&#x0E9;>).  Only numeric entities are used because named HTML entities
such as C<&eacute;> are not defined in XML 1.0 outside of XHTML with a DTD.
Em-dashes and en-dashes are folded to a plain ASCII hyphen C<->.
Bare ampersands, angle brackets, and double-quotes are escaped so the output
is valid XML element content.

=head3 Arguments

All parameters are passed as a flat key-value list.  The C<string> key may be
omitted when passing a bare positional string as the first argument.

See L</COMMON PARAMETERS> for C<string>, C<keep_hrefs>, and C<complain>.
This function does not accept C<keep_apos>.

=head3 Returns

A defined scalar string whose every character is in the ASCII range
(code points 0x00-0x7F).  The empty string is returned unchanged.

=head3 EXAMPLE

    use Encode::Wide qw(wide_to_xml);

    # Accented characters become numeric entities
    my $out = wide_to_xml(string => "SURN \x{017D}ganjar");
    # => 'SURN &#x17D;ganjar'

    # En-dash and em-dash are folded to a plain hyphen
    $out = wide_to_xml(string => "2020\x{2013}2026");
    # => '2020-2026'

    # Ampersands and angle brackets are XML-escaped
    $out = wide_to_xml(string => 'a < b & c > 0');
    # => 'a &lt; b &amp; c &gt; 0'

    # keep_hrefs: XML tags pass through; wide chars are still encoded
    $out = wide_to_xml(
        string     => '<item lang="fr">Caf\x{E9}</item>',
        keep_hrefs => 1,
    );
    # => '<item lang="fr">Caf&#x0E9;</item>'

    # Scalar reference input
    my $text = "caf\x{E9}";
    $out = wide_to_xml(string => \$text);
    # => 'caf&#x0E9;'

=head3 MESSAGES

=over 4

=item C<Usage: wide_to_xml() string not set>

B<Fatal> (via C<croak>).  The C<string> parameter was C<undef>.
Resolution: pass a defined scalar or scalar reference.

=item C<TODO: wide_to_xml(E<lt>hex-tokens...E<gt>)>

B<Warning> (via C<carp>).  A character survived all three byte_map passes.
The hex tokens in the message identify the unhandled codepoint(s).
Resolution: add the character to the appropriate byte_map array, or file a bug
report at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Encode-Wide>.

=item C<BUG: wide_to_xml(E<lt>hex-tokens...E<gt>)>

B<Fatal> (via C<croak>), always preceded by the C<TODO> warning above.
This should never occur in normal use; it indicates a gap in the XML character
tables.  Unlike C<wide_to_html>, there is no numeric-entity fallback for XML
because there is no safe generic fallback that is valid in all XML contexts.

=back

=head3 API SPECIFICATION

=head4 Input

    {
        string     => { type => SCALAR | SCALARREF, required => 1, defined => 1 },
        keep_hrefs => { type => BOOLEAN, optional => 1, default => 0 },
        complain   => { type => CODEREF,  optional => 1 },
    }

=head4 Output

    { type => SCALAR, constraint => sub { $_[0] !~ /[^[:ascii:]]/ } }

=head3 PSEUDOCODE

    1. Unless keep_hrefs: decode HTML entities via HTML::Entities::decode
       and the four extra named entities (&ccaron; &zcaron; &Zcaron; &Scaron;)
    2. Escape bare & not followed by a valid entity name
       (possessive ++ quantifier prevents ReDoS backtracking)
    3. Unless keep_hrefs: escape <, >, and " using %_HTML_ESCAPE (no /e eval)
    4. First byte_map pass: curly quotes -> &quot;, dashes -> -, apostrophes
    5. Early return if the string is now pure ASCII
    6. Second byte_map pass: raw UTF-8 byte sequences -> numeric XML entities
    7. Third byte_map pass: Perl Unicode chars (\N{U+...}) -> numeric XML entities
    8. If non-ASCII still remains: invoke complain callback, carp a TODO warning,
       then croak a BUG error

=cut

# See https://www.compart.com/en/unicode/U+0161 etc.
#	https://www.compart.com/en/unicode/U+00EB
sub wide_to_xml
{
	my $params = Params::Get::get_params('string', @_);

	my $string = $params->{'string'};
	my $complain = $params->{'complain'};

	if(!defined($string)) {
		croak 'Usage: wide_to_xml() string not set';
	}

	if(ref($string) eq 'SCALAR') {
		$string = ${$string};
	}


	# SECURITY: skip entity-decoding when keep_hrefs is set — same rationale as
	# wide_to_html: decoded payloads bypass re-escaping and produce XSS output.
	unless($params->{'keep_hrefs'}) {
		$string = HTML::Entities::decode($string);

		# Decode the four named entities HTML::Entities::decode misses
		$string =~ s/($_EXTRA_ENTITY_RE)/$_EXTRA_ENTITY_MAP{$1}/g;
	}

	# Possessive ++ prevents O(n^2) backtracking (ReDoS) on inputs like
	# "&aaaaaa..." with no closing semicolon.
	$string =~ s/&(?![A-Za-z#0-9]++;)/&amp;/g;

	unless($params->{'keep_hrefs'}) {
		# Escape ASCII markup chars; %_HTML_ESCAPE eliminates the /e eval flag.
		$string =~ s/([<>"])/$_HTML_ESCAPE{$1}/g;
	}

	# $string =~ s/‘/&apos;/g;
	# $string =~ s/’/&apos;/g;
	# $string =~ s/‘/&apos;/g;
	# $string =~ s/‘/&apos;/g;
	# $string =~ s/\x98/&apos;/g;
	# $string =~ s/['‘’‘\x98]/&apos;/g;

	# Table of byte-sequences->entities
	my @byte_map = (
		[ "\xe2\x80\x9c", '&quot;' ],	# “
		[ "\xe2\x80\x9d", '&quot;' ],	# ”
		[ '“', '&quot;' ],	# U+201C
		[ '”', '&quot;' ],	# U+201D
		[ "\xe2\x80\x93", '-' ],	# ndash
		[ "\xe2\x80\x94", '-' ],	# mdash
		[ "\xe2\x80\x98", '&apos;' ],	# ‘
		[ "\xe2\x80\x99", '&apos;' ],	# ’
		[ "\xe2\x80\xA6", '...' ],	# …
		[ "'", '&apos;' ],
		[ '‘', '&apos;' ],
		[ '’', '&apos;' ],
		[ '‘', '&apos;' ],
		[ "\x98", '&apos;' ],
	);

	$string = _sub_map(\$string, \@byte_map);

	# DEAD CODE: the %entity_map below has keys that are multi-character HTML
	# entity strings (e.g. '&copy;', '&Aacute;').  The s{(.)}{...}gex loop
	# that follows matches one character at a time; a single char can never
	# equal a multi-char key, so the true branch is unreachable.
	# By the time the string reaches here, HTML::Entities::decode has already
	# converted all recognised named entities to their Unicode equivalents,
	# which the byte_map passes below encode correctly.
	# Additional bugs in the removed block: '&uacute;' => '&#0FA;' (decimal,
	# not hex) and '&ucirc;' => '&#x0F4;' (maps to o-circumflex, not u-circumflex).
	# This block has been commented out to remove dead code and reach 100%
	# branch coverage.  See t/extended_tests.t section 3 for validation.
	#
	# %entity_map = (
	# 	'&copy;' => '&#x0A9;',
	# 	'&Aacute;' => '&#x0C1;',
	# 	'&ccaron;' => '&#x10D;',
	# 	...
	# 	'&excl;' => '!',
	# );
	# $string =~ s{(.)}{
	# 	my $cp = $1;
	# 	exists $entity_map{$cp}
	# 		? $entity_map{$cp}
	# 		: $cp
	# }gex;

	if($string !~ /[^[:ascii:]]/) {
		return $string;
	}

	@byte_map = (
		["\xc2\xa0", ' '],	# Non breaking space
		["\xc2\xa3", '&#x0A3;'],	# £
		["\xc2\xa9", '&#x0A9;'],
		["\xc2\xaa", '&#x0AA;'],	# ª
		["\xc2\xab", '&quot;'],	# «
		["\xc2\xae", '&#x0AE;'],
		["\xc3\x81", '&#x0C1;'],	# Á
		["\xc3\x8e", '&#x0CE;'],	# Î
		["\xc3\xa0", '&#x0E0;'],	# à
		["\xc3\xa1", '&#x0E1;'],	# á
		["\xc3\xa5", '&#x0E5;'],	# å
		["\xc3\xa9", '&#x0E9;'],
		["\xc3\xaf", '&#x0EF;'],	# ï
		["\xc3\xb1", '&#x0F1;'],	# ntilde ñ
		["\xc5\xa1", '&#x161;'],
		["\xc4\x8d", '&#x10D;'],
		["\xc5\xbd", '&#x17D;'],	# Ž
		["\xc5\xbe", '&#x17E;'],	# ž
		["\xc3\x96", '&#x0D6;'],	# Ö
		["\xc3\x9e", '&#x0DE;'],	# Þ
		["\xc3\x9f", '&#x0DF;'],	# ß
		["\xc3\xa2", '&#x0E2;'],	# â
		["\xc3\xad", '&#x0ED;'],	# í
		["\xc3\xa4", '&#x0E4;'],	# ä
		["\xc3\xa7", '&#x0E7;'],	# ç
		["\xc3\xb0", '&#x0F0;'],	# ð
		["\xc3\xb3", '&#x0F3;'],	# ó
		["\xc3\xb8", '&#x0F8;'],	# ø
		["\xc3\xbc", '&#x0FC;'],	# ü
		["\xc3\xbe", '&#x0FE;'],	# þ
		["\xc3\xa8", '&#x0E8;'],	# è
		["\xc3\xee", '&#x0EE;'],
		["\xc3\xb4", '&#x0F4;'],	# ô
		["\xc3\xb6", '&#x0F6;'],	# ö
		["\xc3\x89", '&#x0C9;'],
		["\xc3\xaa", '&#x0EA;'],
		["\xc3\xab", '&#x0EB;'],	# eumlaut
		["\xc3\xba", '&#x0FA;'],	# ú
		["\xc3\xbb", '&#x0BB;'],	# û - ucirc
		["\xc5\x9b", '&#x15B;'],	# ś - sacute
		["\xc5\xa0", '&#x160;'],
		["\xe2\x80\x93", '-'],
		["\xe2\x80\x94", '-'],
		["\xe2\x80\x9c", '&quot;'],
		["\xe2\x80\x9d", '&quot;'],
		["\xe2\x80\xa6", '...'],
		["\xe2\x97\x8f", '&#x25CF;'],	# ●
		["\xe3\xb1", '&#x0F1;'],	# ntilde ñ - what's this one?

		["\N{U+00A0}", ' '],
		["\N{U+010D}", '&#x10D;'],
		["\N{U+00AB}", '&quot;'],	# «
		["\N{U+00AE}", '&#x0AE;'],	# ®
		["\N{U+00B5}", '&#x0B5;'],	# µ
		["\N{U+00C1}", '&#x0C1;'],	# Á
		["\N{U+00CE}", '&#x0CE;'],	# Î
		["\N{U+00DE}", '&#x0DE;'],	# Þ
		["\N{U+00E0}", '&#x0E0;'],	# à
		["\N{U+00E4}", '&#x0E4;'],	# ä
		["\N{U+00E5}", '&#x0E5;'],	# å
		["\N{U+00EA}", '&#x0EA;'],
		["\N{U+00ED}", '&#x0ED;'],
		["\N{U+00EE}", '&#x0EE;'],
		["\N{U+00FE}", '&#x0FE;'],	# þ
		["\N{U+00C9}", '&#x0C9;'],
		["\N{U+017D}", '&#x17D;'],	# Ž
		["\N{U+017E}", '&#x17E;'],	# ž
		["\N{U+00D6}", '&#x0D6;'],	# Ö
		["\N{U+00DF}", '&#x0DF;'],	# ß
		["\N{U+00E1}", '&#x0E1;'],	# á - aacute
		["\N{U+00E2}", '&#x0E2;'],
		["\N{U+00E8}", '&#x0E8;'],	# è
		["\N{U+00EF}", '&#x0EF;'],	# ï
		["\N{U+00F0}", '&#x0F0;'],	# ð
		["\N{U+00F1}", '&#x0F1;'],	# ñ
		["\N{U+00F3}", '&#x0F3;'],	# ó
		["\N{U+00F4}", '&#x0F4;'],	# ô
		["\N{U+00F6}", '&#x0F6;'],	# ö
		["\N{U+00F8}", '&#x0F8;'],	# ø
		["\N{U+00FA}", '&#x0FA;'],	# ú
		["\N{U+00FC}", '&#x0FC;'],	# ü
		["\N{U+015B}", '&#x15B;'],	# ś
		["\N{U+00E9}", '&#x0E9;'],
		["\N{U+00E7}", '&#x0E7;'],	# ç
		["\N{U+00EB}", '&#x0EB;'],	# ë
		["\N{U+00FB}", '&#x0FB;'],	# û
		["\N{U+0160}", '&#x160;'],
		["\N{U+0161}", '&#x161;'],
		["\N{U+00A3}", '&#x0A3;'],	# £
		["\N{U+00A9}", '&#x0A9;'],	# ©
		["\N{U+2013}", '-'],
		["\N{U+2014}", '-'],
		["\N{U+2018}", '&quot;'],
		["\N{U+2019}", '&quot;'],
		["\N{U+201C}", '&quot;'],
		["\N{U+201D}", '&quot;'],
		["\N{U+2026}", '...'],	# …
		["\N{U+2122}", '&#x2122;'],	# ™
		["\xe2\x84\xa2", '&#x2122;'],	# ™ UTF-8
		["\N{U+25CF}", '&#x25CF;'],	# ●
	);

	$string = _sub_map(\$string, \@byte_map);

	@byte_map = (
		["'", '&#039;'],
		["\x98", '&#039;'],
		['©', '&#x0A9;'],
		['ª', '&#x0AA;'],
		['®', '&#x0AE;'],
		['å', '&#x0E5;'],
		['š', '&#x161;'],
		['č', '&#x10D;'],
		['Ž', '&#x17D;'],
		['ž', '&#x17E;'],
		['£', '&#x0A3;'],
		['µ', '&#x0B5;'],
		['à', '&#x0E0;'],	# à
		['á', '&#x0E1;'],	# á
		['â', '&#x0E2;'],
		['ä', '&#x0E4;'],	# ä
		['Á', '&#x0C1;'],	# Á
		['Ö', '&#x0D6;'],
		['ß', '&#x0DF;'],
		['ç', '&#x0E7;'],
		['è', '&#x0E8;'],
		['é', '&#x0E9;'],
		['ê', '&#x0EA;'],
		['ë', '&#x0EB;'],
		['í', '&#x0ED;'],
		['ï', '&#x0EF;'],
		['Î', '&#x0CE;'],	# Î
		['Þ', '&#x0DE;'],	# Þ
		['ð', '&#x0F0;'],	# ð
		['ø', '&#x0F8;'],	# ø
		['û', '&#x0FB;'],
		['ñ', '&#x0F1;'],
		['ú', '&#x0FA;'],
		['ü', '&#x0FC;'],
		['þ', '&#x0FE;'],	# þ
		['“', '&quot;'],
		['”', '&quot;'],
		['«', '&quot;'],
		['»', '&quot;'],
		['—', '-'],
		['–', '-'],
		['…', '...'],
		['™', '&#x2122;'],
		['●', '&#x25CF;'],
		["\x80\$", ' '],
	);

	$string = _sub_map(\$string, \@byte_map);

	if($string =~ /[^[:ascii:]]/) {
		$complain->("TODO: wide_to_xml($string)") if($complain);
		# Sanitize non-ASCII to hex tokens before embedding in the error message
		$string =~ s{
				([^[:ascii:]])
			}{
				'>>>>' . sprintf('%04X', ord($1)) . '<<<<'
			}gex;
		carp "TODO: wide_to_xml($string)";
		croak "BUG: wide_to_xml($string)";
	}
	return $string;
}

# _sub_map -- apply a list of [from, to] substitutions in a single pass.
#
# Purpose:    Replace every occurrence of each 'from' key with its 'to' value.
#             Longer keys take priority over shorter ones (longest-match-first).
# Entry:      $_[0] scalar-ref to string; $_[1] arrayref of [from, to] pairs.
#             Duplicate 'from' keys: the first definition wins.
# Exit:       Returns a new string (the scalar-ref argument is not modified).
# Side Effects: None.
sub _sub_map
{
	my $string   = ${$_[0]};
	my $byte_map = $_[1];

	# Build the alternation regex, longest key first to prevent partial matches
	my $pattern = join '|',
		map  { quotemeta($_->[0]) }
		sort { length($b->[0]) <=> length($a->[0]) }
		@{$byte_map};

	# Pre-build a hash for O(1) lookup during substitution.
	# Iterate in reverse so that the first definition in @byte_map wins on duplicate keys.
	my %map;
	for my $pair (reverse @{$byte_map}) {
		$map{$pair->[0]} = $pair->[1];
	}

	# No /e flag: hash dereference is a simple value interpolation, not code.
	$string =~ s/($pattern)/$map{$1}/g;

	return $string;
}

=head1 SECURITY

=head2 XSS via entity decode and keep_hrefs

By default both functions call C<HTML::Entities::decode> as the first pipeline
step, normalising input like C<&lt;b&gt;> to C<< <b> >> before re-escaping it.
This round-trip is safe when C<keep_hrefs> is false because the re-escape step
then converts C<< < >> and C<< > >> back to C<&lt;> and C<&gt;>.

When C<keep_hrefs =E<gt> 1> is set, the re-escape step is skipped so that
existing markup survives intact.  If the decode step still ran, a malicious
input such as C<&lt;script&gt;alert(1)&lt;/script&gt;> would become the raw
string C<< <script>alert(1)</script> >> and pass through to the output
unescaped, creating a stored XSS vector.

B<Fix applied in 0.07:> when C<keep_hrefs> is true, the decode step is also
skipped.  The pipeline treats the input as already-trusted HTML; wide
characters are still encoded, but entity normalisation becomes the caller's
responsibility.

=head2 ReDoS in bare-ampersand substitution

The substitution that escapes bare C<&> characters uses a negative lookahead
to distinguish bare ampersands from valid entity references.  A naive
backtracking quantifier inside that lookahead creates O(n^2) work for inputs
such as C<&aaaaa...X> (many word characters, no closing semicolon).

B<Fix applied in 0.07:> the character class inside the lookahead uses a
possessive quantifier C<[A-Za-z#0-9]++>, which commits matches and prevents
backtracking.  Perl 5.10 or later is required, consistent with the declared
C<MIN_PERL_VERSION>.

=head2 Eval-free substitutions

All substitutions in this module use plain C</g> rather than C</ge> (evaluate
replacement as Perl code).  The C</e> flag was present in earlier versions but
was unnecessary: hash lookups are value interpolation, not executable code.
Removing C</e> eliminates a class of potential code-injection issues should a
future change inadvertently expose user-controlled data in the replacement
expression.

=head1 LIMITATIONS

=over 4

=item Character coverage is hand-maintained

Both functions use explicit C<@byte_map> tables organised into three passes
(raw UTF-8 bytes, C<\N{U+...}> named chars, literal Unicode source chars).
Characters not covered by these tables fall back to
C<HTML::Entities::encode_entities_numeric> in C<wide_to_html>, or trigger a
fatal C<BUG:> error in C<wide_to_xml> (XML has no safe generic numeric
fallback).  To add a missing character, extend all three passes for the
relevant function and add a regression test in C<t/30-basics.t>.

=item No C<< <script> >> or C<< <style> >> awareness

C<wide_to_html> encodes wide characters uniformly regardless of context.  It
does not detect content inside C<< <script> >> or C<< <style> >> blocks, so
passing a complete HTML document through this function will corrupt embedded
scripts and stylesheets.  Feed only text fragments or attribute values, not
full documents.

=item XML numeric entity format uses a minimal hex width

The XML pipeline outputs C<&#x0E9;> (three hex digits with one leading zero
for values below 0x100) rather than the canonical four-digit form C<&#x00E9;>.
Both representations are valid XML 1.0.  Consumers that perform strict byte-
level comparison of entity strings should normalise to a consistent width
before comparing.

=item Raw binary input is not supported

The module assumes its input is either a Perl Unicode string (internal C<utf8>
flag set) or a valid UTF-8 byte string.  Passing arbitrary binary data or
text in a single-byte encoding other than Latin-1 will produce incorrect
output or trigger decoding errors.  Decode the input with L<Encode/decode>
before calling these functions.

=item C<keep_hrefs> shifts trust to the caller

When C<keep_hrefs =E<gt> 1> is set, entity-decoding is suppressed and markup
characters pass through unescaped.  The caller must guarantee that the input
does not contain untrusted content that could produce XSS output.

=back

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Encode-Wide/coverage/>

=item * L<HTML::Entities> — the standard module for HTML entity encoding and decoding

=item * L<Encode> — Perl's core character encoding framework

=item * L<XML::Entities> — decodes XML named entities (the inverse of wide_to_xml)

=item * L<Unicode::Escape> — alternative Unicode escaping approaches

=item * L<https://www.compart.com/en/unicode/> — Unicode character reference

=back

=head1 SUPPORT

Please report bugs and feature requests through the RT bug tracker:

    https://rt.cpan.org/Public/Dist/Display.html?Name=Encode-Wide

Or by email: C<bug-encode-wide at rt.cpan.org>

You will be notified automatically of progress on your report.

=head1 FORMAL SPECIFICATION

=head2 wide_to_html

Let S be the input string, S' the output string.

    ∀ c ∈ S' : ord(c) ≤ 0x7F                           (ASCII-only output)
    S = ""  ⟹  S' = ""                                  (empty pass-through)
    keep_hrefs = 0 ⟹ "<" ∉ S' ∧ ">" ∉ S' ∧ ∄ bare " in S'
    keep_apos  = 0 ⟹ ∄ bare apostrophe in S'
    ¬∃ bare & in S'  (& appears only as part of a valid &name; or &#xNN; entity)
    string = undef ⟹ croak("Usage: wide_to_html() string not set")

=head2 wide_to_xml

Let S be the input string, S' the output string.

    ∀ c ∈ S' : ord(c) ≤ 0x7F                           (ASCII-only output)
    S = ""  ⟹  S' = ""                                  (empty pass-through)
    keep_hrefs = 0 ⟹ "<" ∉ S' ∧ ">" ∉ S' ∧ ∄ bare " in S'
    U+2013 ∈ S ⟹ "-" ∈ S' ∧ U+2013 ∉ S'               (en-dash collapsed)
    U+2014 ∈ S ⟹ "-" ∈ S' ∧ U+2014 ∉ S'               (em-dash collapsed)
    ¬∃ bare & in S'  (& appears only as part of a valid &name; or &#xNN; entity)
    string = undef ⟹ croak("Usage: wide_to_xml() string not set")

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself (GPL version 2 or later).

If you use this module, please let me know at
C<njh at nigelhorne.com>.

=cut

1;
