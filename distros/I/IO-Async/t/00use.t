#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require IO::Async::Notifier;
require IO::Async::Handle;
require IO::Async::Stream;
require IO::Async::Timer;
require IO::Async::Timer::Absolute;
require IO::Async::Timer::Countdown;
require IO::Async::Timer::Periodic;
require IO::Async::Signal;
require IO::Async::Listener;
require IO::Async::Socket;
require IO::Async::File;
require IO::Async::FileStream;

require IO::Async::OS;

require IO::Async::Loop::Select;
require IO::Async::Loop::Poll;

require IO::Async::Test;

require IO::Async::Function;
require IO::Async::Resolver;

require IO::Async::Protocol;
require IO::Async::Protocol::Stream;
require IO::Async::Protocol::LineStream;

pass( 'Modules loaded' );
done_testing;
