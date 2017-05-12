use strict;
use warnings;

use Test::More;

use_ok('Message::Passing::PSGI');
use_ok('Plack::App::Message::Passing');
use_ok('Plack::Handler::Message::Passing');

done_testing;

