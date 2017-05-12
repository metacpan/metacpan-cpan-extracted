#!/usr/bin/perl

use strict;
use warnings;

use utf8;

use lib "$ENV{HOME}/.enbld/extlib/lib/perl5/";

use Enbld;

enbld 'mydevenv' => build {

    target 'perl' => define {
        version '5.18.1';
    };

};

