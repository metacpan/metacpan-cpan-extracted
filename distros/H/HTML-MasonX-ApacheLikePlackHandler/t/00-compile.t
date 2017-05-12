use strict;
use warnings;
use Test::More tests => 1;

{
    local $ENV{HTML_MASONX_APACHELIKEPLACKHANDLER_MOCK_APACHE2_REQUEST_CLASS}          = 'Your::ApacheLikePlackHandler::Compat::Apache2::Request';
    local $ENV{HTML_MASONX_APACHELIKEPLACKHANDLER_MOCK_APACHE2_REQUEST_INSTANCE_CLASS} = 'Your::Mock::Apache2::Request';
    local $ENV{HTML_MASONX_APACHELIKEPLACKHANDLER_MOCK_APACHE2_SERVERUTIL_CLASS}       = 'Your::ApacheLikePlackHandler::Compat::Apache2::ServerUtil';
    local $ENV{HTML_MASONX_APACHELIKEPLACKHANDLER_MOCK_APACHE2_STATUS_CLASS}           = 'Your::ApacheLikePlackHandler::Compat::Apache2::Status';
    require HTML::MasonX::ApacheLikePlackHandler;
}
pass("It compiles, ship it!");
