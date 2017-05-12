#!/usr/bin/env perl

use strict;
use warnings;
use Daemon::Control;

exit Daemon::Control->new(
    name        => 'Mercury',

    program     => $ENV{HOME} . '/perl5/bin/mercury',
    program_args => [ 'broker' ],

    pid_file    => '/tmp/mercury.pid',
    stderr_file => '/tmp/mercury.out',
    stdout_file => '/tmp/mercury.out',

    fork        => 2,

)->run;
