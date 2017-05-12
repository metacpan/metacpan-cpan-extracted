use strict;
use warnings;

package TestApp::Plugin::RecordHistory::Model::User;
use Jifty::DBI::Schema;

use TestApp::Plugin::RecordHistory::Record schema {
    column name =>
        type is 'varchar',
        default is 'anonymous';
};

sub current_user_can { 1 }

1;

