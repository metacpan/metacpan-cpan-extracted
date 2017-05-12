package TestApp::View;
use Jifty::View::Declare -base;

use strict;
use warnings;

template 'test_td_enable' => page {
    #set use_google_analytics => 1;
    { title is "Jifty::Plugin::GoogleAnalytics test (TD)" };
};

template 'test_td_disable' => page {
    set use_google_analytics => 0;
    { title is "Jifty::Plugin::GoogleAnalytics test (TD)" };
};

1;
