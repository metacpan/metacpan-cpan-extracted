use strict;
use warnings;

package TestApp::Model::User;
use Jifty::DBI::Schema;

use TestApp::Record schema {
    column 'test' => 
        type is 'text';
};

# Your model-specific methods go here.

use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::ModShibb::Mixin::Model::User;

sub current_user_can {
    return 1;
};

1;

