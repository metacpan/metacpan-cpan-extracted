use strict;
use warnings;
use v5.14;

use Test2::V0;

use AnyEvent::Impl::Perl;
use Future::IO;
use Future::IO::Impl::AnyEvent;
use Test::Future::IO::Impl;

is (AnyEvent::detect, 'AnyEvent::Impl::Perl', 'AnyEvent::detect');

run_tests 'accept';
run_tests 'connect';
run_tests 'sleep';
run_tests 'sysread';
run_tests 'syswrite';
run_tests 'waitpid';

done_testing;
