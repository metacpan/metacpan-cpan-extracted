#!/usr/bin/perl

use lib 'lib', '../lib';

use strict;
use warnings;

use Exception::Base;

eval {
    eval { open my $file, "<", "/badmodeexample"
        or Exception::Base->throw( message=>"cannot open", verbosity=>4 ); };
    die;
};
die;
