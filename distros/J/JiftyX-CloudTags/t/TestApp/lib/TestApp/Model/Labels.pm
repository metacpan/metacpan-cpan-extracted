use strict;
use warnings;

package TestApp::Model::Labels;
use Jifty::DBI::Schema;

use TestApp::Record schema {

column name =>
    type is 'varchar';

column hit =>
    type is 'integer';

column posts =>
    refers_to TestApp::Model::LabelPostCollection by 'ref_label';

};

# Your model-specific methods go here.

1;

