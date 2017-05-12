#!/usr/bin/env perl

use strict;
use warnings;
use Test::Class;

use lib 't/lib';
use Test::JavaScript::Writer::Var;

Test::Class->runtests;

