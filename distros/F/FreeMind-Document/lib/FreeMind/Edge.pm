package FreeMind::Edge;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$FreeMind::Edge::AUTHORITY = 'cpan:TOBYINK';
	$FreeMind::Edge::VERSION   = '0.002';
}

use XML::LibXML::Augment
	-type  => 'Element',
	-names => ['edge'],
;

require FreeMind::Document;

__PACKAGE__->FreeMind::Document::_has(
	COLOR => { },
	STYLE => { },
	WIDTH => { },
);

1;
