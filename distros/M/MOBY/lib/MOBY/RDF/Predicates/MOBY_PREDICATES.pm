package MOBY::RDF::Predicates::MOBY_PREDICATES;

use strict;

BEGIN {
	use vars qw /$VERSION/;
	$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

	use constant MOBY_PREDICATES_PREFIX => 'moby';

	use constant MOBY_PREDICATES_URI =>
	  'http://biomoby.org/RESOURCES/MOBY-S/Predicates#';

######################################
## Predicates for MOBY_PREDICATES   ##
######################################

	use constant hasa        => MOBY_PREDICATES_URI . 'hasa';
	use constant has         => MOBY_PREDICATES_URI . 'has';
	use constant articleName => MOBY_PREDICATES_URI . 'articleName';

}
1;
