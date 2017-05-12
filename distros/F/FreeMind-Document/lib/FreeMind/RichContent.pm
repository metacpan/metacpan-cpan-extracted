package FreeMind::RichContent;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$FreeMind::Text::AUTHORITY = 'cpan:TOBYINK';
	$FreeMind::Text::VERSION   = '0.002';
}

use XML::LibXML::Augment
	-type  => 'Element',
	-names => ['richcontent'],
;

require FreeMind::Document;

__PACKAGE__->FreeMind::Document::_has(
	TYPE => { },
);

1;
