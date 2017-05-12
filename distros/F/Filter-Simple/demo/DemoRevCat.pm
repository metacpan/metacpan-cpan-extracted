package DemoRevCat;
$VERSION = '0.01';

use Filter::Simple;

FILTER_ONLY
	code   => sub {
			my $ph = $Filter::Simple::placeholder;
			s/($ph)\s*[.]\s*($ph)/$2.$1/g
		},
