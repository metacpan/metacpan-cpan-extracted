#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    use_ok('FCGI::Engine');
    use_ok('FCGI::Engine::ProcManager');
    use_ok('FCGI::Engine::ProcManager::Constrained');
}

done_testing;

