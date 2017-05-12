package FreeMind::Text;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$FreeMind::Text::AUTHORITY = 'cpan:TOBYINK';
	$FreeMind::Text::VERSION   = '0.002';
}

use XML::LibXML::Augment
	-type  => 'Element',
	-names => ['text'],
;

require FreeMind::Document;

1;
