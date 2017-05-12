use strict;
use warnings;

package TestApp::Plugin::RecordHistory::Model::CD;
use Jifty::DBI::Schema;

use TestApp::Plugin::RecordHistory::Record schema {
    column title =>
        type is 'varchar';
    column artist =>
        type is 'varchar';
};

use Jifty::Plugin::RecordHistory::Mixin::Model::RecordHistory (
    cascaded_delete => 0,
);

sub current_user_can { 1 }

1;

