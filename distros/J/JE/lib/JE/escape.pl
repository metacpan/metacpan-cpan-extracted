package JE;

use strict;
use warnings; no warnings 'utf8';
use Encode 2.08 qw< decode_utf8 encode_utf8 FB_CROAK >;

sub _decodeURI {
	my $global = shift;
	my $str = shift;
	$str = defined $str ? $str->to_string->value : 'undefined';
	$str =~ /%(?![a-fA-F0-9]{2})(.{0,2})/
	 and require JE::Object::Error::URIError,
	     die
		JE::Object::Error::URIError->new(
			$global,
			add_line_number
				"Invalid escape %$1 in URI"
		);

	$str = encode_utf8 $str;

	# [;/?:@&=+$,#] do not get unescaped
	$str =~ s/%(?!2[346bcf]|3[abdf]|40)
		([0-9a-f]{2})/chr hex $1/iegx;
	
	if (do{
		local $@;
		eval {
			$str = decode_utf8 $str, FB_CROAK;
		};
		$@
	}) {
		require JE'Object'Error'URIError;
		die JE::Object::Error::URIError
		->new(
			$global,
			add_line_number
				'Malformed UTF-8 in URI'
		);
	}
	
	$str =~
	     /^[\0-\x{10ffff}]*\z/
	or require JE::Object::Error::URIError,
	   die JE::Object::Error::URIError->new(
		$global, add_line_number
			'Malformed UTF-8 in URI');

	JE::String->_new($global, $str);
}

sub _decodeURIComponent {
	my $global = shift;
	my $str = shift;
	$str = defined $str ? $str->to_string->value : 'undefined';
	$str =~ /%(?![a-fA-F0-9]{2})(.{0,2})/
	 and require JE::Object::Error::URIError,
	     die
		JE::Object::Error::URIError->new(
			$global,
			add_line_number
				"Invalid escape %$1 in URI"
		);

	$str = encode_utf8 $str;

	# [;/?:@&=+$,#] do not get unescaped
	$str =~ s/%([0-9a-f]{2})/chr hex $1/iegx;
	
	if (do{
		local $@;
		eval {
			$str = decode_utf8 $str, FB_CROAK;
		};
		$@
	}) {
		require JE'Object'Error'URIError;
		die JE::Object::Error::URIError
		->new(
			$global,
			add_line_number
				'Malformed UTF-8 in URI'
		);
	}
	
	$str =~
	     /^[\0-\x{10ffff}]*\z/
	or require JE::Object::Error::URIError,
	   die JE::Object::Error::URIError->new(
		$global, add_line_number
			'Malformed UTF-8 in URI');

	JE::String->_new($global, $str);
}

sub _encodeURI {
	my $global = shift;
	my $str = shift;
	$str = defined $str ? $str->to_string->value : 'undefined';
	$str =~ /(\p{Cs})/ and
		require JE::Object::Error::URIError,
		die JE::Object::Error::URIError->new($global, 
			add_line_number sprintf
				"Unpaired surrogate 0x%x in string", ord $1
		);

	$str = encode_utf8 $str;

	$str =~
		s< ([^;/?:@&=+\$,A-Za-z0-9\-_.!~*'()#]) >
		 < sprintf '%%%02X', ord $1           >egx;
	
	JE::String->_new($global, $str);
}

sub _encodeURIComponent {
	my $global = shift;
	my $str = shift;
	$str = defined $str ? $str->to_string->value : 'undefined';
	$str =~ /(\p{Cs})/ and
		require JE::Object::Error::URIError,
		die JE::Object::Error::URIError->new(
			$global, add_line_number sprintf
				"Unpaired surrogate 0x%x in string", ord $1
	);

	$str = encode_utf8 $str;

	$str =~ s< ([^A-Za-z0-9\-_.!~*'()])  >
	         < sprintf '%%%02X', ord $1 >egx;
	
	JE::String->_new($global, $str);
}

sub _escape {
	my $global = shift;
	my $str = defined $_[0] ? shift->to_string->value16 : 'undefined';
	no warnings 'utf8';
	$str =~ s< ([^A-Za-z0-9\@*_+\-./])  >
	         [ sprintf '%%' . (
	               ord $1 <= 0xff
	               ? '%02'
	               : 'u%04'
	           ) . 'x', ord $1          ]egx;
	JE::String->_new($global, $str);
}

sub _unescape {
	my $global = shift;
	my $str = defined $_[0] ? shift->to_string->value16 : 'undefined';
	$str =~s<%(?:u([a-f0-9]{4})|([a-f0-9]{2}))>
	        < chr hex $+ >egix;
	JE::String->_new($global, $str);
}

1
