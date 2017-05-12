# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Log-Log4perl-Appender-SpreadSession.t'

use Test::More tests => 1;

BEGIN { use_ok('Log::Log4perl::Appender::SpreadSession') };
