package t::lib::MyHandlers::No;
use Moose;
with 'HTTP::Response::Switch::Handler';

sub handle { shift->decline }

1;
