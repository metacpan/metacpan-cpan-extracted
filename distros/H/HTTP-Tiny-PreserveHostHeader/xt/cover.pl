#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
no warnings 'all';

use File::Basename;
use File::Spec;
use Cwd;

BEGIN {
    chdir dirname(__FILE__) or die "$!";
    chdir '..'              or die "$!";
}

do "./Build.PL";

local @ARGV = (@ARGV, 'testcover');
do "./Build";
