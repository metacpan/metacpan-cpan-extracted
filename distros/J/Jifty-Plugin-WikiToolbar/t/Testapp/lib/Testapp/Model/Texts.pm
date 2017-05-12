use strict;
use warnings;

package Testapp::Model::Texts;
use Jifty::DBI::Schema;

use Testapp::Record schema {
    column oldrender =>
        render_as 'Jifty::Plugin::WikiToolbar::Textarea';
    column newrender =>
        is WikiToolbar;

};

# Your model-specific methods go here.

sub Jifty::Plugin::WikiToolbar::Textarea::rows { return 15; };

1;

