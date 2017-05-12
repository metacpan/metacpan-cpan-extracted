package FreeMind::ArrowLink;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$FreeMind::ArrowLink::AUTHORITY = 'cpan:TOBYINK';
	$FreeMind::ArrowLink::VERSION   = '0.002';
}

use XML::LibXML::Augment
	-type  => 'Element',
	-names => ['arrowlink'],
;

require FreeMind::Document;

__PACKAGE__->FreeMind::Document::_has(
	COLOR            => { },
	DESTINATION      => { required => 1 },
	ENDARROW         => { },
	ENDINCLINATION   => { },
	ID               => { },
	STARTARROW       => { },
	STARTINCLINATION => { },
);

1;
