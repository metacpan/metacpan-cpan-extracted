#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Memoize::Memcached::Attribute::Test;
Memoize::Memcached::Attribute::Test->runtests;

exit;
