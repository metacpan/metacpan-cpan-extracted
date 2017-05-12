use strict;
use warnings;

package TestApp::Model::Part;
use Jifty::DBI::Schema;

use TestApp::Record schema {
    column part_name =>
        is mandatory,
        type is 'text',
        label is "Part Name",
        ;
    column color =>
        type is 'text',
        label is "Part Color",
        valid_values are (qw/Red Green Blue/),
        ;
    column weight =>
        type is 'integer',
        label is "Weight",
        hints is "(Gram)",
        ;
    column part_supplier_links =>
        refers_to TestApp::Model::PartSupplierLinkCollection by 'part',
        ;
};

# Your model-specific methods go here.

sub name {
    shift->part_name;
}

1;

