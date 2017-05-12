#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 3;

BEGIN {
    use_ok 'IO::AIO';
    use_ok 'Filesys::Virtual::Async';
    use_ok 'Filesys::Virtual::Async::Plain';
}
