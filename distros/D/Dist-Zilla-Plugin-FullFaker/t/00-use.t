#!/usr/bin/env perl -w

# $Id: 00-use.t 48 2015-07-01 06:38:25Z stro $

use strict;
use Test;
BEGIN { plan tests => 1 }

use Dist::Zilla::Plugin::FullFaker;

ok(1);

exit;
