use strict;
use warnings;

package TestApp::Model::PartSupplierLink;
use Jifty::DBI::Schema;

use TestApp::Record schema {
    column supplier =>
        is indexed,
        lable is "Supplier",
        refers_to TestApp::Model::Supplier,
        ;
    column part =>
        is indexed,
        lable is "Part",
        refers_to TestApp::Model::Part,
        ;
    column qty =>
        type is 'text',
        label is "QTY",
        ;
};

# Your model-specific methods go here.

1;

