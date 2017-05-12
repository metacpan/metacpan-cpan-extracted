#!perl -T

use warnings;
use strict;
use Data::Dumper;

use Test::More tests => 10;

BEGIN {
	use_ok( 'HTML::WikiConverter');
	use_ok( 'HTML::WikiConverter::GoogleCode');
}

my $wc = new HTML::WikiConverter( dialect => 'GoogleCode' );

# attribute names for GoogleCode dialect
is(join('; ' , sort(keys(%{$wc->attributes()}))),
	'escape_autolink; labels; summary',
	'google code attributes'
);

#
# escape autolink
#

# base case
$wc = new HTML::WikiConverter( 
		dialect => 'GoogleCode', 	
		escape_autolink => ['JavaScript', 'VbaScript'],
		);

# escape GoogleCode autolinking
is($wc->html2wiki('PerlScript is better than VbaScript, but even with JavaScript'),
	'PerlScript is better than !VbaScript, but even with !JavaScript',
	'escape_autolink'
);

# no escaping autolinking under <pre> tags
is($wc->html2wiki('PerlScript is better than <pre>VbaScript</pre>, but even with JavaScript'),
	"PerlScript is better than\n\n{{{\nVbaScript\n}}}\n\n, but even with !JavaScript",
	'escape_autolink'
);

#
# summary wiki element
#

# base case, insert summary comment as first line of wiki markup
$wc = new HTML::WikiConverter( 
		dialect => 'GoogleCode', 	
		summary => 'The summary message',
		);

is($wc->html2wiki('Blah Blah'),
	"#summary The summary message\nBlah Blah",
	'summary'
);

#
# labels wiki element
#

# base case, insert labels comment as first line of wiki markup
$wc = new HTML::WikiConverter( 
		dialect => 'GoogleCode', 	
		labels => ['Featured', 'Phase-Deploy'],
		);

is($wc->html2wiki('Blah Blah'),
	"#labels Featured,Phase-Deploy\nBlah Blah",
	'labels'
);

# empty labels
$wc = new HTML::WikiConverter( 
		dialect => 'GoogleCode', 	
		labels => [],
		);

is($wc->html2wiki('Blah Blah'),
	'Blah Blah',
	'empty labels'
);


#
# no attributes
#
$wc = new HTML::WikiConverter( 
		dialect => 'GoogleCode'
		);

is($wc->html2wiki('Blah Blah'),
	'Blah Blah',
	'no attributes'
);

#
# summary and labels
#
$wc = new HTML::WikiConverter( 
		dialect => 'GoogleCode', 	
		summary => 'The summary message',
		labels => ['Featured', 'Phase-Deploy'],
		);

is($wc->html2wiki('Blah Blah'),
	"#summary The summary message\n#labels Featured,Phase-Deploy\nBlah Blah",
	'empty labels'
);


