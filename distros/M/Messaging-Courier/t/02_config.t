#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 2;

use Messaging::Courier::Config;

ok(Messaging::Courier::Config->new());
ok(defined( Messaging::Courier::Config->group() ));
