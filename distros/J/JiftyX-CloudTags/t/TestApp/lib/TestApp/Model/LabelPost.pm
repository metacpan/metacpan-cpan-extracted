use strict;
use warnings;

package TestApp::Model::LabelPost;
use Jifty::DBI::Schema;

use TestApp::Record schema {

column ref_label =>
    refers_to TestApp::Model::Labels;

column ref_post =>
    refers_to TestApp::Model::Posts;

};

# Your model-specific methods go here.

1;

