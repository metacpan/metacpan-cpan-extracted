#!/usr/bin/perl

use 5.008;
use strict;
no warnings;

use File::Basename;
use File::Spec;
use Cwd;

BEGIN {
    chdir dirname(__FILE__) or die "$!";
    chdir '..' or die "$!";
};

do "./Build.PL";

local @ARGV = (@ARGV, 'testcover');
do "./Build";
