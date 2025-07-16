package Encode::Wide;

# TODO: don't transform anything within <script>...</script>
# TODO: a lot of this should be table driven

use strict;
use warnings;

use Exporter qw(import);
use HTML::Entities;
use Params::Get;
use Term::ANSIColor;

our @EXPORT_OK = qw(wide_to_html wide_to_xml);

# Encode to HTML whatever the non-ASCII encoding scheme has been chosen
# Can't use HTML:Entities::encode since that doesn't seem to cope with
#	all encodings and misses some characters
#
# See https://www.compart.com/en/unicode/U+0161 etc.
#	https://www.compart.com/en/unicode/U+00EB
#
# keep_hrefs => 1 means ensure hyperlinks still work
# keep_apos => 1 means keep apostrophes, useful within <script>

=encoding UTF-8

=head1 NAME

Encode::Wide - Convert wide characters (Unicode) into HTML or XML-safe ASCII entities

=head1 VERSION

0.02

=cut

our $VERSION = 0.02;

=head1 SYNOPSIS

    use Encode::Wide qw(wide_to_html wide_to_xml);

    my $html = wide_to_html(string => "Café déjà vu – naïve façade");
    # returns: 'Caf&eacute; d&eacute;j&agrave; vu &ndash; na&iuml;ve fa&ccedil;ade'

    my $xml = wide_to_xml(string => "Café déjà vu – naïve façade");
    # returns: 'Caf&#xE9; d&#xE9;j&#xE0; vu &#x2013; na&#xEF;ve fa&#xE7;ade'

=head1 DESCRIPTION

Encode::Wide provides functions for converting wide (Unicode) characters into ASCII-safe
formats suitable for embedding in HTML or XML documents. It is especially useful
when dealing with text containing accented or typographic characters that need
to be safely represented in markup.

The module offers two exportable functions:

=over 4

=item * C<wide_to_html(string => $text)>

Converts Unicode characters in the input string to their named HTML entities if available,
or hexadecimal numeric entities otherwise. Common characters such as `é`, `à`, `&`, `<`, `>` are
converted to their standard HTML representations like `&eacute;`, `&agrave;`, `&amp;`, etc.

=item * C<wide_to_xml(string => $text)>

Converts all non-ASCII characters in the input string to hexadecimal numeric entities.
Unlike HTML, XML does not support many named entities, so this function ensures compliance
by using numeric representations such as `&#xE9;` for `é`.

=back

=head1 PARAMETERS

Both functions accept a named parameter:

=over 4

=item * C<string> — The Unicode string to convert.

=back

=head1 ENCODING

Input strings are expected to be valid UTF-8. If a byte string is passed, the module will attempt
to decode it appropriately. Output is guaranteed to be pure ASCII.

=head1 EXPORT

None by default.

Optionally exportable:

    wide_to_html
    wide_to_xml

=cut

sub wide_to_html
{
	my $params = Params::Get::get_params('string', @_);

	my $string = $params->{'string'};
	my $complain = $params->{'complain'};

	if(!defined($string)) {
		my $i = 0;
		while((my @call_details = caller($i++))) {
			print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
		}
		die 'BUG: wide_to_html() string not set';
	}

	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";
	# my $i = 0;
	# while((my @call_details = caller($i++))) {
		# print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
	# }

	$string = HTML::Entities::decode($string);
	# $string =~ s/ & / &amp; /g;
	$string =~ s/&ccaron;/č/g;	# I don't think HTML::Entities does this
	$string =~ s/&zcaron;/ž/g;	# I don't think HTML::Entities does this
	$string =~ s/&Scaron;/Š/g;	# I don't think HTML::Entities does this

	# Escape only if it's not already part of an entity
	$string =~ s/&(?![A-Za-z#0-9]+;)/&amp;/g;

	unless($params->{'keep_hrefs'}) {
		$string =~ s/</&lt;/g;
		$string =~ s/>/&gt;/g;
		$string =~ s/"/&quot;/g;
	}

	$string =~ s/\xe2\x80\x9c/&quot;/g;	# “
	$string =~ s/\xe2\x80\x9d/&quot;/g;	# ”
	$string =~ s/“/&quot;/g;	# U+201C
	$string =~ s/”/&quot;/g;	# U+201D

	# $string =~ s/&db=/&amp;db=/g;
	# $string =~ s/&id=/&amp;id=/g;

	$string =~ s/\xe2\x80\x93/&ndash;/g;
	$string =~ s/\xe2\x80\x94/&mdash;/g;
	$string =~ s/\xe2\x80\x98/&apos;/g;	# ‘
	$string =~ s/\xe2\x80\x99/&apos;/g;	# ’
	$string =~ s/\xe2\x80\xA6/.../g;	# …
	unless($params->{'keep_apos'}) {
		# We can't combine since each char in the multi-byte matches, not the entire multi-byte
		# $string =~ s/['‘’‘\x98]/&apos;/g;
		$string =~ s/'/&apos;/g;
		$string =~ s/‘/&apos;/g;
		$string =~ s/’/&apos;/g;
		$string =~ s/‘/&apos;/g;
		$string =~ s/\x98/&apos;/g;
	}

	if($string !~ /[^[:ascii:]]/) {
		return $string;
	}

	$string =~ s/\xc2\xa0/ /g;	# Non breaking space
	$string =~ s/\xc2\xa3/&pound;/g;
	$string =~ s/\xc2\xa9/&copy;/g;
	$string =~ s/\xc2\xaa/&ordf;/g;	# ª
	$string =~ s/\xc2\xab/&quot;/g;	# «
	$string =~ s/\xc2\xae/&reg;/g;
	$string =~ s/\xc2\xbb/&quot;/g;	# »
	$string =~ s/\xc3\x81/&Aacute;/g;	# Á
	$string =~ s/\xc3\x83/&Icirc;/g;	# Î
	$string =~ s/\xc3\x9e/&THORN;/g;	# Þ
	$string =~ s/\xc3\xa0/&agrave;/g;	# à
	$string =~ s/\xc3\xa1/&aacute;/g;	# á
	$string =~ s/\xc3\xa2/&acirc;/g;
	$string =~ s/\xc3\xa4/&auml;/g;
	$string =~ s/\xc3\xa9/&eacute;/g;
	$string =~ s/\xc3\xad/&iacute;/g;	# í
	$string =~ s/\xc3\xb0/&eth;/g;	# ð
	$string =~ s/\xc3\xba/&uacute;/g;	# ú
	$string =~ s/\xc3\xb4/&ocirc;/g;	# ô
	$string =~ s/\xc3\xb6/&ouml;/g;
	$string =~ s/\xc3\xb8/&oslash;/g;	# ø
	$string =~ s/\xc5\xa1/&scaron;/g;
	$string =~ s/\xc4\x8d/&ccaron;/g;
	$string =~ s/\xc5\xbe/&zcaron;/g;
	$string =~ s/\xc3\xa5/&aring;/g;	# å
	$string =~ s/\xc3\xa7/&ccedil;/g;
	$string =~ s/\xc3\xaf/&iuml;/g;	# ï
	$string =~ s/\xc3\xb3/&oacute;/g;
	$string =~ s/\xc3\x96/&Ouml;/g; # Ö
	$string =~ s/\xc3\xa8/&egrave;/g;
	$string =~ s/\xc3\x89/&Eacute;/g;
	$string =~ s/\xc3\x9f/&szlig;/g;
	$string =~ s/\xc3\xaa/&ecirc;/g;
	$string =~ s/\xc3\xab/&euml;/g;
	$string =~ s/\xc3\xae/&icirc;/g;
	$string =~ s/\xc3\xbb/&ucirc;/g;
	$string =~ s/\xc3\xbc/&uuml;/g; # ü
	$string =~ s/\xc3\xbe/&thorn;/g;	# þ
	$string =~ s/\xc5\x9b/&sacute;/g;
	$string =~ s/\xc5\xa0/&Scaron;/g;
	$string =~ s/\xe2\x80\x93/&ndash;/g;
	$string =~ s/\xe2\x80\x94/&mdash;/g;
	$string =~ s/\xc3\xb1/&ntilde;/g;	# ñ
	$string =~ s/\xe2\x80\x9c/&quot;/g;
	$string =~ s/\xe2\x80\x9d/&quot;/g;
	$string =~ s/\xe2\x80\xa6/.../g;
	$string =~ s/\xe2\x97\x8f/&#x25CF;/g;	# ●

	$string =~ s/\N{U+00A0}/ /g;
	$string =~ s/\N{U+00A3}/&pound;/g;
	$string =~ s/\N{U+00A9}/&copy;/g;
	$string =~ s/\N{U+00AA}/&ordf;/g;	# ª
	$string =~ s/\N{U+00AB}/&quot;/g;	# «
	$string =~ s/\N{U+00AE}/&reg;/g;
	$string =~ s/\N{U+00BB}/&quot;/g;	# »
	$string =~ s/\N{U+00CE}/&Icirc;/g;	# Î
	$string =~ s/\N{U+00DE}/&THORN;/g;	# Þ
	$string =~ s/\N{U+0161}/&scaron;/g;
	$string =~ s/\N{U+010D}/&ccaron;/g;
	$string =~ s/\N{U+017E}/&zcaron;/g;
	$string =~ s/\N{U+00C9}/&Eacute;/g;
	$string =~ s/\N{U+00D6}/&Ouml;/g;	# Ö
	$string =~ s/\N{U+00DF}/&szlig;/g;	# ß
	$string =~ s/\N{U+00E1}/&aacute;/g;	# á
	$string =~ s/\N{U+00E2}/&acirc;/g;
	$string =~ s/\N{U+00E4}/&auml;/g;
	$string =~ s/\N{U+00E5}/&aring;/g;	# å
	$string =~ s/\N{U+00E7}/&ccedil;/g;	# ç
	$string =~ s/\N{U+00E8}/&egrave;/g;
	$string =~ s/\N{U+00E9}/&eacute;/g;
	$string =~ s/\N{U+00ED}/&iacute;/g;	# í
	$string =~ s/\N{U+00EE}/&icirc;/g;
	$string =~ s/\N{U+00EF}/&iuml;/g;	# ï
	$string =~ s/\N{U+00F0}/&eth;/g;	# ð
	$string =~ s/\N{U+00F1}/&ntilde;/g;	# ñ
	$string =~ s/\N{U+00F4}/&ocirc;/g;	# ô
	$string =~ s/\N{U+00F6}/&ouml;/g;
	$string =~ s/\N{U+00F8}/&oslash;/g;	# ø
	$string =~ s/\N{U+00FA}/&uacute;/g;	# ú
	$string =~ s/\N{U+00FC}/&uuml;/g;	# ü
	$string =~ s/\N{U+00FE}/&thorn;/g;	# þ
	$string =~ s/\N{U+00C1}/&Aacute;/g;	# Á
	$string =~ s/\N{U+00C9}/&Eacute;/g;
	$string =~ s/\N{U+00CA}/&ecirc;/g;
	$string =~ s/\N{U+00EB}/&euml;/g;
	$string =~ s/\N{U+00F3}/&oacute;/g;
	$string =~ s/\N{U+015B}/&sacute;/g;
	$string =~ s/\N{U+00FB}/&ucirc;/g;
	$string =~ s/\N{U+0160}/&Scaron;/g;
	$string =~ s/\N{U+2013}/&ndash;/g;
	$string =~ s/\N{U+2014}/&mdash;/g;
	$string =~ s/\N{U+201C}/&quot;/g;
	$string =~ s/\N{U+201D}/&quot;/g;
	$string =~ s/\N{U+2026}/.../g;	# …
	$string =~ s/\N{U+25CF}/&#x25CF;/g;	# ●

	# utf8::encode($string);
	# $string =~ s/š/&scaron;/g;
	# $string =~ s/č/&ccaron;/g;
	# $string =~ s/ž/&zcaron;/g;
	# $string =~ s/é/&eacute;/g;
	# $string =~ s/ç/&ccedil;/g;
	# $string =~ s/\N{U+0161}/&scaron;/g;
	# $string =~ s/\N{U+010D}/&ccaron;/g;
	# $string =~ s/\N{U+017E}/&zcaron;/g;
	# $string =~ s/\N{U+00E9}/&eacute;/g;
	# $string =~ s/\N{U+00D6}/&Ouml;/g;	# Ö
	# $string =~ s/\N{U+00E7}/&ccedil;/g;	# ç
	# $string =~ s/\N{U+00E8}/&egrave;/g;
	# $string =~ s/\N{U+00E9}/&Eacute;/g;

	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";

	# utf8::decode($string);

	# print STDERR __LINE__, ": ($string)";
	# # print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";

	# $string =~ s/\xe4\x8d/&ccaron;/g;	# ? ACOM strangeness
	# $string =~ s/\N{U+0161}/&scaron;/g;
	# $string =~ s/\N{U+010D}/&ccaron;/g;
	# $string =~ s/\N{U+00A9}/&copy;/g;
	# $string =~ s/\N{U+00AE}/&reg;/g;
	# $string =~ s/\N{U+00E2}/&acirc;/g;
	# $string =~ s/\N{U+00E4}/&auml;/g;
	# $string =~ s/\N{U+00E8}/&egrave;/g;
	# $string =~ s/\N{U+00E9}/&eacute;/g;
	# $string =~ s/\N{U+00EB}/&euml;/g;
	# $string =~ s/\N{U+00F3}/&oacute;/g;
	# $string =~ s/\N{U+00FB}/&ucirc;/g;
	# $string =~ s/\N{U+017E}/&zcaron;/g;
	# $string =~ s/\N{U+00D6}/&Ouml;/g;	# Ö
	# $string =~ s/\N{U+00E7}/&ccedil;/g;	# ç
	# $string =~ s/\N{U+00C9}/&Eacute;/g;
	# $string =~ s/\N{U+00CA}/&ecirc;/g;
	# $string =~ s/\N{U+0160}/&Scaron;/g;	# FIXME: also above
	# $string =~ s/\N{U+2013}/-/g;

	$string =~ s/Á/&Aacute;/g;
	$string =~ s/å/&aring;/g;
	$string =~ s/ª/&ordf;/g;
	$string =~ s/š/&scaron;/g;
	$string =~ s/Š/&Scaron;/g;
	$string =~ s/č/&ccaron;/g;
	$string =~ s/ž/&zcaron;/g;
	$string =~ s/á/&aacute;/g;
	$string =~ s/â/&acirc;/g;
	$string =~ s/é/&eacute;/g;
	$string =~ s/è/&egrave;/g;
	$string =~ s/ç/&ccedil;/g;
	$string =~ s/ê/&ecirc;/g;
	$string =~ s/ë/&euml;/g;
	$string =~ s/ð/&eth;/g;
	$string =~ s/í/&iacute;/g;
	$string =~ s/ï/&iuml;/g;
	$string =~ s/Î/&Iicrc;/g;
	$string =~ s/©/&copy;/g;
	$string =~ s/®/&reg;/g;
	$string =~ s/ó/&oacute;/g;
	$string =~ s/ô/&ocirc;/g;
	$string =~ s/ö/&ouml;/g;
	$string =~ s/ø/&oslash;/g;
	$string =~ s/ś/&sacute;/g;
	$string =~ s/Þ/&THORN;/g;
	$string =~ s/þ/&thorn;/g;
	$string =~ s/û/&ucirc;/g;
	$string =~ s/ü/&uuml;/g;
	$string =~ s/ú/&uacute;/g;
	$string =~ s/£/&pound;/g;
	$string =~ s/ß/&szlig;/g;
	$string =~ s/–/&ndash;/g;
	$string =~ s/—/&mdash;/g;
	$string =~ s/ñ/&ntilde;/g;
	# See above
	# $string =~ s/[“”«»]/&quot;/g;
	$string =~ s/“/&quot;/g;
	$string =~ s/”/&quot;/g;
	$string =~ s/«/&quot;/g;
	$string =~ s/»/&quot;/g;
	$string =~ s/…/.../g;
	$string =~ s/●/&#x25CF;/g;
	$string =~ s/\x80$/ /;

	# if($string =~ /^Maria\(/) {
		# # print STDERR (unpack 'H*', $string);
		# print STDERR __LINE__, ': ';
		# print STDERR (sprintf '%v02X', $string);
		# print STDERR "\n";
		# my $i = 0;
		# while((my @call_details = caller($i++))) {
			# print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
		# }
		# # die $string;
	# }

	# print STDERR __LINE__, ": ($string)\n";
	if($string =~ /[^[:ascii:]]/) {
		$string = HTML::Entities::encode_entities_numeric($string, '\x80-\x{10FFFF}');
		if($string =~ /[^[:ascii:]]/) {
			print STDERR (unpack 'H*', $string);
			print STDERR __LINE__, ': ';
			print STDERR (sprintf '%v02X', $string), "\n";
			my $i = 0;
			while((my @call_details = caller($i++))) {
				print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
			}
			$complain->("TODO: wide_to_html($string)") if($complain);
			warn "TODO: wide_to_html($string)";
			$string =~ s/[^[:ascii:]]/XXXXX/g;
			die "BUG: wide_to_html($string)";
		}
	}

	return $string;
}

# See https://www.compart.com/en/unicode/U+0161 etc.
#	https://www.compart.com/en/unicode/U+00EB
sub wide_to_xml
{
	my $params = Params::Get::get_params('string', @_);

	my $string = $params->{'string'};
	my $complain = $params->{'complain'};

	if(!defined($string)) {
		my $i = 0;
		while((my @call_details = caller($i++))) {
			print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
		}
		die 'BUG: string not set';
	}

	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";

	# my $i = 0;
	# while((my @call_details = caller($i++))) {
		# print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
	# }

	$string = HTML::Entities::decode($string);
	# print STDERR __LINE__, ": ($string)\n";

	# $string =~ s/&amp;/&/g;
	$string =~ s/&ccaron;/č/g;	# I don't think HTML::Entities does this
	$string =~ s/&zcaron;/ž/g;	# I don't think HTML::Entities does this
	$string =~ s/&Scaron;/Š/g;	# I don't think HTML::Entities does this

	# Escape only if it's not already part of an entity
	$string =~ s/&(?![A-Za-z#0-9]+;)/&amp;/g;

	unless($params->{'keep_hrefs'}) {
		# $string =~ s/</&lt;/g;
		# $string =~ s/>/&gt;/g;
		# $string =~ s/"/&quot;/g;
		# $string =~ s/“/&quot;/g;	# U+201C
		# $string =~ s/”/&quot;/g;	# U+201D

		my %replacements = (
			'<' => '&lt;',
			'>' => '&gt;',
			'"' => '&quot;',
			'“' => '&quot;',	# U+201C
			'”' => '&quot;',	# U+201D
		);

		$string =~ s/([<>“”"])/$replacements{$1} || $1/eg;
	}

	$string =~ s/\xe2\x80\x9c/&quot;/g;	# “
	$string =~ s/\xe2\x80\x9d/&quot;/g;	# ”
	$string =~ s/“/&quot;/g;	# U+201C
	$string =~ s/”/&quot;/g;	# U+201D

	# $string =~ s/‘/&apos;/g;
	# $string =~ s/’/&apos;/g;
	# $string =~ s/‘/&apos;/g;
	# $string =~ s/‘/&apos;/g;
	# $string =~ s/\x98/&apos;/g;
	$string =~ s/\xe2\x80\x93/&ndash;/g;
	$string =~ s/\xe2\x80\x94/&mdash;/g;
	$string =~ s/\xe2\x80\x98/&apos;/g;	# ‘
	$string =~ s/\xe2\x80\x99/&apos;/g;	# ’
	$string =~ s/\xe2\x80\xA6/.../g;	# …
	# $string =~ s/['‘’‘\x98]/&apos;/g;
	$string =~ s/'/&apos;/g;
	$string =~ s/‘/&apos;/g;
	$string =~ s/’/&apos;/g;
	$string =~ s/‘/&apos;/g;
	$string =~ s/\x98/&apos;/g;

	$string =~ s/&Aacute;/&#x0C1;/g;	# Á
	$string =~ s/&aring;/&#x0E5;/g;	# å
	$string =~ s/&ccaron;/&#x10D;/g;
	$string =~ s/&agrave;/&#x0E0;/g;	# á
	$string =~ s/&aacute;/&#x0E1;/g;	# á
	$string =~ s/&acirc;/&#x0E2;/g;		# â
	$string =~ s/&auml;/&#x0E4;/g;		# ä
	$string =~ s/&ccedil;/&#x0E7;/g;	# ç
	$string =~ s/&egrave;/&#x0E8;/g;
	$string =~ s/&eacute;/&#x0E9;/g;
	$string =~ s/&ecirc;/&#x0EA;/g;
	$string =~ s/&euml;/&#x0EB;/g;	# euml
	$string =~ s/&Icirc;/&#x0CE;/g;	# Î
	$string =~ s/&Eacute;/&#x0C9;/g;
	$string =~ s/&szlig;/&#x0DF;/g;	# ß
	$string =~ s/&iacute;/&#xED;/g;	# í
	$string =~ s/&icirc;/&#x0EE;/g;
	$string =~ s/&iuml;/&#x0EF;/g;	# ï
	$string =~ s/&eth;/&#x0F0;/g;	# ð
	$string =~ s/&uacute;/&#0FA;/g;	# ú
	$string =~ s/&uuml;/&#x0FC;/g;
	$string =~ s/&scaron;/&#x161;/g;
	$string =~ s/&oacute;/&#x0F3;/g;	# ó
	$string =~ s/&ucirc;/&#x0F4;/g;
	$string =~ s/&ouml;/&#x0F6;/g;
	$string =~ s/&ordf;/&#x0AA;/g;	# ª
	$string =~ s/&oslash;/&#x0F8;/g;	# ø
	$string =~ s/&zcaron;/&#x17E;/g;
	$string =~ s/&Scaron;/&#x160;/g;
	$string =~ s/&THORN;/&#x0DE;/g;	# Þ
	$string =~ s/&thorn;/&#x0FE;/g;	# þ
	$string =~ s/&copy;/&#x0A9;/g;
	$string =~ s/&reg;/&#x0AE;/g;
	$string =~ s/&pound;/&#163;/g;
	$string =~ s/&ntilde;/&#x0F1;/g;
	$string =~ s/&mdash;/-/g;
	$string =~ s/&ndash;/-/g;

	if($string !~ /[^[:ascii:]]/) {
		return $string;
	}

	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";

	$string =~ s/\xc2\xa0/ /g;	# Non breaking space
	$string =~ s/\xc2\xa3/&#x0A3;/g;	# £
	$string =~ s/\xc2\xa9/&#x0A9;/g;
	$string =~ s/\xc2\xaa/&#x0AA;/g;	# ª
	$string =~ s/\xc2\xab/&quot;/g;	# «
	$string =~ s/\xc2\xae/&#x0AE;/g;
	$string =~ s/\xc3\x81/&#x0C1;/g;	# Á
	$string =~ s/\xc3\x8e/&#x0CE;/g;	# Î
	$string =~ s/\xc3\xa0/&#x0E0;/g;	# à
	$string =~ s/\xc3\xa1/&#x0E1;/g;	# á
	$string =~ s/\xc3\xa5/&#x0E5;/g;	# å
	$string =~ s/\xc3\xa9/&#x0E9;/g;
	$string =~ s/\xc3\xaf/&#x0EF;/g;	# ï
	$string =~ s/\xc3\xb1/&#x0F1;/g;	# ntilde ñ
	$string =~ s/\xc5\xa1/&#x161;/g;
	$string =~ s/\xc4\x8d/&#x10D;/g;
	$string =~ s/\xc5\xbe/&#x17E;/g;	# ž
	$string =~ s/\xc3\x96/&#x0D6;/g;	# Ö
	$string =~ s/\xc3\x9e/&#x0DE;/g;	# Þ
	$string =~ s/\xc3\x9f/&#x0DF;/g;	# ß
	$string =~ s/\xc3\xa2/&#x0E2;/g;	# â
	$string =~ s/\xc3\xad/&#x0ED;/g;	# í
	$string =~ s/\xc3\xa4/&#x0E4;/g;	# ä
	$string =~ s/\xc3\xa7/&#x0E7;/g;	# ç
	$string =~ s/\xc3\xb0/&#x0F0;/g;	# ð
	$string =~ s/\xc3\xb3/&#x0F3;/g;	# ó
	$string =~ s/\xc3\xb8/&#x0F8;/g;	# ø
	$string =~ s/\xc3\xbc/&#x0FC;/g;	# ü
	$string =~ s/\xc3\xbe/&#x0FE;/g;	# þ
	$string =~ s/\xc3\xa8/&#x0E8;/g;	# è
	$string =~ s/\xc3\xee/&#x0EE;/g;
	$string =~ s/\xc3\xb4/&#x0F4;/g;	# ô
	$string =~ s/\xc3\xb6/&#x0F6;/g;	# ö
	$string =~ s/\xc3\x89/&#x0C9;/g;
	$string =~ s/\xc3\xaa/&#x0EA;/g;
	$string =~ s/\xc3\xab/&#x0EB;/g;	# eumlaut
	$string =~ s/\xc3\xba/&#x0FA;/g;	# ú
	$string =~ s/\xc3\xbb/&#x0BB;/g;	# û - ucirc
	$string =~ s/\xc5\x9b/&#x15B;/g;	# ś - sacute
	$string =~ s/\xc5\xa0/&#x160;/g;
	$string =~ s/\xe2\x80\x93/-/g;
	$string =~ s/\xe2\x80\x94/-/g;
	$string =~ s/\xe2\x80\x9c/&quot;/g;
	$string =~ s/\xe2\x80\x9d/&quot;/g;
	$string =~ s/\xe2\x80\xa6/.../g;
	$string =~ s/\xe2\x97\x8f/&#x25CF;/g;	# ●
	$string =~ s/\xe3\xb1/&#x0F1;/g;	# ntilde ñ - what's this one?
	# $string =~ s/\xe4\x8d/&#x10D;/g;	# ? ACOM strangeness
	# $string =~ s/\N{U+0161}/&#x161;/g;
	# $string =~ s/\N{U+010D}/&#x10D;/g;
	# $string =~ s/\N{U+00E9}/&#x0E9;/g;
	# $string =~ s/\N{U+017E}/&#x17E;/g;

	$string =~ s/\N{U+00A0}/ /g;
	$string =~ s/\N{U+010D}/&#x10D;/g;
	$string =~ s/\N{U+00AB}/&quot;/g;	# «
	$string =~ s/\N{U+00AE}/&#x0AE;/g;	# ®
	$string =~ s/\N{U+00C1}/&#x0C1;/g;	# Á
	$string =~ s/\N{U+00CE}/&#x0CE;/g;	# Î
	$string =~ s/\N{U+00DE}/&#x0DE;/g;	# Þ
	$string =~ s/\N{U+00E4}/&#x0E4;/g;	# ä
	$string =~ s/\N{U+00E5}/&#x0E5;/g;	# å
	$string =~ s/\N{U+00EA}/&#x0EA;/g;
	$string =~ s/\N{U+00ED}/&#x0ED;/g;
	$string =~ s/\N{U+00EE}/&#x0EE;/g;
	$string =~ s/\N{U+00FE}/&#x0FE;/g;	# þ
	$string =~ s/\N{U+00C9}/&#x0C9;/g;
	$string =~ s/\N{U+017E}/&#x17E;/g;	# ž
	$string =~ s/\N{U+00D6}/&#x0D6;/g;	# Ö
	$string =~ s/\N{U+00DF}/&#x0DF;/g;	# ß
	$string =~ s/\N{U+00E1}/&#x0E1;/g;	# á - aacute
	$string =~ s/\N{U+00E2}/&#x0E2;/g;
	$string =~ s/\N{U+00E8}/&#x0E8;/g;	# è
	$string =~ s/\N{U+00EF}/&#x0EF;/g;	# ï
	$string =~ s/\N{U+00F0}/&#x0F0;/g;	# ð
	$string =~ s/\N{U+00F1}/&#x0F1;/g;	# ñ
	$string =~ s/\N{U+00F3}/&#x0F3;/g;	# ó
	$string =~ s/\N{U+00F4}/&#x0F4;/g;	# ô
	$string =~ s/\N{U+00F6}/&#x0F6;/g;	# ö
	$string =~ s/\N{U+00F8}/&#x0F8;/g;	# ø
	$string =~ s/\N{U+00FA}/&#x0FA;/g;	# ú
	$string =~ s/\N{U+00FC}/&#x0FC;/g;	# ü
	$string =~ s/\N{U+015B}/&#x15B;/g;	# ś
	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";
	$string =~ s/\N{U+00E9}/&#x0E9;/g;
	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";
	$string =~ s/\N{U+00E7}/&#x0E7;/g;	# ç
	$string =~ s/\N{U+00EB}/&#x0EB;/g;	# ë
	$string =~ s/\N{U+00FB}/&#x0FB;/g;	# û
	$string =~ s/\N{U+0160}/&#x160;/g;
	$string =~ s/\N{U+0161}/&#x161;/g;
	$string =~ s/\N{U+00A9}/&#x0A9;/g;	# ©
	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";
	$string =~ s/\N{U+2013}/-/g;
	$string =~ s/\N{U+2014}/-/g;
	$string =~ s/\N{U+201C}/&quot;/g;
	$string =~ s/\N{U+201D}/&quot;/g;
	$string =~ s/\N{U+2026}/.../g;	# …
	$string =~ s/\N{U+25CF}/&#x25CF;/g;	# ●

	# utf8::encode($string);
	# $string =~ s/š/&s#x161;/g;
	# $string =~ s/č/&#x10D;/g;
	# $string =~ s/ž/&z#x17E;/g;
	# $string =~ s/é/&#x0E9;/g;
	# $string =~ s/Ö/&#x0D6;/g;
	# $string =~ s/ç/&#x0E7;/g;
	# $string =~ s/\N{U+0161}/&#x161;/g;
	# $string =~ s/\N{U+010D}/&#x10D;/g;
	# $string =~ s/\N{U+017E}/&#x17E;/g;
	# $string =~ s/\N{U+00E9}/&#x0E9;/g;
	# $string =~ s/\N{U+00D6}/&#x0D6;/g;	# Ö
	# $string =~ s/\N{U+00E7}/&#x0E7;/g;	# ç

	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";

	# utf8::decode($string);

	# $string =~ s/['\x98]/&#039;/g;
	$string =~ s/'/&#039;/g;
	$string =~ s/\x98/&#039;/g;
	$string =~ s/©/&#x0A9;/g;
	$string =~ s/ª/&#x0AA;/g;
	$string =~ s/®/&#x0AE;/g;
	$string =~ s/å/&#x0E5;/g;
	$string =~ s/š/&#x161;/g;
	$string =~ s/č/&#x10D;/g;
	$string =~ s/ž/&#x17E;/g;
	$string =~ s/£/&#x0A3;/g;
	$string =~ s/á/&#x0E1;/g;	# á
	$string =~ s/â/&#x0E2;/g;
	$string =~ s/ä/&#x0E4;/g;	# ä
	$string =~ s/Á/&#x0C1;/g;	# Á
	$string =~ s/Ö/&#x0D6;/g;
	$string =~ s/ß/&#x0DF;/g;
	$string =~ s/ç/&#x0E7;/g;
	$string =~ s/è/&#x0E8;/g;
	$string =~ s/é/&#x0E9;/g;
	$string =~ s/ê/&#x0EA;/g;
	$string =~ s/ë/&#x0EB;/g;
	$string =~ s/í/&#x0ED;/g;
	$string =~ s/ï/&#x0EF;/g;
	$string =~ s/Î/&#x0CE;/g;	# Î
	$string =~ s/Þ/&#x0DE;/g;	# Þ
	$string =~ s/ð/&#x0F0;/g;	# ð
	$string =~ s/ø/&#x0F8;/g;	# ø
	$string =~ s/û/&#x0FB;/g;
	$string =~ s/ñ/&#x0F1;/g;
	$string =~ s/ú/&#x0FA;/g;
	$string =~ s/ü/&#x0FC;/g;
	$string =~ s/þ/&#x0FE;/g;	# þ
	# $string =~ s/[“”«»]/&quot;/g;
	$string =~ s/“/&quot;/g;
	$string =~ s/”/&quot;/g;
	$string =~ s/«/&quot;/g;
	$string =~ s/»/&quot;/g;
	$string =~ s/—/-/g;
	$string =~ s/…/.../g;
	$string =~ s/●/&#x25CF;/g;
	$string =~ s/\x80$/ /;

	# if($string =~ /^Maria\(/) {
		# print STDERR (unpack 'H*', $string);
		# print STDERR __LINE__, ': ';
		# print STDERR (sprintf '%v02X', $string);
		# print STDERR "\n";
		# my $i = 0;
		# while((my @call_details = caller($i++))) {
			# print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
		# }
		# die $string;
	# }

	# print STDERR __LINE__, ": ($string)\n";
	if($string =~ /[^[:ascii:]]/) {
		print STDERR (unpack 'H*', $string);
		print STDERR __LINE__, ': ';
		print STDERR (sprintf '%v02X', $string);
		print STDERR "\n";
		my $i = 0;
		while((my @call_details = caller($i++))) {
			print STDERR "\t", colored($call_details[2] . ' of ' . $call_details[1], 'red'), "\n";
		}
		$complain->("TODO: wide_to_xml($string)") if($complain);
		warn "TODO: wide_to_xml($string)";
		$string =~ s/[^[:ascii:]]/XXXXX/g;
		die "BUG: wide_to_xml($string)";
	}
	return $string;
}

=head1 SEE ALSO

L<HTML::Entities>, L<Encode>, L<XML::Entities>, L<Unicode::Escape>.

L<https://www.compart.com/en/unicode/>.

=head1 AUTHOR

Nigel Horne <njh@nigelhorne.com>

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
