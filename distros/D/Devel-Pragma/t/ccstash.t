#!/usr/bin/env perl

package CCstash;

use strict;
use warnings;

use Devel::Pragma qw(ccstash);

use lib qw(t/lib);

use Test::More tests => 3;

is ccstash, undef; # undef in code that's not being `require`d

use CCstashCallee1;

is(CCstashCallee1->test, 'CCstash');

require CCstashCallee2;

is(CCstashCallee2->test, 'CCstashCallee2');
