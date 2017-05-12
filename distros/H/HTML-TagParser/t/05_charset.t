# ----------------------------------------------------------------
    use strict;
    use bytes;
    use Test::More tests => 13;
    BEGIN { use_ok('HTML::TagParser') };
# ----------------------------------------------------------------
    my $FILES = {
		"t/sample/charset-latin1.html"	=>	"Latin-1",
		"t/sample/charset-8859-1.html"	=>	"ISO-8859-1",
		"t/sample/charset-utf8.html"	=>	"UTF-8",
		"t/sample/charset-bogus.html"   =>      "windows-100%",
	};
# ----------------------------------------------------------------
	my $ingy;
	foreach my $file ( sort { $FILES->{$a} cmp $FILES->{$b} } keys %$FILES ) {
		my $code = $FILES->{$file};
	    my $html = HTML::TagParser->new( $file );
		ok( ref $html, "$code open" );
		is( $html->{charset}, $code, "$code charset" );
		my $titletag = $html->getElementsByTagName("title");
		if ( $ingy ) {
			is( $titletag->innerText(), $ingy, "$code title (match)" );
		} else {
			$ingy ||= $titletag->innerText();
			like( $ingy, qr/Ingy d.*t Net/i, "$code title (regex)" );
		}
	}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
