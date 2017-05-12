package TestApp::Plugin::RecordHistory::View;
use Jifty::View::Declare -base;

use Jifty::Plugin::RecordHistory::View;

alias Jifty::Plugin::RecordHistory::View under '/book/history', {
    object_type => 'Book',
};

1;

