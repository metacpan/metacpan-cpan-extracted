#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

unlink 't/testdb';
ok ! -f 't/testdb', "'t/testdb' was deleted";

