package Encode::Wide;

# TODO: don't transform anything within <script>...</script> in wide_to_html

use strict;
use warnings;

use Exporter qw(import);
use HTML::Entities;
use Params::Get 0.13;
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

Encode::Wide - Convert wide characters (Unicode, UTF-8, etc.) into HTML or XML-safe ASCII entities

=head1 VERSION

0.06

=cut

our $VERSION = 0.06;

=head1 SYNOPSIS

    use Encode::Wide qw(wide_to_html wide_to_xml);

    my $html = wide_to_html(string => "Café déjà vu – naïve façade");
    # returns: 'Caf&eacute; d&eacute;j&agrave; vu &ndash; na&iuml;ve fa&ccedil;ade'

    my $xml = wide_to_xml(string => "Café déjà vu – naïve façade");
    # returns: 'Caf&#xE9; d&#xE9;j&#xE0; vu &#x2013; na&#xEF;ve fa&#xE7;ade'

=head1 DESCRIPTION

Encode::Wide provides functions for converting wide (Unicode) characters into ASCII-safe
formats suitable for embedding in HTML or XML documents.
It is especially useful when dealing with text containing accented or typographic characters that need
to be safely represented in markup.

Other modules exist to do this,
however they tend to have assumptions on the input,
whereas this should work with UTF-8, Unicode, or anything that's common.

The module offers two exportable functions:

=over 4

=item * C<wide_to_html(string => $text)>

Converts all non-ASCII characters in the input string to their named HTML entities if available,
or hexadecimal numeric entities otherwise.
Common characters such as `é`, `à`, `&`, `<`, `>` are
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

Input strings are expected to be valid UTF-8 or Unicode.
If a byte string is passed, the module will attempt to decode it appropriately.
Output is guaranteed to be pure ASCII.

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

	if(ref($string) eq 'SCALAR') {
		$string = ${$string};
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

	# I don't think HTML::Entities does these
	my %entity_map = (
		'&ccaron;' => 'č',
		'&zcaron;' => 'ž',
		'&Scaron;' => 'Š',
	);

	$string =~ s{
		# ([\x80-\x{10FFFF}])
		(.)
	}{
		my $cp = $1;
		exists $entity_map{$cp}
			? $entity_map{$cp}
			: $cp
	}gex;

	# Escape only if it's not already part of an entity
	$string =~ s/&(?![A-Za-z#0-9]+;)/&amp;/g;

	unless($params->{'keep_hrefs'}) {
		%entity_map = (
			'<' => '&lt;',
			'>' => '&gt;',
			'"' => '&quot;',
		);
		$string =~ s{(.)}{
			my $cp = $1;
			exists $entity_map{$cp}
				? $entity_map{$cp}
				: $cp
		}gex;
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
		# We can't combine since each char in the multi-byte matches, not the entire multi-byte
		# $string =~ s/['‘’‘\x98]/&apos;/g;
		%entity_map = (
			"'" => '&apos;',
			'‘' => '&apos;',
			'’' => '&apos;',
			'‘' => '&apos;',
			"\x98" => '&apos;',
		);

		$string =~ s{
			# ([\x80-\x{10FFFF}])
			(.)
		}{
			my $cp = $1;
			exists $entity_map{$cp}
				? $entity_map{$cp}
				: $cp
		}gex;
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
		["\N{U+017E}", '&zcaron;'],
		["\N{U+00C9}", '&Eacute;'],
		["\N{U+00D6}", '&Ouml;'],	# Ö
		["\N{U+00DF}", '&szlig;'],	# ß
		["\N{U+00E1}", '&aacute;'],	# á
		["\N{U+00E2}", '&acirc;'],
		["\N{U+00E4}", '&auml;'],
		["\N{U+00E5}", '&aring;'],	# å
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
		["\N{U+25CF}", '&#x25CF;'],	# ●
	);

	$string = _sub_map(\$string, \@byte_map);

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

	@byte_map = (
		[ 'Á', '&Aacute;' ],
		[ 'å', '&aring;' ],
		[ 'ª', '&ordf;' ],
		[ 'š', '&scaron;' ],
		[ 'Š', '&Scaron;' ],
		[ 'č', '&ccaron;' ],
		[ 'ž', '&zcaron;' ],
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
		[ 'Î', '&Iicrc;' ],
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
		[ '●', '&#x25CF;' ],
		[ "\x80\$", ' ' ],
	);

	$string = _sub_map(\$string, \@byte_map);

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
			# $string =~ s/[^[:ascii:]]/XXXXX/g;
			$string =~ s{
					([^[:ascii:]])
				}{
					'>>>>' . sprintf("%04X", ord($1)) . '<<<<'
				}gex;	# e=evaluate, g=global, x=extended
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

	if(ref($string) eq 'SCALAR') {
		$string = ${$string};
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

	# I don't think HTML::Entities does these
	my %entity_map = (
		'&ccaron;' => 'č',
		'&zcaron;' => 'ž',
		'&Scaron;' => 'Š',
	);

	$string =~ s{
		# ([\x80-\x{10FFFF}])
		(.)
	}{
		my $cp = $1;
		exists $entity_map{$cp}
			? $entity_map{$cp}
			: $cp
	}gex;

	# Escape only if it's not already part of an entity
	$string =~ s/&(?![A-Za-z#0-9]+;)/&amp;/g;

	unless($params->{'keep_hrefs'}) {
		%entity_map = (
			'<' => '&lt;',
			'>' => '&gt;',
			'"' => '&quot;',
			'“' => '&quot;',	# U+201C
			'”' => '&quot;',	# U+201D
		);

		$string =~ s{(.)}{
			my $cp = $1;
			exists $entity_map{$cp}
				? $entity_map{$cp}
				: $cp
		}gex;
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

	%entity_map = (
		'&copy;' => '&#x0A9;',
		'&Aacute;' => '&#x0C1;',	# Á
		'&ccaron;' => '&#x10D;',
		'&agrave;' => '&#x0E0;',	# á
		'&aacute;' => '&#x0E1;',	# á
		'&acirc;' => '&#x0E2;',		# â
		'&auml;' => '&#x0E4;',		# ä
		'&aring;' => '&#x0E5;',	# å
		'&ccedil;' => '&#x0E7;',	# ç
		'&egrave;' => '&#x0E8;',
		'&eacute;' => '&#x0E9;',
		'&ecirc;' => '&#x0EA;',
		'&euml;' => '&#x0EB;',	# euml
		'&Icirc;' => '&#x0CE;',	# Î
		'&Eacute;' => '&#x0C9;',
		'&szlig;' => '&#x0DF;',	# ß
		'&iacute;' => '&#xED;',	# í
		'&icirc;' => '&#x0EE;',
		'&iuml;' => '&#x0EF;',	# ï
		'&eth;' => '&#x0F0;',	# ð
		'&uacute;' => '&#0FA;',	# ú
		'&uuml;' => '&#x0FC;',
		'&scaron;' => '&#x161;',
		'&oacute;' => '&#x0F3;',	# ó
		'&ucirc;' => '&#x0F4;',
		'&ouml;' => '&#x0F6;',
		'&ordf;' => '&#x0AA;',	# ª
		'&oslash;' => '&#x0F8;',	# ø
		'&zcaron;' => '&#x17E;',
		'&Scaron;' => '&#x160;',
		'&THORN;' => '&#x0DE;',	# Þ
		'&thorn;' => '&#x0FE;',	# þ
		'&reg;' => '&#x0AE;',
		'&pound;' => '&#163;',
		'&ntilde;' => '&#x0F1;',
		'&mdash;' => '-',
		'&ndash;' => '-',
		'&excl;' => '!',
	);

	$string =~ s{(.)}{
		my $cp = $1;
		exists $entity_map{$cp}
			? $entity_map{$cp}
			: $cp
	}gex;

	if($string !~ /[^[:ascii:]]/) {
		return $string;
	}

	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";

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

	# $string =~ s/\xe4\x8d/&#x10D;/g;	# ? ACOM strangeness
	# $string =~ s/\N{U+0161}/&#x161;/g;
	# $string =~ s/\N{U+010D}/&#x10D;/g;
	# $string =~ s/\N{U+00E9}/&#x0E9;/g;
	# $string =~ s/\N{U+017E}/&#x17E;/g;

		["\N{U+00A0}", ' '],
		["\N{U+010D}", '&#x10D;'],
		["\N{U+00AB}", '&quot;'],	# «
		["\N{U+00AE}", '&#x0AE;'],	# ®
		["\N{U+00B5}", '&#x0B5;'],	# µ
		["\N{U+00C1}", '&#x0C1;'],	# Á
		["\N{U+00CE}", '&#x0CE;'],	# Î
		["\N{U+00DE}", '&#x0DE;'],	# Þ
		["\N{U+00E4}", '&#x0E4;'],	# ä
		["\N{U+00E5}", '&#x0E5;'],	# å
		["\N{U+00EA}", '&#x0EA;'],
		["\N{U+00ED}", '&#x0ED;'],
		["\N{U+00EE}", '&#x0EE;'],
		["\N{U+00FE}", '&#x0FE;'],	# þ
		["\N{U+00C9}", '&#x0C9;'],
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
	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";
		["\N{U+00E9}", '&#x0E9;'],
	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";
		["\N{U+00E7}", '&#x0E7;'],	# ç
		["\N{U+00EB}", '&#x0EB;'],	# ë
		["\N{U+00FB}", '&#x0FB;'],	# û
		["\N{U+0160}", '&#x160;'],
		["\N{U+0161}", '&#x161;'],
		["\N{U+00A9}", '&#x0A9;'],	# ©
	# print STDERR __LINE__, ": ($string)";
	# print STDERR (sprintf '%v02X', $string);
	# print STDERR "\n";
		["\N{U+2013}", '-'],
		["\N{U+2014}", '-'],
		["\N{U+2018}", '&quot;'],
		["\N{U+2019}", '&quot;'],
		["\N{U+201C}", '&quot;'],
		["\N{U+201D}", '&quot;'],
		["\N{U+2026}", '...'],	# …
		["\N{U+25CF}", '&#x25CF;'],	# ●
	);

	$string = _sub_map(\$string, \@byte_map);

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
	@byte_map = (
		["'", '&#039;'],
		["\x98", '&#039;'],
		['©', '&#x0A9;'],
		['ª', '&#x0AA;'],
		['®', '&#x0AE;'],
		['å', '&#x0E5;'],
		['š', '&#x161;'],
		['č', '&#x10D;'],
		['ž', '&#x17E;'],
		['£', '&#x0A3;'],
		['µ', '&#x0B5;'],
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
		['●', '&#x25CF;'],
		["\x80\$", ' '],
	);

	$string = _sub_map(\$string, \@byte_map);

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
		# $string =~ s/[^[:ascii:]]/XXXXX/g;
		$string =~ s{
				([^[:ascii:]])
			}{
				'>>>>' . sprintf("%04X", ord($1)) . '<<<<'
			}gex;	# e=evaluate, g=global, x=extended
		die "BUG: wide_to_xml($string)";
	}
	return $string;
}

sub _sub_map
{
	my $string = ${$_[0]};
	my $byte_map = $_[1];

	# Build an alternation sorted by longest sequence first
	my $pattern = join '|',
		map { quotemeta($_->[0]) }
		sort { length $b->[0] <=> length $a->[0] }
		@{$byte_map};

	$string =~ s/($pattern)/do {
		my $bytes = $1;
		my ($pair) = grep { $_->[0] eq $bytes } @{$byte_map};
		$pair->[1];
	}/ge;

	return $string;
}

=head1 SEE ALSO

=over 4

=item * Test coverage report: L<https://nigelhorne.github.io/Encode-Wide/coverage/>

=item * L<HTML::Entities>

=item * L<Encode>

=item * L<XML::Entities>

=item * L<Unicode::Escape>

=item * L<https://www.compart.com/en/unicode/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-encode-wide at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Encode-Wide>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

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
