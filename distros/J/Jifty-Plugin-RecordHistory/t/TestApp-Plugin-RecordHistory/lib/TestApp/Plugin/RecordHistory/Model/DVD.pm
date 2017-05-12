use strict;
use warnings;

package TestApp::Plugin::RecordHistory::Model::DVD;
use Jifty::DBI::Schema;

use TestApp::Plugin::RecordHistory::Record schema {
    column title =>
        type is 'varchar';
    column director =>
        type is 'varchar';
};

use Jifty::Plugin::RecordHistory::Mixin::Model::RecordHistory (
    delete_change => 1,
);

sub current_user_can { 1 }

1;

