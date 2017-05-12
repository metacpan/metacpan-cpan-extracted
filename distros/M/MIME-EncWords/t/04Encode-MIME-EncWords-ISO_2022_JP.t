# -*- perl -*-

use strict;
use Test::More;

BEGIN {
    if( ord("A") == 193 ) {
	plan skip_all => 'No Encode::MIME::EncWords on EBCDIC Platforms';
    } elsif ($] < 5.007003) {
	plan skip_all => 'Unicode/multibyte support is not available';
    } else {
	plan tests => 14;
    }
}

BEGIN{
    use_ok('Encode::MIME::EncWords');
}

require_ok('Encode::MIME::EncWords');

# Codes below are derived from mime_header_iso2022jp.t in Encode,
# originally from mime.t in Jcode.
# Non-ASCII characters are escaped but code values are intact.

my %mime = (
    "\xb4\xc1\xbb\xfa\xa1\xa2\xa5\xab\xa5\xbf\xa5\xab\xa5\xca\xa1\xa2\xa4\xd2\xa4\xe9\xa4\xac\xa4\xca"
     => "=?ISO-2022-JP?B?GyRCNEE7eiEiJSslPyUrJUohIiRSJGkkLCRKGyhC?=",
    "foo bar"
     => "foo bar",
    "\xb4\xc1\xbb\xfa\xa1\xa2\xa5\xab\xa5\xbf\xa5\xab\xa5\xca\xa1\xa2\xa4\xd2\xa4\xe9\xa4\xac\xa4\xca\xa4\xce\xba\xae\xa4\xb8\xa4\xc3\xa4\xbfSubject Header."
     => "=?ISO-2022-JP?B?GyRCNEE7eiEiJSslPyUrJUohIiRSJGkkLCRKJE46LiQ4JEMkPxsoQlN1?=\n =?ISO-2022-JP?B?YmplY3Q=?= Header.",
);


for my $k (keys %mime){
    $mime{"$k\n"} = $mime{$k} . "\n";
}


for my $decoded (sort keys %mime){
    my $encoded = $mime{$decoded};

    my $header = Encode::encode('MIME-EncWords-ISO_2022_JP', Encode::decode('euc-jp', $decoded));
    my $utf8   = Encode::decode('MIME-EncWords', $header);

    is(Encode::encode('euc-jp', $utf8), $decoded);
    is($header, $encoded);
}

__END__
