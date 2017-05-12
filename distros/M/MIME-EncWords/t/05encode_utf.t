use strict;
use Test::More;

BEGIN {
    if ($] < 5.007003) {
	plan skip_all => 'No Unicode/multibyte support';
    } else {
	plan tests => 36;
    }
}

use MIME::EncWords qw(encode_mimewords);
$MIME::EncWords::Config = {
    Detect7bit => 'YES',
    Mapping => 'EXTENDED',
    Replacement => 'DEFAULT',
    Charset => 'ISO-8859-1',
    Encoding => 'A',
    Field => undef,
    Folding => "\n",
    MaxLineLen => 76,
    Minimal => 'YES',
};

dotest('UTF-16');
dotest('UTF-16BE');
dotest('UTF-16LE');
dotest('UTF-32');
dotest('UTF-32BE');
dotest('UTF-32LE');

sub dotest {
    my $charset = shift;

    local($/) = '';
    open WORDS, "<testin/encode-utf-8.txt" or die "open: $!";
    while (<WORDS>) {
	s{\A\s+|\s+\Z}{}g;    # trim

	my ($isgood, $dec, $expect) = split /\n/, $_, 3;
	$isgood = (uc($isgood) eq 'GOOD');
	my @params = eval $dec;

	if (ref $params[0]) {
	    foreach my $p (@{$params[0]}) {
		if ($p->[1] and uc $p->[1] eq 'UTF-8') {
		    Encode::from_to($p->[0], 'UTF-8', $charset);
		    $p->[1] = $charset;
		}
	    }
	} else {
	    if ($params[1] and $params[1] eq 'Charset' and
		uc $params[2] eq 'UTF-8') {
		Encode::from_to($params[0], 'UTF-8', $charset);
		$params[2] = $charset;
	    }
	}

	my $enc = encode_mimewords(@params);
	is((($isgood && !$@) or (!$isgood && $@)) &&
           ($isgood ? $enc : $expect), $expect, $@ || $enc);
    }
    close WORDS;
}    

1;

