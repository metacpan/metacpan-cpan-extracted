#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

use_ok 'JLogger::Filter::FieldRegexp';

my $filter = new_ok 'JLogger::Filter::FieldRegexp', [fields => { from => '^bar@*'}];

ok !$filter->filter({from => 'bar@foo.com'});
ok $filter->filter({from => 'foo@bar.com'});

$filter = new_ok 'JLogger::Filter::FieldRegexp', [fields => { to => '^bar@jabber.org'}];

ok !$filter->filter({to => 'bar@jabber.org'});
ok !$filter->filter({to => 'bar@jabber.org'});
