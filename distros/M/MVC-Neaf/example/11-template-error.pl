#!/usr/bin/env perl

use strict;
use warnings;

# always use latest and greatest Neaf, no matter what's in @INC
use FindBin qw($Bin);
use File::Basename qw(dirname basename);
use lib dirname($Bin)."/lib";
use MVC::Neaf;

MVC::Neaf->route( cgi => basename(__FILE__) => sub {
    return {
        -template => \"[% IF %]", # this dies
    };
}, description => "Template error example");

MVC::Neaf->run;
