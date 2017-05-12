#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'lib';

BEGIN { use_ok 'IPC::Pidfile', 'import module' }

ok IPC::Pidfile::pidfile_is_fresh, 'pidfile has current PID in it';
like IPC::Pidfile::pid, qr/^[0-9]+$/, 'pid is correctly formatted';
is IPC::Pidfile::pidfile_read, $IPC::Pidfile::PID, 'read pidfile';

done_testing;
