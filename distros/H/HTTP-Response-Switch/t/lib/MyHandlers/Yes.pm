package t::lib::MyHandlers::Yes;
use Moose;
with 'HTTP::Response::Switch::Handler';

sub handle { 1 }

1;
