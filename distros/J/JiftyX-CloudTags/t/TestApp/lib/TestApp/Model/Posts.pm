use strict;
use warnings;

package TestApp::Model::Posts;
use Jifty::DBI::Schema;

use TestApp::Record schema {

column title =>
    type is 'varchar';

column content =>
    type is 'blob'

};

# Your model-specific methods go here.

1;

