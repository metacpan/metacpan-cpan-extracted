use strict;
use warnings;

use Test::More;

use_ok('Message::Passing::AMQP::ConnectionManager');
use_ok('Message::Passing::AMQP::Role::HasAConnection');
use_ok('Message::Passing::AMQP');
use_ok('Message::Passing::Input::AMQP');
use_ok('Message::Passing::Output::AMQP');

done_testing;

