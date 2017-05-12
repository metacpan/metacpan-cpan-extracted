use strict;
use warnings;

package TestApp::Model::Supplier;
use Jifty::DBI::Schema;

use TestApp::Record schema {
    column supplier_name =>
        is mandatory,
        type is 'text',
        label is "Supplier Name",
        ;
    column status =>
        type is 'integer',
        label is "Status",
        ;
    column city =>
        is indexed,
        type is 'text',
        label is "City",
        valid_values are (qw/London Paris Rome Athens Oslo/),
        ;
    column part_supplier_links =>
        refers_to TestApp::Model::PartSupplierLinkCollection by 'supplier',
        ;
};

# Your model-specific methods go here.

sub name {
    shift->supplier_name;
}

1;

