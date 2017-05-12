#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;
use Devel::Pragma qw(:all);

ok(defined &ccstash, 'ccstash is exported by :all');
ok(defined &scope, 'scope is exported by :all');
ok(defined &new_scope, 'new_scope is exported by :all');
ok(defined &hints, 'hints is exported by :all');
ok(defined &fqname, 'fqname is exported by :all');
