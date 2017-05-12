#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 16;

use lib 'lib', '../lib';

eval "require IO::Poll";
my $has_io_poll = $@ ? 0 : 1;

use_ok("IOMux::Handler");
use_ok("IOMux::Handler::Read");
use_ok("IOMux::Handler::Write");
use_ok("IOMux::Handler::Service");

use_ok("IOMux::File::Read");
use_ok("IOMux::File::Write");
use_ok("IOMux::Pipe::Write");
use_ok("IOMux::Pipe::Read");

use_ok("IOMux::Net::TCP");
use_ok("IOMux::Service::TCP");

use_ok("IOMux::Bundle");
use_ok("IOMux::IPC");

use_ok("IOMux");
use_ok("IOMux::Select");

if($has_io_poll)
{   use_ok("IOMux::Poll");
}
else
{   pass "IO::Poll is not installed (optional)";
}

use_ok("IOMux::Open");
