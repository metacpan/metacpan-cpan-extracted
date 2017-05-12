package TestApp;

use strict;
use warnings;

use Catalyst; #'-Debug';

use JSORB;
use JSORB::Dispatcher::Catalyst;

our $VERSION = '0.01';

TestApp->config(
    name => 'TestApp',
    who  => 'World',
);

TestApp->setup;

1;
