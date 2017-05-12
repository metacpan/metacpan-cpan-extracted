#!/usr/bin/perl

use Config;
use inc::Module::Install;

name 'Locale-Hebrew';
all_from 'Hebrew.pm';
makemaker_args(
    OBJECT=> join(' ', map "$_$Config{obj_ext}", qw(Hebrew bidi)),
);

sign; WriteAll;
