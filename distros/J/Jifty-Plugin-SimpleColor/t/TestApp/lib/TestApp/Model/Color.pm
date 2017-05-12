use strict;
use warnings;

package TestApp::Model::Color;
use Jifty::DBI::Schema;

use TestApp::Record schema {
    column image1 =>
        is SimpleColor;
};

sub Jifty::Plugin::SimpleColor::Widget::addColors { return "['900', '090', '009', 'ccc']"; };

# Your model-specific methods go here.

1;

