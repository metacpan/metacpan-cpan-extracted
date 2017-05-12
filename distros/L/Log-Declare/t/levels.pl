#!/usr/bin/env perl

use strict;

use Log::Declare;

print STDERR 'START', $/;

trace 'trace';
debug 'debug';
info  'info';
warn  'warn';
error 'error';
audit 'audit';

print STDERR 'END', $/;
