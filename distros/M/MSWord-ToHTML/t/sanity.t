#!/usr/bin/env perl

use strictures 1;
use Module::Find;
use Test::Most tests => 6;
use lib 'lib';

my @found = useall MSWord;
use_ok($_) for @found;
