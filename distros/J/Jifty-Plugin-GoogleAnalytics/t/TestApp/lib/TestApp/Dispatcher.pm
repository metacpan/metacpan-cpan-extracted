package TestApp::Dispatcher;

use strict;
use warnings;

use Jifty::Dispatcher -base;

on qr{^/test_dispatcher$} => [
    run {
        default use_google_analytics => 0;
    },
];

1;
