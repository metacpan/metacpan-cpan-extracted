use strict;
use warnings;

package TestApp::Plugin::RecordHistory::Model::Book;
use Jifty::DBI::Schema;

use TestApp::Plugin::RecordHistory::Record schema {
    column title =>
        type is 'varchar';
    column author =>
        type is 'varchar';
};

use Jifty::Plugin::RecordHistory::Mixin::Model::RecordHistory;

sub current_user_can { 1 }

1;

