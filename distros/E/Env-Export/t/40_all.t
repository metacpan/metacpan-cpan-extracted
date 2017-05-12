#!/usr/bin/perl

use strict;
use warnings;
use subs qw(sub_count);

use File::Spec;
use Test::More;

(my $vol, my $dir, undef) = File::Spec->splitpath(File::Spec->rel2abs($0));
require File::Spec->catpath($vol, $dir, 'sub_count.pl');

# TEST SCOPE: These tests exercise the ":all" keyword

# Record the list of all %ENV keys that are valid as identifiers
my @valid = sort grep(/^[A-Za-z_]\w*$/, keys %ENV);

my $namespace = 'namespace0000';

# The number of tests is dependent on @valid
plan tests => (@valid * 2) + 3;

# First set: general ":all" usage
my $code = <<"END_BLOCK1";
package $namespace;
use Env::Export qw(:all);
package main;
END_BLOCK1

for (@valid)
{
    $code .= "is(${namespace}::$_(), \$ENV{$_}, ':all test, key=$_');\n";
}

eval $code;
warn "eval fail: $@" if $@;
is(sub_count($namespace), scalar(@valid),
   "Number of subs exported to first namespace");

# Second set: ":all" used with ":prefix"
$namespace++;
$code = <<"END_BLOCK1";
package $namespace;
use Env::Export qw(:prefix PRE_ :all);
package main;
END_BLOCK1

for (@valid)
{
    $code .= "is(${namespace}::PRE_$_(), \$ENV{$_}, ':all+:prefix, $_');\n";
}

eval $code;
warn "eval fail: $@" if $@;
is(sub_count($namespace), scalar(@valid),
   "Number of subs exported to second namespace");

# Last test: create an unusable %ENV key and make sure it doesn't show up
$namespace++;
$ENV{'***'} = '+++';
eval "package $namespace; use Env::Export ':all';";
warn "eval fail: $@" if $@;
is(sub_count($namespace), scalar(@valid),
   "Number of subs exported to third namespace");

exit;
