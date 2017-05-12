package FreeMind::Font;

use 5.010001;
use strict;
use warnings;

BEGIN {
	$FreeMind::Font::AUTHORITY = 'cpan:TOBYINK';
	$FreeMind::Font::VERSION   = '0.002';
}

use XML::LibXML::Augment
	-type  => 'Element',
	-names => ['font'],
;

require FreeMind::Document;

__PACKAGE__->FreeMind::Document::_has(
	BOLD              => { isa => Types::Standard::Bool },
	ITALIC            => { isa => Types::Standard::Bool },
	SIZE              => { isa => Types::Standard::Int, required => 1 },
	NAME              => { required => 1 },
);

1;
