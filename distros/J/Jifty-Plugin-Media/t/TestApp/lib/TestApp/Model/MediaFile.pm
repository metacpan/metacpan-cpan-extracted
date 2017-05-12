use strict;
use warnings;

package TestApp::Model::MediaFile;
use Jifty::DBI::Schema;

use TestApp::Record schema {
    column name =>
        label is _('Name'),
        is mandatory;
    column url =>
        is Media;
    column legend =>
        label is _('Legend'),
        hint is _('optional');
    column pos =>
        label is _('position'),
        valid_values are qw(static left right),
        hint is _('optional, only for image');
};

# Your model-specific methods go here.

1;

