#!/usr/bin/perl

use strict;
use warnings;

use lib "$ENV{HOME}/.enbld/extlib/lib/perl5/";

use Enbld;

enbld 'mydevenv' => build {

    target 'perl' => define {
        version 'latest';

        modules 'cpanfile';
    };
};

