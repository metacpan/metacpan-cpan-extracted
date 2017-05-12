#! /usr/bin/env perl
use strict;
use warnings;

use Global::IPC::StaticVariable qw/var_create var_destory var_read var_update/;
print var_create() . "\n";
