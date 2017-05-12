#!/usr/bin/perl
#
# foo.pl
#
# Created: 10/07/2009 09:00:34 AM

use strict;
use warnings;
use Getopt::Awesome::Examples::ImportAllFoos;
use Getopt::Awesome qw(:all);

define_option('foo', 'This is foo from main');
define_option('bar', 'This is bar from main');
parse_opts();
Getopt::Awesome::Examples::ImportAllFoos->test_this_foo;


