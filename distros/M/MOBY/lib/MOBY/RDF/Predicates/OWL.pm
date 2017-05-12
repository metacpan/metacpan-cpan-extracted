package MOBY::RDF::Predicates::OWL;

use strict;
BEGIN {

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

use constant OWL_PREFIX => 'owl';

use constant OWL_URI => 'http://www.w3.org/2002/07/owl#';

################################
## Predicates for OWL         ##
################################

use constant Class => OWL_URI . 'Class';


}
1;
