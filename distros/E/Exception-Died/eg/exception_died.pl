#!/usr/bin/perl

use lib 'lib', '../lib';

use strict;
use warnings;

use Exception::Base verbosity=>3;
use Exception::Died '%SIG';

eval {
    eval {
	die "Simple die";
    };
    print "Inner eval: ", ref $@;
    die;
};
print "Outer eval: ", ref $@;
die;
