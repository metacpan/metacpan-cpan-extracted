use strict;
use Test::More;

BEGIN {
    if ($] < 5.007003) {
	plan tests => 29;
    } else {
	if ($] < 5.008) { # Perl 5.7.3 + Encode 0.04
	    require Encode::CN;
	}
	plan tests => 33;
    }
}

my @names = qw(
	    US-ASCII
	    ISO-8859-1 ISO-8859-2 ISO-8859-3 ISO-8859-4 ISO-8859-5
	    ISO-8859-6 ISO-8859-7 ISO-8859-8 ISO-8859-9 ISO-8859-10
	    SHIFT_JIS EUC-JP ISO-2022-KR EUC-KR ISO-2022-JP ISO-2022-JP-2
	    ISO-8859-6-I ISO-8859-6-E ISO-8859-8-E ISO-8859-8-I
	    GB2312 BIG5 KOI8-R
	    UTF-8 UTF-16 UTF-32
	    HZ-GB-2312
	    TIS-620
	   );

use MIME::Charset qw(:info);

foreach my $name (@names) {
    my $obj = MIME::Charset->new($name);
    is($obj->as_string, $name, $name);
    if (&MIME::Charset::USE_ENCODE and
	($name eq 'HZ-GB-2312' or $name eq 'TIS-620' or $name eq 'UTF-16' or
	$name eq 'UTF-32')) {
	is($obj->decoder ? 'defined' : undef, 'defined', "$name available");
	diag("$name is decoded by '".$obj->decoder->name."' encoding")
	    if $obj->decoder;
    }
}
