use strict;
use Test::More;
use MARC::Spec;
use MARC::Spec::Field;
use MARC::Spec::Subfield;
use MARC::Spec::Comparisonstring;
use MARC::Spec::Subspec;
use MARC::Spec::Structure;
use MARC::Spec::Parser;

BEGIN {
    use_ok 'MARC::Spec';
    use_ok 'MARC::Spec::Field';
    use_ok 'MARC::Spec::Subfield';
    use_ok 'MARC::Spec::Comparisonstring';
    use_ok 'MARC::Spec::Subspec';
    use_ok 'MARC::Spec::Parser';
 }

require_ok 'MARC::Spec';
require_ok 'MARC::Spec::Field';
require_ok 'MARC::Spec::Subfield';
require_ok 'MARC::Spec::Comparisonstring';
require_ok 'MARC::Spec::Subspec';
require_ok 'MARC::Spec::Parser';

done_testing;
