#!/usr/bin/perl

use strict;
use warnings;

use lib "$ENV{HOME}/.enbld/extlib/lib/perl5/";

use Enbld;

enbld 'mydevenv' => build {

    target 'git' => define {
        version 'latest';
    };

};

