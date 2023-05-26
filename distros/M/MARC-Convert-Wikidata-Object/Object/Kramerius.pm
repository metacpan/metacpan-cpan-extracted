package MARC::Convert::Wikidata::Object::Kramerius;

use strict;
use warnings;

use Mo qw(is);

our $VERSION = 0.01;

has kramerius_id => (
	is => 'ro',
);

has object_id => (
	is => 'ro',
);

# TODO Remove if i could construct URL by some method.
has url => (
	is => 'ro',
);

1;

__END__
