#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Log::Any::Adapter::Mojo',
    VERSION_FROM => 'lib/Log/Any/Adapter/Mojo.pm',
    AUTHOR       => 'Henry Tang <henryykt@gmail.com>',
    PREREQ_PM    => {
        'Mojolicious'       => '1.13',
        'Log::Any::Adapter' => '0.07',
        'Log::Any'          => '0.14'
    },
    LICENSE => 'artistic_2',
    test    => { TESTS => 't/*.t t/*/*.t t/*/*/*.t' }
);
