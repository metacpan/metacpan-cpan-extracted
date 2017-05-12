use strict;
use warnings;

use Test::More;

use_ok('Message::Passing::Role::HasAConnection');
use_ok('Message::Passing::Role::ConnectionManager');
use_ok('Message::Passing');
use_ok('Message::Passing::Output::STDOUT');
use_ok('Message::Passing::Input::STDIN');
use_ok('Message::Passing::Input::FileTail');
use_ok('Message::Passing::Output::Null');
use_ok('Message::Passing::Output::Callback');
use_ok('Message::Passing::Output::Test');
use_ok('Message::Passing::Output::File');
use_ok('Message::Passing::Output::IO::Handle');
use_ok('Message::Passing::Output::STDERR');
use_ok('Message::Passing::Filter::Null');
use_ok('Message::Passing::Filter::All');
use_ok('Message::Passing::Filter::Delay');
use_ok('Message::Passing::Filter::Encoder::JSON');
use_ok('Message::Passing::Filter::Encoder::Null');
use_ok('Message::Passing::Filter::Decoder::JSON');
use_ok('Message::Passing::Filter::Decoder::Null');
use_ok('Message::Passing::Role::HasHostnameAndPort');
use_ok('Message::Passing::Role::HasUsernameAndPassword');
use_ok('Message::Passing::Role::HasErrorChain');
use_ok('Message::Passing::Input::Socket::UDP');
use_ok('Message::Passing::Filter::ToLogstash');

done_testing;

