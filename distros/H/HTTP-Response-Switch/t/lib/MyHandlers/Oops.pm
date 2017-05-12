package t::lib::MyHandlers::Oops;
use Moose;
with 'HTTP::Response::Switch::Handler';

sub handle { die 'something went wrong' }

1;
