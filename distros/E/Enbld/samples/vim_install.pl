#!/usr/bin/perl

use strict;
use warnings;

use lib "$ENV{HOME}/.enbld/extlib/lib/perl5/";

use Enbld;

enbld 'myenv' => build {

    target 'vim' => define {
        version 'latest';
    };

    conf '.vimrc' => load {
        from 'https://raw.github.com/magnolia-k/vimrc/master/.vimrc';
    };

};

