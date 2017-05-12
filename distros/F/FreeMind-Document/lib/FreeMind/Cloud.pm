package FreeMind::Cloud;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$FreeMind::Cloud::AUTHORITY = 'cpan:TOBYINK';
	$FreeMind::Cloud::VERSION   = '0.002';
}

use XML::LibXML::Augment
	-type  => 'Element',
	-names => ['cloud'],
;

require FreeMind::Document;

__PACKAGE__->FreeMind::Document::_has(
	COLOR => { },
);


1;
