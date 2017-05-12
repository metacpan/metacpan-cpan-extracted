#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 1;

use IPC::Shm;

ok( IPC::Shm->cleanup,			"IPC::Shm->cleanup" );

