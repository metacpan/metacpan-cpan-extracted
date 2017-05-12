#! /usr/bin/env perl
use strict;
use warnings;

use Global::MutexLock qw(mutex_create mutex_destory mutex_lock mutex_unlock);
print mutex_create() . "\n";
