use 5.010;
use strict;
use warnings;

package HTML::HTML5::Sanity;

BEGIN {
	$HTML::HTML5::Sanity::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::Sanity::VERSION   = '0.105';
}

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
	'all'       => [ qw(fix_document) ],
	'standard'  => [ qw(fix_document) ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT    = ( @{ $EXPORT_TAGS{'standard'} } );

our $FIX_LANG_ATTRIBUTES = 1;

use Locale::Country qw(country_code2code LOCALE_CODE_ALPHA_2 LOCALE_CODE_NUMERIC);
use XML::LibXML qw(:ns :libxml);

our $lang_3to2 = {
	'aar' => 'aa' ,
	'abk' => 'ab' ,
	'ave' => 'ae' ,
	'afr' => 'af' ,
	'aka' => 'ak' ,
	'amh' => 'am' ,
	'arg' => 'an' ,
	'ara' => 'ar' ,
	'asm' => 'as' ,
	'ava' => 'av' ,
	'aym' => 'ay' ,
	'aze' => 'az' ,
	'bak' => 'ba' ,
	'bel' => 'be' ,
	'bul' => 'bg' ,
	'bih' => 'bh' ,
	'bis' => 'bi' ,
	'bam' => 'bm' ,
	'ben' => 'bn' ,
	'tib' => 'bo' ,
	'bod' => 'bo' ,
	'bre' => 'br' ,
	'bos' => 'bs' ,
	'cat' => 'ca' ,
	'che' => 'ce' ,
	'cha' => 'ch' ,
	'cos' => 'co' ,
	'cre' => 'cr' ,
	'cze' => 'cs' ,
	'ces' => 'cs' ,
	'chu' => 'cu' ,
	'chv' => 'cv' ,
	'wel' => 'cy' ,
	'cym' => 'cy' ,
	'dan' => 'da' ,
	'ger' => 'de' ,
	'deu' => 'de' ,
	'div' => 'dv' ,
	'dzo' => 'dz' ,
	'ewe' => 'ee' ,
	'gre' => 'el' ,
	'ell' => 'el' ,
	'eng' => 'en' ,
	'epo' => 'eo' ,
	'spa' => 'es' ,
	'est' => 'et' ,
	'baq' => 'eu' ,
	'eus' => 'eu' ,
	'per' => 'fa' ,
	'fas' => 'fa' ,
	'ful' => 'ff' ,
	'fin' => 'fi' ,
	'fij' => 'fj' ,
	'fao' => 'fo' ,
	'fre' => 'fr' ,
	'fra' => 'fr' ,
	'fry' => 'fy' ,
	'gle' => 'ga' ,
	'gla' => 'gd' ,
	'glg' => 'gl' ,
	'grn' => 'gn' ,
	'guj' => 'gu' ,
	'glv' => 'gv' ,
	'hau' => 'ha' ,
	'heb' => 'he' ,
	'hin' => 'hi' ,
	'hmo' => 'ho' ,
	'hrv' => 'hr' ,
	'hat' => 'ht' ,
	'hat' => 'ht' ,
	'hun' => 'hu' ,
	'arm' => 'hy' ,
	'hye' => 'hy' ,
	'her' => 'hz' ,
	'ina' => 'ia' ,
	'ind' => 'id' ,
	'ile' => 'ie' ,
	'ibo' => 'ig' ,
	'iii' => 'ii' ,
	'ipk' => 'ik' ,
	'ido' => 'io' ,
	'ice' => 'is' ,
	'isl' => 'is' ,
	'ita' => 'it' ,
	'iku' => 'iu' ,
	'jpn' => 'ja' ,
	'jav' => 'jv' ,
	'geo' => 'ka' ,
	'kat' => 'ka' ,
	'kon' => 'kg' ,
	'kik' => 'ki' ,
	'kik' => 'ki' ,
	'kua' => 'kj' ,
	'kaz' => 'kk' ,
	'kal' => 'kl' ,
	'khm' => 'km' ,
	'kan' => 'kn' ,
	'kor' => 'ko' ,
	'kau' => 'kr' ,
	'kas' => 'ks' ,
	'kur' => 'ku' ,
	'kom' => 'kv' ,
	'cor' => 'kw' ,
	'kir' => 'ky' ,
	'lat' => 'la' ,
	'ltz' => 'lb' ,
	'ltz' => 'lb' ,
	'lug' => 'lg' ,
	'lim' => 'li' ,
	'lin' => 'ln' ,
	'lao' => 'lo' ,
	'lit' => 'lt' ,
	'lub' => 'lu' ,
	'lav' => 'lv' ,
	'mlg' => 'mg' ,
	'mah' => 'mh' ,
	'mao' => 'mi' ,
	'mri' => 'mi' ,
	'mac' => 'mk' ,
	'mkd' => 'mk' ,
	'mal' => 'ml' ,
	'mon' => 'mn' ,
	'mar' => 'mr' ,
	'may' => 'ms' ,
	'msa' => 'ms' ,
	'mlt' => 'mt' ,
	'bur' => 'my' ,
	'mya' => 'my' ,
	'nau' => 'na' ,
	'nob' => 'nb' ,
	'nde' => 'nd' ,
	'nep' => 'ne' ,
	'ndo' => 'ng' ,
	'dut' => 'nl' ,
	'nld' => 'nl' ,
	'nno' => 'nn' ,
	'nor' => 'no' ,
	'nbl' => 'nr' ,
	'nav' => 'nv' ,
	'nya' => 'ny' ,
	'oci' => 'oc' ,
	'oji' => 'oj' ,
	'orm' => 'om' ,
	'ori' => 'or' ,
	'oss' => 'os' ,
	'pan' => 'pa' ,
	'pli' => 'pi' ,
	'pol' => 'pl' ,
	'pus' => 'ps' ,
	'por' => 'pt' ,
	'que' => 'qu' ,
	'roh' => 'rm' ,
	'run' => 'rn' ,
	'rum' => 'ro' ,
	'ron' => 'ro' ,
	'rus' => 'ru' ,
	'kin' => 'rw' ,
	'san' => 'sa' ,
	'srd' => 'sc' ,
	'snd' => 'sd' ,
	'sme' => 'se' ,
	'sag' => 'sg' ,
	'sin' => 'si' ,
	'slo' => 'sk' ,
	'slk' => 'sk' ,
	'slv' => 'sl' ,
	'smo' => 'sm' ,
	'sna' => 'sn' ,
	'som' => 'so' ,
	'alb' => 'sq' ,
	'sqi' => 'sq' ,
	'srp' => 'sr' ,
	'ssw' => 'ss' ,
	'sot' => 'st' ,
	'sun' => 'su' ,
	'swe' => 'sv' ,
	'swa' => 'sw' ,
	'tam' => 'ta' ,
	'tel' => 'te' ,
	'tgk' => 'tg' ,
	'tha' => 'th' ,
	'tir' => 'ti' ,
	'tuk' => 'tk' ,
	'tgl' => 'tl' ,
	'tsn' => 'tn' ,
	'ton' => 'to' ,
	'tur' => 'tr' ,
	'tso' => 'ts' ,
	'tat' => 'tt' ,
	'twi' => 'tw' ,
	'tah' => 'ty' ,
	'uig' => 'ug' ,
	'ukr' => 'uk' ,
	'urd' => 'ur' ,
	'uzb' => 'uz' ,
	'ven' => 've' ,
	'vie' => 'vi' ,
	'vol' => 'vo' ,
	'wln' => 'wa' ,
	'wol' => 'wo' ,
	'xho' => 'xh' ,
	'yid' => 'yi' ,
	'yor' => 'yo' ,
	'zha' => 'za' ,
	'chi' => 'zh' ,
	'zho' => 'zh' ,
	'zul' => 'zu' ,
};

our $lang_grandfather = {
	'art-lojban'       => 'jbo',
	'i-ami'            => 'ami',
	'i-bnn'            => 'bnn',
	'i-hak'            => 'hak',
	'i-klingon'        => 'tlh',
	'i-lux'            => 'lb',
	'i-navajo'         => 'nv',
	'i-pwn'            => 'pwn', #haha
	'i-tao'            => 'tao',
	'i-tay'            => 'tay',
	'i-tsu'            => 'tsu',
	'no-bok'           => 'nb',
	'no-nyn'           => 'nn',
	'sgn-be-fr'        => 'sfb',
	'sgn-be-nl'        => 'vgt',
	'sgn-ch-de'        => 'sgg',
	'zh-guoyu'         => 'cmn',
	'zh-hakka'         => 'hak',
	'zh-min-nan'       => 'nan',
	'zh-xiang'         => 'hsn',
	};

our $obsolete_iso3166 = {
	'UK' => 'GB',   # Exceptionally reserved
	'FX' => 'FR',   # Exceptionally reserved
	'ZR' => 'CD',   # Zaire => Congo
	'HV' => 'BF',   # Upper Volta => Burkina Faso
	'DY' => 'BJ',   # Dahomey => Benin
	'BU' => 'MM',   # Burma => Myanmar
	'TP' => 'TL',   # East Timor => Timor-Leste
	'NH' => 'VU',   # New Hebrides => Vanuatu
	'RH' => 'ZW',   # Rhodesia => Zimbabwe
};

our $canon_lang = {};

sub fix_document
{
	my $old_document        = shift;
	my $attribute_behaviour = shift || 0;
	
	my $new_document        = XML::LibXML::Document->new;
	
	my $new_root = fix_element(
		$old_document->documentElement,
		$new_document,
		{ ':' => 'http://www.w3.org/1999/xhtml', 'xml' => XML_XML_NS }
		);
		
	$new_document->setDocumentElement($new_root);
	
	return $new_document;
}

sub fix_element
{
	my $old_element         = shift;
	my $new_document        = shift;
	my $parent_declarations = shift;
	
	my $declared_namespaces = {};
	foreach my $k (keys %{$parent_declarations})
	{
		$declared_namespaces->{$k} = $parent_declarations->{$k};
	}
	
	# Process namespace declarations on this element.
	foreach my $attr ($old_element->attributes)
	{
		next if $attr->nodeType == XML_NAMESPACE_DECL;
		
		if ($attr->nodeName =~ /^xmlns:(.*)$/)
		{
			my $prefix = $1;
			
			if ($prefix eq 'xml' && $attr->getData eq XML_XML_NS)
			{
				# that's OK.
			}
			elsif ($prefix eq 'xml' || $attr->getData eq XML_XML_NS)
			{
				next;
			}
			elsif ($prefix eq 'xmlns' || $attr->getData eq XML_XMLNS_NS)
			{
				next;
			}
			
			$declared_namespaces->{ $prefix } = $attr->getData;
		}
	}
	
	# Process any default XML Namespace
	my $hasExplicit = 0;
	if ($old_element->hasAttributeNS(undef, 'xmlns'))
	{
		$hasExplicit = 1;
		$declared_namespaces->{ ':' } = $old_element->getAttributeNS(undef, 'xmlns');
	}
	
	# Create a new element.
	my $new_element;
	if ($hasExplicit)
	{
		$new_element = $new_document->createElementNS(
			$declared_namespaces->{ ':' },
			$old_element->nodeName,
			);
	}
	else
	{
		my $tag = $old_element->nodeName;
		if ($tag =~ /^([^:]+)\:([^:]+)$/)
		{
			my $ns_prefix = $1;
			my $localname = $2;
			
			if (defined $declared_namespaces->{$ns_prefix})
			{
				$new_element = $new_document->createElementNS(
					$declared_namespaces->{$ns_prefix},	$tag);
			}
		}
		unless ($new_element)
		{
			$new_element = $new_document->createElementNS(
				$declared_namespaces->{ ':' }, $tag);
		}
	}
	
	# Add attributes to new element.
	foreach my $old_attr ($old_element->attributes)
	{
		next if $old_attr->nodeType == XML_NAMESPACE_DECL;
		# next if $old_attr->nodeName =~ /^xmlns(:.*)?$/;
		
		fix_attribute($old_attr, $new_element, $declared_namespaces);
	}
	
	# Process child nodes.
	foreach my $old_kid ($old_element->childNodes)
	{
		if ($old_kid->nodeType == XML_TEXT_NODE
		||  $old_kid->nodeType == XML_CDATA_SECTION_NODE)
		{
			$new_element->appendTextNode($old_kid->nodeValue);
		}
		elsif ($old_kid->nodeType == XML_COMMENT_NODE)
		{
			$new_element->appendChild(
				$new_document->createComment($old_kid->nodeValue)
				);
		}
		elsif ($old_kid->nodeType == XML_ELEMENT_NODE)
		{
			$new_element->appendChild(
				fix_element($old_kid, $new_document, $declared_namespaces)
				);
		}
	}
	
	return $new_element;
}

sub fix_attribute
{
	my $old_attribute       = shift;
	my $new_element         = shift;
	my $declared_namespaces = shift;
	
	my $name = $old_attribute->nodeName;
	my @new_attribute;
	
	if ($name =~ /^([^:]+)\:([^:]+)$/)
	{
		my $ns_prefix = $1;
		my $localname = $2;
		
		if (defined $declared_namespaces->{$ns_prefix})
		{
			@new_attribute = (
				$declared_namespaces->{$ns_prefix},
				sprintf("%s:%s", $ns_prefix, $localname),
				);
		}
	}
	
	my $node_value = $old_attribute->nodeValue;
	
	if ($FIX_LANG_ATTRIBUTES && $name =~ /^(xml:)?lang$/i)
	{
		return undef
			unless _valid_lang($node_value);
		
		if ($FIX_LANG_ATTRIBUTES == 2)
		{
			$node_value = _canon_lang($node_value);
		}
	}
	
	if (@new_attribute)
	{
		$new_element->setAttributeNS(@new_attribute, $node_value);
	}
	else
	{
		$new_element->setAttribute($name, $node_value);
	}
	
	return undef;
}

sub _valid_lang
{
	my $value_to_test = shift;

	return 1 if (defined $value_to_test) && ($value_to_test eq '');
	return 0 unless defined $value_to_test;
	
	# Regex for recognizing RFC 4646 well-formed tags
	# http://www.rfc-editor.org/rfc/rfc4646.txt
	# http://tools.ietf.org/html/draft-ietf-ltru-4646bis-21

	# The structure requires no forward references, so it reverses the order.
	# It uses Java/Perl syntax instead of the old ABNF
	# The uppercase comments are fragments copied from RFC 4646

	# Note: the tool requires that any real "=" or "#" or ";" in the regex be escaped.

	my $alpha      = '[a-z]';      # ALPHA
	my $digit      = '[0-9]';      # DIGIT
	my $alphanum   = '[a-z0-9]';   # ALPHA / DIGIT
	my $x          = 'x';          # private use singleton
	my $singleton  = '[a-wyz]';    # other singleton
	my $s          = '[_-]';       # separator -- lenient parsers will use [_-] -- strict will use [-]

	# Now do the components. The structure is slightly different to allow for capturing the right components.
	# The notation (?:....) is a non-capturing version of (...): so the "?:" can be deleted if someone doesn't care about capturing.

	my $language   = '([a-z]{2,8}) | ([a-z]{2,3} [_-] [a-z]{3})';
	
	# ABNF (2*3ALPHA) / 4ALPHA / 5*8ALPHA  --- note: because of how | works in regex, don't use $alpha{2,3} | $alpha{4,8} 
	# We don't have to have the general case of extlang, because there can be only one extlang (except for zh-min-nan).

	# Note: extlang invalid in Unicode language tags

	my $script = '[a-z]{4}' ;   # 4ALPHA 

	my $region = '(?: [a-z]{2}|[0-9]{3})' ;    # 2ALPHA / 3DIGIT

	my $variant    = '(?: [a-z0-9]{5,8} | [0-9] [a-z0-9]{3} )' ;  # 5*8alphanum / (DIGIT 3alphanum)

	my $extension  = '(?: [a-wyz] (?: [_-] [a-z0-9]{2,8} )+ )' ; # singleton 1*("-" (2*8alphanum))

	my $privateUse = '(?: x (?: [_-] [a-z0-9]{1,8} )+ )' ; # "x" 1*("-" (1*8alphanum))

	# Define certain grandfathered codes, since otherwise the regex is pretty useless.
	# Since these are limited, this is safe even later changes to the registry --
	# the only oddity is that it might change the type of the tag, and thus
	# the results from the capturing groups.
	# http://www.iana.org/assignments/language-subtag-registry
	# Note that these have to be compared case insensitively, requiring (?i) below.

	my $grandfathered  = '(?:
			  (en [_-] GB [_-] oed)
			| (i [_-] (?: ami | bnn | default | enochian | hak | klingon | lux | mingo | navajo | pwn | tao | tay | tsu ))
			| (no [_-] (?: bok | nyn ))
			| (sgn [_-] (?: BE [_-] (?: fr | nl) | CH [_-] de ))
			| (zh [_-] min [_-] nan)
			)';

	# old:         | zh $s (?: cmn (?: $s Hans | $s Hant )? | gan | min (?: $s nan)? | wuu | yue );
	# For well-formedness, we don't need the ones that would otherwise pass.
	# For validity, they need to be checked.

	# $grandfatheredWellFormed = (?:
	#         art $s lojban
	#     | cel $s gaulish
	#     | zh $s (?: guoyu | hakka | xiang )
	# );

	# Unicode locales: but we are shifting to a compatible form
	# $keyvalue = (?: $alphanum+ \= $alphanum+);
	# $keywords = ($keyvalue (?: \; $keyvalue)*);

	# We separate items that we want to capture as a single group

	my $variantList   = $variant . '(?:' . $s . $variant . ')*' ;     # special for multiples
	my $extensionList = $extension . '(?:' . $s . $extension . ')*' ; # special for multiples

	my $langtag = "
			($language)
			($s ( $script ) )?
			($s ( $region ) )?
			($s ( $variantList ) )?
			($s ( $extensionList ) )?
			($s ( $privateUse ) )?
			";

	# Here is the final breakdown, with capturing groups for each of these components
	# The variants, extensions, grandfathered, and private-use may have interior '-'
	
	my $r = ($value_to_test =~ 
		/^(
			($langtag)
		 | ($privateUse)
		 | ($grandfathered)
		 )$/xi);
	return $r;
}

# If people use a non-canon lang once, they're likely to do it twice, so a little caching.
sub _canon_lang
{
	my $lang = shift;
	unless (defined $canon_lang->{$lang})
	{
		$canon_lang->{$lang} = __canon_lang($lang);
	}
	return $canon_lang->{$lang};
}

sub __canon_lang
{
	# Use lower case only
	my $lang = lc shift;

	# If there's a 2 letter code where a three letter code has been used, replace it.
	if ($lang =~ /^([a-z]{3})/)
	{
		substr($lang, 0, 3) = $lang_3to2->{$1}
			if defined $lang_3to2->{$1};
	}
	
	return $lang_grandfather->{$lang}
		if defined $lang_grandfather->{$lang};

	# Simple case.
	return $lang if length $lang < 4;

	# Replace '_' with '-'.
	$lang =~ s/_/-/g;
	
	# upper case the country component of lang-country pairs.
	return sprintf('%s-%s', $1, _canon_country($2))
		if $lang =~ /^([a-z]{2,3})-([a-z]{2}|\d{3})$/;

	# title case the script component of lang-script pairs.
	return sprintf('%s-%s', $1, _canon_script($2))
		if $lang =~ /^([a-z]{2,3})-([a-z]{4})$/;

	# title case the script component, upper case country componet of lang-script-country triplets.
	return sprintf('%s-%s-%s', $1, _canon_script($2), _canon_country($3))
		if $lang =~ /^([a-z]{2,3})-([a-z]{4})-([a-z]{2}|\d{3})$/;

	# Too complicated - give up and return lower case.
	return $lang;
}

sub _canon_country
{
	my $c = uc shift;

	if ($c =~ /^\d\d\d$/)
	{
		my $c1 = country_code2code($c, LOCALE_CODE_NUMERIC, LOCALE_CODE_ALPHA_2);
		$c = uc $c1
			if defined $c1 && length $c1;
	}

	return $obsolete_iso3166->{$c}
		if defined $obsolete_iso3166->{$c};
	
	return $c;
}

sub _canon_script
{
	my $s = ucfirst lc shift;
	return $s;
}

1;

__END__

=head1 NAME

HTML::HTML5::Sanity - make HTML5 DOM trees less insane

=head1 SYNOPSIS

  use HTML::HTML5::Parser;
  use HTML::HTML5::Sanity;
  
  my $parser    = HTML::HTML5::Parser->new;
  my $html5_dom = $parser->parse_file('http://example.com/');
  my $sane_dom  = fix_document($html5_dom);

=head1 DESCRIPTION

The Document Object Model (DOM) generated by HTML::HTML5::Parser meets
the requirements of the HTML5 spec, but will probably catch a lot of
people by surprise.

The main oddity is that elements and attributes which appear to be
namespaced are not really. For example, the following element:

  <div xml:lang="fr">...</div>

Looks like it should be parsed so that it has an attribute "lang" in
the XML namespace. Not so. It will really be parsed as having the
attribute "xml:lang" in the null namespace.

=over 4

=item C<< fix_document($document) >>

  $sane_dom = fix_document($html5_dom);

Returns a modified copy of the DOM and leaving the original DOM
unmodified.

=item C<< fix_element($element_node, $new_document_node, \%namespaces) >>

Don't use this. Not exported.

=item C<< fix_attribute($attribute_node, $new_element_node, \%namespaces) >>

Don't use this. Not exported.

=item C<$HTML::HTML5::Sanity::FIX_LANG_ATTRIBUTES>

  $HTML::HTML5::Sanity::FIX_LANG_ATTRIBUTES = 2;
  $sane_dom = fix_document($html5_dom);

If set to 1 (the default), the package will detect invalid values in
@lang and @xml:lang, and remove the attribute if it is invalid. If set
to 2, it will also attempt to canonicalise the value (e.g. 'EN_GB' will
be converted to to 'en-GB'). If set to 0, then the value of language
attributes is not checked.

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<HTML::HTML5::Parser>, L<XML::LibXML>, L<Task::HTML5>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2014 by Toby Inkster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
